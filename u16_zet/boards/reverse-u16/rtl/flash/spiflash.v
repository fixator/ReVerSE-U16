/*
 *  Wishbone SpiFlash RAM core for ReVerSE-U16 board By MVV'2015
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module spiflash (
    // Wishbone slave interface
    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    input             wb_we_i,
    input             wb_adr_i,
    input      [ 1:0] wb_sel_i,
    input             wb_stb_i,
    input             wb_cyc_i,
    output reg        wb_ack_o
  );

  // Registers and nets
  wire        op;
  wire        wr_command;
  wire        address0;
  reg  [20:0] address;

  wire        word;
  wire        op_word;
  reg  [ 3:0] st;
  reg  [ 7:0] lb;

  reg [21:0]  addr;
  reg         read;
  wire        busy;
//  wire        data_valid;
  wire [ 7:0] dataout;
  
  
  asmi asmi (
	.addr	 	({2'b01,addr}),
	.clkin	 	(wb_clk_i),
	.rden	 	(read),
	.read	 	(read),
	.reset	 	(wb_rst_i),
	.busy	 	(busy),
	.data_valid	(),
	.dataout	(dataout)
	);
  
  
  // Combinatorial logic
  assign op      = wb_stb_i & wb_cyc_i & !busy;
  assign word    = wb_sel_i==2'b11;
  assign op_word = op & word & !wb_we_i;

  assign address0 = (wb_sel_i==2'b10) | (word & |st[2:1]);
  assign wr_command = op & wb_we_i;  // Wishbone write access Signal

  // Behaviour
  always @(posedge wb_clk_i)
    addr <= { address, address0 };

  always @(posedge wb_clk_i)
    read <= op & !wb_we_i;

  always @(posedge wb_clk_i)
    wb_dat_o <= wb_rst_i ? 16'h0
      : (st[2] ? (wb_sel_i[1] ? { dataout, lb }
                              : { 8'h0, dataout })
               : wb_dat_o);

  // wb_ack_o
  always @(posedge wb_clk_i)
    wb_ack_o <= wb_rst_i ? 1'b0
      : (wb_ack_o ? 1'b0 : (op & (wb_we_i ? 1'b1 : st[2])));

  // st - state
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 4'h0
      : (op & st==4'h0 ? (word ? 4'b0001 : 4'b0100)
                         : { st[2:0], 1'b0 });

  // lb - low byte
  always @(posedge wb_clk_i)
    lb <= wb_rst_i ? 8'h0 : (op_word & st[1] ? dataout : 8'h0);

  // --------------------------------------------------------------------
  // Register addresses and defaults
  // --------------------------------------------------------------------
  `define FLASH_ALO   1'h0    // Lower 16 bits of address lines
  `define FLASH_AHI   1'h1    // Upper  5 bits of address lines
  always @(posedge wb_clk_i)  // Synchrounous
    if(wb_rst_i)
      address <= 21'h000000;  // Interupt Enable default
    else
      if(wr_command)          // If a write was requested
        case(wb_adr_i)        // Determine which register was writen to
            `FLASH_ALO: address[15: 0] <= wb_dat_i;
            `FLASH_AHI: address[20:16] <= wb_dat_i[4:0];
            default:    ;     // Default
        endcase               // End of case

endmodule 
