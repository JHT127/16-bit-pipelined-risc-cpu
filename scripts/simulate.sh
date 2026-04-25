#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  simulate.sh  —  Build & run the 16-bit pipelined RISC CPU
# ─────────────────────────────────────────────────────────────
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$REPO_ROOT/sim"
OUT="$SIM_DIR/cpu_sim"

echo "==> Compiling Verilog sources..."
iverilog -g2012 -o "$OUT" \
  "$REPO_ROOT/src/core/opcodes.v" \
  "$REPO_ROOT/src/core/functions.v" \
  "$REPO_ROOT/src/utils/basic_components.v" \
  "$REPO_ROOT/src/memory/memories.v" \
  "$REPO_ROOT/src/controller/controller.v" \
  "$REPO_ROOT/src/core/datapath.v" \
  "$REPO_ROOT/src/core/CPU.v" \
  "$REPO_ROOT/tb/cpu_tb.v"

echo "==> Compilation successful. Running simulation..."
cd "$SIM_DIR" && vvp cpu_sim

echo ""
echo "==> Simulation complete."
echo "    To view waveforms:  gtkwave $SIM_DIR/cpu_dump.vcd  (if VCD dump enabled in testbench)"
