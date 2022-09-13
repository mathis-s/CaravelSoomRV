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

## Testing
The Repo includes two test to verify SoomRV's integration into Caravel.
1. `core`: Mangagment SoC uploads & runs a naive `strlen` on SoomRV, and checks the result. Tests Wishbone interface SoomRV's SRAM and control registers.
2. `spi_gpio`: Uploads and runs a "Hello World" program on SoomRV to test GPIO integration and SoomRV's SPI.

Exhaustive tests of the core itself run using Verilator can be found in the [SoomRV repo](https://github.com/git-mathis/SoomRV).

## Die Image
![Screenshot from 2022-09-12 21-46-33](https://user-images.githubusercontent.com/39701487/189902810-aaabe4e6-5821-43af-9e09-a8cd39d7afd1.png)
