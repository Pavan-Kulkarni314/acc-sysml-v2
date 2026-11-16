#!/usr/bin/env bash
# Renders the diagrams in docs/diagrams from the model.
# Needs Graphviz ("dot") on the PATH. Run scripts/setup_pilot.sh once first.
set -euo pipefail

PILOT_DIR=".pilot"
# Java needs ";" between classpath entries and a Windows path on Git Bash (Windows).
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) SEP=";"; ROOT="$(pwd -W)" ;;
  *) SEP=":"; ROOT="$(pwd)" ;;
esac
java -Djava.awt.headless=true -cp "${PILOT_DIR}/sysml.jar${SEP}${PILOT_DIR}/classes" Render \
  "${ROOT}/${PILOT_DIR}/sysml.library/" model docs/diagrams \
  "ACC_Context|TREE|01_context" \
  "ACC_SystemRequirements|TREE|03_system_requirements" \
  "ACC_LogicalArchitecture::provideAcc|ACTION|04_functional_chain" \
  "ACC_Behaviour::AccStates|STATE|05_state_machine" \
  "ACC_PhysicalArchitecture::vehicleDesign|INTERCONNECTION|06_physical_architecture|noattributes" \
  "ACC_Verification::brakeOverrideTest|ACTION|09_tc07_brake_override" \
  2>&1 | grep -v -e "^Reading " -e "^log4j"
