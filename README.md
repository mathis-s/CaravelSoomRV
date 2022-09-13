# SoomRV

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)



## Description
SoomRV is a simple superscalar Out-of-Order RISC-V microprocessor. It can execute 2 Instructions per cycle completely out of order,
and also supports speculative execution and precise exceptions.

## Features
- RV32IMZbaZbb Instruction Set (other instructions can be emulated via traps)
- 2 IPC for simple Int-Ops, 1 IPC Load/Store
- Fully Out-of-Order Load/Store
- Adaptive Branch Predictor (local 2-bit history) combined with 48 Entry Branch Target Buffer
- Tag-based OoO Execution with 32 speculative registers (in addition to the 32 architectural registers)
- 30 Entry Reorder Buffer allows executing code after skipping up to 30 Instructions
- 4KiB ICache + 4KiB DCache

## Repo
The Verilog source files can be found in `verilog/rtl`. These are converted from SystemVerilog via zachjs' [sv2v](https://github.com/zachjs/sv2v),
the original SystemVerilog source code is available [here](https://github.com/git-mathis/SoomRV).
