#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

find "$ROOT_DIR" -maxdepth 1 -mindepth 1 -type d \
  \( \
    -name 'C:*lighthouse.*' -o \
    -name 'C*Users*AppData*Local*lighthouse.*' -o \
    -name '*AppData*Local*lighthouse.*' -o \
    -name '*\\AppData\\Local\\lighthouse.*' -o \
    -name '@undefined' -o \
    -name '@undefined:*' -o \
    -name '*@undefined*' -o \
    -name '*undefined:*' -o \
    -name 'undefined:' \
  \) \
  -exec rm -rf -- {} +
