#!/usr/bin/env node
/**
 * install-dsh-plugins — install or update the plugins of a DSH profile.
 *
 * The plugin list is read from a source profile (the current one by default),
 * every target profile gets `minimumReleaseAgeExclude` entries for those
 * registry packages, and finally one `dsh plugin add ...@latest` run brings the
 * target to the latest compatible versions. Local (`link:`/`file:`) and aliased
 * (`npm:`) specs are preserved verbatim.
 *
 * Defaults to a dry run: --apply is required to write files or run pnpm.
 */

import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const USAGE = `用法：install-dsh-plugins.mjs [选项]

读取 DSH profile 的插件列表，把它们从各目标 profile 的 pnpm minimumReleaseAge
门槛中排除，然后用以下命令安装或更新：
  dsh plugin --profile <target> add <pkg>@latest ... --config.minimumReleaseAge=0

选项：
  --source <name>       读取插件列表的源 profile（默认：$DSH_PROFILE）
  --profile <name>      目标 profile，可重复或用逗号分隔
                        （默认：当前 profile）
  --apply               写入 pnpm-workspace.yaml 并运行 dsh plugin
  --no-age-exclude      不修改 minimumReleaseAgeExclude
  -h, --help            显示此帮助

不加 --apply 时不会改动任何内容，只打印计划。

在 WSL 下，四个 connector 插件需要 Windows 客户端中的凭据；见 skill 的
“四个 connector 插件的凭据前提”一节。本安装器只更新包，不验证这些凭据。`;

// Bundles that make up the profile itself, plus the TUI's auto-inserted bundle.
// They are updated by DSH/dsh-tui, never as a regular plugin.
const INFRASTRUCTURE = new Set([
  '@deepseek-ai/dsh-base',
  '@deepseek-ai/dsh-web-app',
  '@deepseek-harness-tui/dsh-tui',
  'dsh-working-activity',
]);

function fail(message) {
  process.stderr.write(`install-dsh-plugins: ${message}\n`);
  process.exit(1);
}

function parseArgs(argv) {
  const options = { source: undefined, profiles: [], apply: false, ageExclude: true };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const value = () => {
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('-')) fail(`${arg} needs a value`);
      i += 1;
      return next;
    };
    if (arg === '--source') options.source = value();
    else if (arg === '--profile') options.profiles.push(...value().split(',').map(s => s.trim()).filter(Boolean));
    else if (arg === '--apply') options.apply = true;
    else if (arg === '--no-age-exclude') options.ageExclude = false;
    else if (arg === '-h' || arg === '--help') {
      process.stdout.write(`${USAGE}\n`);
      process.exit(0);
    } else fail(`unknown argument: ${arg} (try --help)`);
  }
  return options;
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch {
    return undefined;
  }
}

function profileName() {
  if (process.env.DSH_PROFILE?.trim()) return process.env.DSH_PROFILE.trim();
  if (process.env.DSH_PROFILE_DIR?.trim()) {
    return process.env.DSH_PROFILE_DIR.replace(/[\\/]+$/, '').split(/[\\/]/).pop();
  }
  return undefined;
}

function profileDir(home, name) {
  if (process.env.DSH_PROFILE_DIR?.trim() && profileName() === name) {
    return process.env.DSH_PROFILE_DIR;
  }
  return join(home, 'profiles', name);
}

function isLocalSpec(spec) {
  return /^(link|file|portal|workspace|npm|git\+|github|https?|ssh):/i.test(spec.trim());
}

function installedVersion(dir, name) {
  return readJson(join(dir, 'node_modules', name, 'package.json'))?.version;
}

function pluginEntries(manifest) {
  const deps = manifest?.dependencies ?? {};
  const bundles = Array.isArray(manifest?.dsh?.profile?.bundles)
    ? manifest.dsh.profile.bundles
    : undefined;
  const ordered = bundles ?? Object.keys(deps);
  const plugins = [];
  const skipped = [];

  for (const name of ordered) {
    if (INFRASTRUCTURE.has(name)) continue;
    const spec = deps[name];
    if (spec === undefined) {
      // A declared layer that is not a dependency: dsh cannot load it, but
      // installing the latest version is the best available repair.
      plugins.push({ name, spec: 'latest', local: false, missingSpec: true });
      continue;
    }
    if (spec.startsWith('workspace:')) {
      skipped.push({ name, spec, reason: 'workspace protocol' });
      continue;
    }
    plugins.push({ name, spec, local: isLocalSpec(spec) });
  }

  if (bundles !== undefined) {
    for (const [name, spec] of Object.entries(deps)) {
      if (!ordered.includes(name)) skipped.push({ name, spec, reason: 'not in dsh.profile.bundles' });
    }
  }
  return { plugins, skipped };
}

/** Package name of a minimumReleaseAgeExclude item: `pkg`, `pkg@1.2.3`,
 *  `pkg@1 || 2`, `'@scope/pkg@1.2.3'`. */
function entryPackage(value) {
  let v = value.trim().split(/\s*\|\|\s*/)[0];
  if ((v.startsWith("'") && v.endsWith("'")) || (v.startsWith('"') && v.endsWith('"'))) {
    v = v.slice(1, -1);
  }
  if (v.startsWith('@')) {
    const slash = v.indexOf('/');
    if (slash === -1) return v;
    const at = v.indexOf('@', slash + 1);
    return at === -1 ? v : v.slice(0, at);
  }
  const at = v.indexOf('@');
  return at === -1 ? v : v.slice(0, at);
}

function yamlScalar(name) {
  return /^[@&*!|>'"%#`?\-,[\]{}:]/.test(name) || /[:#\s]/.test(name)
    ? `'${name.replace(/'/g, "''")}'`
    : name;
}

/**
 * Ensure `names` are present as bare entries of the top-level
 * `minimumReleaseAgeExclude` list in a pnpm-workspace.yaml text.
 *
 * Surgically edits lines instead of dumping YAML through a parser, so comments,
 * ordering, and unrelated entries survive. Existing entries for a managed
 * package are normalised to the bare name (pnpm 11.5–11.7 only honours the
 * first entry per package, so a pinned entry must not shadow it); duplicates
 * are dropped.
 */
function ensureReleaseAgeExcludes(text, names) {
  const lines = text.split('\n');
  const keyRe = /^minimumReleaseAgeExclude:\s*(?:#.*)?$/;
  const key = lines.findIndex(line => /^minimumReleaseAgeExclude:/.test(line));
  if (key !== -1) {
    const rest = lines[key].replace(/^minimumReleaseAgeExclude:/, '').trim();
    if (rest === '[]') {
      lines[key] = 'minimumReleaseAgeExclude:';
    } else if (rest !== '' && !rest.startsWith('#')) {
      fail(`inline minimumReleaseAgeExclude is not supported (${lines[key].trim()}); convert it to block list form first`);
    }
  }
  const wanted = new Set(names);
  const added = [];
  const normalized = [];
  const deduped = [];

  if (key === -1) {
    let body = text.replace(/\s*$/, '');
    const block = ['minimumReleaseAgeExclude:', ...names.map(name => `  - ${yamlScalar(name)}`)];
    body = body === '' ? block.join('\n') : `${body}\n\n${block.join('\n')}`;
    return {
      text: `${body}\n`,
      added: [...names],
      normalized,
      deduped,
      changed: names.length > 0,
    };
  }

  // The block runs until the next top-level key; blank lines, comments, and
  // list items (indented or not) stay inside it.
  let end = key + 1;
  while (end < lines.length) {
    const line = lines[end];
    if (line === '' || /^\s/.test(line) || /^\s*#/.test(line) || /^-\s/.test(line)) {
      end += 1;
      continue;
    }
    break;
  }

  const itemRe = /^(\s*)-\s+(.+?)\s*$/;
  const body = [];
  const seen = new Set();
  let itemIndent = '  ';
  let lastItem = -1;

  for (let i = key + 1; i < end; i += 1) {
    const line = lines[i];
    const match = line.match(itemRe);
    if (!match) {
      body.push(line);
      continue;
    }

    const indent = match[1];
    let raw = match[2];
    let comment = '';
    const commentMatch = raw.match(/^(.*?)\s+(#.*)$/);
    if (commentMatch) {
      raw = commentMatch[1].trim();
      comment = commentMatch[2];
    }

    const pkg = entryPackage(raw);
    if (!wanted.has(pkg)) {
      body.push(line);
      lastItem = body.length - 1;
      continue;
    }
    if (seen.has(pkg)) {
      deduped.push(pkg);
      continue;
    }
    seen.add(pkg);
    itemIndent = indent;
    const normalizedLine = `${indent}- ${yamlScalar(pkg)}${comment ? ` ${comment}` : ''}`;
    if (normalizedLine !== line) normalized.push(`${raw} -> ${pkg}`);
    body.push(normalizedLine);
    lastItem = body.length - 1;
  }

  for (const name of names) {
    if (seen.has(name)) continue;
    added.push(name);
  }

  if (added.length > 0) {
    const insertAt = lastItem === -1 ? 0 : lastItem + 1;
    body.splice(insertAt, 0, ...added.map(name => `${itemIndent}- ${yamlScalar(name)}`));
  }

  const changed = added.length > 0 || normalized.length > 0 || deduped.length > 0;
  return {
    text: [...lines.slice(0, key + 1), ...body, ...lines.slice(end)].join('\n'),
    added,
    normalized,
    deduped,
    changed,
  };
}

function shellQuote(value) {
  return /^[A-Za-z0-9_./:@%+=,-]+$/.test(value) ? value : `'${value.replace(/'/g, `'\\''`)}'`;
}

function runDsh(args, { inherit = false } = {}) {
  const windows = process.platform === 'win32';
  const bin = process.env.DSH_BIN?.trim() || 'dsh';
  const result = spawnSync(
    windows ? [bin, ...args].map(shellQuote).join(' ') : bin,
    windows ? [] : args,
    {
      encoding: 'utf8',
      stdio: inherit ? 'inherit' : 'pipe',
      shell: windows,
    },
  );
  return {
    code: result.status ?? 1,
    error: result.error,
    stdout: result.stdout ?? '',
    stderr: result.stderr ?? '',
  };
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const home = process.env.DSH_HOME?.trim() || join(homedir(), '.dsh');
  const current = profileName();
  if (current === undefined) {
    fail('cannot determine the current profile: set DSH_PROFILE or DSH_PROFILE_DIR, or pass --source/--profile');
  }

  const source = options.source ?? current;
  const sourceDir = profileDir(home, source);
  const sourceManifest = readJson(join(sourceDir, 'package.json'));
  if (sourceManifest === undefined) {
    fail(`source profile '${source}' has no readable package.json at ${join(sourceDir, 'package.json')}`);
  }

  const { plugins, skipped } = pluginEntries(sourceManifest);
  if (plugins.length === 0) {
    process.stdout.write(`install-dsh-plugins: no plugins found in profile '${source}' (${sourceDir})\n`);
    return;
  }

  const targets = [...new Set(options.profiles.length > 0 ? options.profiles : [current])];

  process.stdout.write(`source profile: ${source} (${sourceDir})\n`);
  process.stdout.write('plugins:\n');
  for (const plugin of plugins) {
    process.stdout.write(
      `  - ${plugin.name} (${plugin.spec}${plugin.local ? ', local' : ''}${plugin.missingSpec ? ', no dependency entry' : ''})\n`,
    );
  }
  for (const item of skipped) {
    process.stdout.write(`  skip ${item.name} (${item.reason})\n`);
  }
  // pnpm resolves the whole manifest, including dependencies that are not
  // profile bundles, so any workspace: entry aborts the install.
  const workspaceDeps = Object.entries(sourceManifest.dependencies ?? {})
    .filter(([, spec]) => spec.startsWith('workspace:'))
    .map(([name]) => name);
  if (workspaceDeps.length > 0) {
    fail(
      `profile '${source}' contains workspace: dependencies (${workspaceDeps.join(', ')}); ` +
        'pnpm cannot resolve them outside a workspace, so remove them from the profile before installing plugins',
    );
  }
  process.stdout.write(`target profiles: ${targets.join(', ')}\n`);
  process.stdout.write(`mode: ${options.apply ? 'apply' : 'dry-run (pass --apply to change anything)'}\n`);

  const registryNames = plugins.filter(plugin => !plugin.local).map(plugin => plugin.name);
  const specs = plugins.map(plugin => `${plugin.name}@${plugin.local ? plugin.spec : 'latest'}`);

  let failed = false;
  for (const target of targets) {
    const dir = profileDir(home, target);
    process.stdout.write(`\n== target '${target}' (${dir})\n`);

    if (!existsSync(join(dir, 'package.json'))) {
      if (!options.apply) {
        process.stdout.write(`  profile does not exist yet; --apply would initialise it with 'dsh plugin --profile ${target} ls'\n`);
        process.stdout.write(`  would install: ${specs.join(' ')}\n`);
        continue;
      }
      process.stdout.write(`  initialising profile with 'dsh plugin --profile ${target} ls'\n`);
      const init = runDsh(['plugin', '--profile', target, 'ls']);
      if (init.code !== 0) {
        if (init.error) process.stderr.write(`  ${init.error.message}\n`);
        else process.stderr.write(init.stderr || init.stdout);
        fail(`could not initialise profile '${target}'`);
      }
    } else {
      process.stdout.write(`  installed now:\n`);
      for (const plugin of plugins) {
        const version = installedVersion(dir, plugin.name);
        process.stdout.write(`    - ${plugin.name}: ${version ?? 'not installed'}\n`);
      }
    }

    if (options.ageExclude && registryNames.length > 0) {
      const workspacePath = join(dir, 'pnpm-workspace.yaml');
      if (!existsSync(workspacePath)) {
        process.stdout.write(`  no pnpm-workspace.yaml at ${workspacePath}; skipping exclude edit\n`);
      } else {
        const before = readFileSync(workspacePath, 'utf8');
        const result = ensureReleaseAgeExcludes(before, registryNames);
        if (!result.changed) {
          process.stdout.write(`  minimumReleaseAgeExclude: already contains all ${registryNames.length} plugins\n`);
        } else {
          for (const name of result.added) process.stdout.write(`  exclude + ${name}\n`);
          for (const item of result.normalized) process.stdout.write(`  exclude ~ ${item}\n`);
          for (const name of result.deduped) process.stdout.write(`  exclude - duplicate ${name}\n`);
          if (options.apply) {
            writeFileSync(workspacePath, result.text);
            process.stdout.write(`  updated ${workspacePath}\n`);
          } else {
            process.stdout.write(`  would update ${workspacePath}\n`);
          }
        }
      }
    }

    const args = [
      'plugin',
      '--profile',
      target,
      'add',
      ...specs,
      '--config.minimumReleaseAge=0',
    ];
    if (!options.apply) {
      process.stdout.write(`  would run: ${['dsh', ...args].map(shellQuote).join(' ')}\n`);
      continue;
    }

    process.stdout.write(`  running: ${['dsh', ...args].map(shellQuote).join(' ')}\n`);
    const install = runDsh(args, { inherit: true });
    if (install.code !== 0) {
      if (install.error) process.stderr.write(`  ${install.error.message}\n`);
      process.stderr.write(`  'dsh plugin --profile ${target} add ...' failed (exit ${install.code})\n`);
      failed = true;
    } else {
      process.stdout.write(`  done\n`);
    }
  }

  process.stdout.write('\nRestart dsh / dsh-tui to load updated plugins.\n');
  if (failed) process.exit(1);
}

main();
