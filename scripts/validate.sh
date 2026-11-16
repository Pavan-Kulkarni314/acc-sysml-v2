#!/usr/bin/env bash
# Parses and validates every model file with the SysML v2 Pilot Implementation.
# Exits with an error if any file has syntax or semantic errors.
# Run scripts/setup_pilot.sh once before using this script.
set -euo pipefail

PILOT_DIR=".pilot"
# Java needs ";" between classpath entries and a Windows path on Git Bash (Windows).
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) SEP=";"; ROOT="$(pwd -W)" ;;
  *) SEP=":"; ROOT="$(pwd)" ;;
esac
java -cp "${PILOT_DIR}/sysml.jar${SEP}${PILOT_DIR}/classes" Validate \
  "${ROOT}/${PILOT_DIR}/sysml.library/" model/*.sysml 2>&1 \
  | grep -v -e "^Reading " -e "^log4j"
