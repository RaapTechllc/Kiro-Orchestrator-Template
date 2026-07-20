#!/usr/bin/env bash
set -u

if [ ! -f result.txt ]; then
  printf 'result.txt does not exist\n' >&2
  exit 1
fi

actual=$(tr -d '\r\n' < result.txt)
if [ "$actual" != orchestrated ]; then
  printf 'result.txt must contain exactly: orchestrated\n' >&2
  exit 1
fi

line_count=$(wc -l < result.txt)
if [ "$line_count" -ne 1 ]; then
  printf 'result.txt must contain one newline-terminated line\n' >&2
  exit 1
fi

printf 'golden path verified\n'
