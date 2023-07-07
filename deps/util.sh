#!/bin/bash

message() {
	local content="$*"
	printf "[dotfiles] - %s\n" "$content"
}

skip_message() {
	local old="$IFS"
	IFS='/'
	local target="'$*'"
	message "$target already exist, skip..."
	IFS=$old
}

install_or_skip() {
	local command="$1"
	local target="$2"
	if ! type "$target" >/dev/null 2>&1; then
		message "install '$target' with command: '$command'"
		eval "$command"
	else
		skip_message $target
	fi
}
