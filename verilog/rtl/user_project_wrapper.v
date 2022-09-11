// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

wire[8:0] mem_addr;
wire[31:0] mem_dataOut;
wire[31:0] mem_dataIn;
wire[3:0] mem_wm;
wire mem_we;
wire mem_ce;

wire[8:0] instr_addr;
wire[63:0] instr_dataIn;
wire instr_ce;

wire[8:0]  instrMgmt_addr;
wire[63:0] instrMgmt_dataIn;
wire[63:0] instrMgmt_dataOut;
wire  instrMgmt_ce;
wire       instrMgmt_we;
wire[7:0]  instrMgmt_wm;

wire zero;

// Core
soomrv mprj (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),

    // Logic Analyzer

    //.la_data_in(la_data_in),
    .la_data_out(la_data_out),
    //.la_oenb (la_oenb),

    // IO Pads

    .io_in (io_in),
    .io_out(io_out),
    .io_oeb(io_oeb),
    .analog_io(analog_io),
    
    .user_clock2(user_clock2),

    .mem_addr(mem_addr),
    .mem_dataOut(mem_dataOut),
    .mem_dataIn(mem_dataIn),
    .mem_wm(mem_wm),
    .mem_we(mem_we),
    .mem_ce(mem_ce),

    .instr_addr(instr_addr),
    .instr_dataIn(instr_dataIn),
    .instr_ce(instr_ce),

    .instrMgmt_addr(instrMgmt_addr),
    .instrMgmt_dataIn(instrMgmt_dataIn),
    .instrMgmt_dataOut(instrMgmt_dataOut),
    .instrMgmt_ce(instrMgmt_ce),
    .instrMgmt_we(instrMgmt_we),
    .instrMgmt_wm(instrMgmt_wm),

    .zero(zero),

    // IRQ
    .irq(user_irq)
);

// Data SRAM
/*sky130_sram_8kbyte_1rw1r_32x2048_8 ram
(
    .clk0(wb_clk_i),
    .csb0(mem_ce),
    .web0(mem_we),
    .wmask0(mem_wm),
    .addr0(mem_addr[10:0]),
    .din0(mem_dataOut),
    .dout0(mem_dataIn),
    
    .clk1(wb_clk_i),
    .csb1(mem_ce),
    .addr1(mem_addr[10:0]),
    .dout1()
);

wire notConnected;
sky130_sram_8kbyte_1rw_64x1024_8 pram
(
    .clk0(wb_clk_i),
    .csb0(instr_ce),
    .web0(instr_we),
    .wmask0(instr_wm),
    .spare_wen0(instr_wm[7]),
    .addr0(instr_addr[10:0]),
    .din0({instr_dataOut[63], instr_dataOut[63:0]}),
    .dout0({notConnected, instr_dataIn[63:0]}),
);*/

sky130_sram_2kbyte_1rw1r_32x512_8 pram0
(
    .clk0(wb_clk_i),
    .csb0(instrMgmt_ce),
    .web0(instrMgmt_we),
    .wmask0(instrMgmt_wm[3:0]),
    .addr0(instrMgmt_addr[8:0]),
    .din0(instrMgmt_dataOut[31:0]),
    .dout0(instrMgmt_dataIn[31:0]),
    
    .clk1(wb_clk_i),
    .csb1(instr_ce),
    .addr1(instr_addr[8:0]),
    .dout1(instr_dataIn[31:0])
);

sky130_sram_2kbyte_1rw1r_32x512_8 pram1
(
    .clk0(wb_clk_i),
    .csb0(instrMgmt_ce),
    .web0(instrMgmt_we),
    .wmask0(instrMgmt_wm[7:4]),
    .addr0(instrMgmt_addr[8:0]),
    .din0(instrMgmt_dataOut[63:32]),
    .dout0(instrMgmt_dataIn[63:32]),
    
    .clk1(wb_clk_i),
    .csb1(instr_ce),
    .addr1(instr_addr[8:0]),
    .dout1(instr_dataIn[63:32])
);

sky130_sram_2kbyte_1rw1r_32x512_8 ram
(
    .clk0(wb_clk_i),
    .csb0(mem_ce),
    .web0(mem_we),
    .wmask0(mem_wm),
    .addr0(mem_addr[8:0]),
    .din0(mem_dataOut),
    .dout0(mem_dataIn),
    
    .clk1(zero),
    .csb1(mem_ce),
    .addr1(mem_addr[8:0]),
    .dout1()
);

endmodule	// user_project_wrapper

`default_nettype wire
