#!/bin/sh
printf '\033c\033]0;%s\a' GinoAI
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ginoLinux.x86_64" "$@"
