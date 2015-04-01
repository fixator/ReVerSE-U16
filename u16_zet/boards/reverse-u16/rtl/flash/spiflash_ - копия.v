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
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input         wb_we_i,
    input         wb_adr_i,
    input  [ 1:0] wb_sel_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    output        wb_ack_o
  );

  // Registers and nets
  wire        op;
  wire        wr_command;
  reg  [20:0] address;

  wire        word;
  wire        op_word;
  reg         st;
  reg  [ 7:0] lb;

  wire [23:0] addr;
  wire        data_valid;
  wire [ 7:0] dataout;
  
  
  asmi asmi (
	.addr	 	(addr),
	.clkin	 	(wb_clk_i),
	.rden	 	(op),
	.read	 	(op),
	.reset	 	(wb_rst_i),
	.busy	 	(),
	.data_valid	(data_valid),
	.dataout	(dataout)
	);
  
  
  // Combinatorial logic
  assign op      = wb_stb_i & wb_cyc_i;
  assign word    = wb_sel_i==2'b11;
  assign op_word = op & word & !wb_we_i;

  assign addr[23:1] = {2'b01, address};
  assign addr[0]    = (wb_sel_i==2'b10) | (word & st);
  assign wr_command = op & wb_we_i;  // Wishbone write access Signal

  assign wb_ack_o = op & data_valid & (op_word ? st : 1'b1);
  assign wb_dat_o = wb_sel_i[1] ? { dataout, lb }
                                : { 8'h0, dataout };

  // Behaviour
  // st - state
  always @(posedge wb_clk_i)
    st <= wb_rst_i ? 1'b0 : op_word;

  // lb - low byte
  always @(posedge wb_clk_i)
    lb <= wb_rst_i ? 8'h0 : (op_word ? dataout : 8'h0);

  // --------------------------------------------------------------------
  // Register addresses and defaults
  // --------------------------------------------------------------------
  `define FLASH_ALO   1'h0    // Lower 16 bits of address lines
  `define FLASH_AHI   1'h1    // Upper  6 bits of address lines
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
