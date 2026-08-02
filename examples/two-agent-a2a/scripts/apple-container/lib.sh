#!/usr/bin/env bash
# Shared helpers for Apple Container peer-share labs.
# shellcheck shell=bash

apple_guest_arch_args() {
  # Args for `container run` matching the fetched Linux binary.
  local bin="${1:-}"
  if [[ -n "$bin" ]] && file "$bin" 2>/dev/null | grep -Eqi 'ARM aarch64|aarch64'; then
    echo --arch arm64
    return 0
  fi
  # Default / x86_64 linux binary → amd64 guest + Rosetta on Apple Silicon.
  echo --arch amd64 --rosetta
}
