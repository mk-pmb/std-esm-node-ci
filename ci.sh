#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function ci_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?
  export HOME="$SELFPATH"/home

  local INST_MTHD="${INSTALL_FROM%%:*}"
  local INST_FROM="${INSTALL_FROM#*:}"
  vdo '' ci_install_and_test_"$INST_MTHD"
  local INST_RV=$?
  ci_report_state
  return "$INST_RV"
}


function vdo () {
  local TITLE="$1"; shift
  [ -n "$TITLE" ] || TITLE="$*"
  echo "==>>== $TITLE ==>>=="
  "$@"
  local RV=$?
  echo "==<<== $TITLE | rv=$RV ==<<=="
  echo
  return "$RV"
}


function vls () {
  vdo "Files in $1" ls --escape --classify --format=long --no-group -- "$1"
}


function ci_report_state () {
  echo "Current directory: $PWD"
  vdo '' git branch --list --verbose
  vdo '' git status --short
  vls .
  vls node_modules/esm
  vls node_modules/.[a-z]*
  vdo '' npm why esm
}


function ci_install_and_test_npm () {
  cd -- "$SELFPATH" || return $?
  vdo '' npm install "$INST_FROM" || return $?
  cd -- node_modules/esm || return $?
  vdo '' npm test || return $?
}


function ci_install_and_test_gh () {
  cd -- "$SELFPATH" || return $?

  local REPO_SPEC="$INST_FROM"
  local CLONE_CMD=( git clone )

  if [[ "$REPO_SPEC" == *'#'* ]]; then
    CLONE_CMD+=( --single-branch --branch "${REPO_SPEC##*\#}" )
    REPO_SPEC="${REPO_SPEC%\#*}"
  fi

  CLONE_CMD+=( -- "https://github.com/$REPO_SPEC" repo )

  vdo '' "${CLONE_CMD[@]}" || return $?
  cd repo || return $?
  vdo '' npm install . || return $?
  ci_report_state
  vdo '' npm test || return $?
  vdo '' npm audit || return $?
}










ci_main "$@"; exit $?
