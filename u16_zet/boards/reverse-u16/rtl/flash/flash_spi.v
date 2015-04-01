/*
 *  Wishbone Flash RAM core for Altera DE0 board
 *  Copyright (C) 2010  Donna Polehn <dpolehn@verizon.net>
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

module flash_spi (
     // Wishbone slave interface
    input           wb_clk_i,
    input           wb_rst_i,
    input  [15:0]   wb_dat_i,
    output [15:0]   wb_dat_o,
    input           wb_we_i,
    input           wb_adr_i,    // Wishbone address line
    input  [ 1:0]   wb_sel_i,
    input           wb_stb_i,
    input           wb_cyc_i,
    output          wb_ack_o,

    // Pad signals
//    input	  clk,
    input 	  flash_miso_,
    output	  flash_mosi_,
    output	  flash_sck_,
    output	  flash_cs_n_

    // Pad signals
    // output [21:0] flash_addr_,
    // input  [15:0] flash_data_,
    // output        flash_we_n_,
    // output        flash_oe_n_,
    // output        flash_ce_n_,
    // output        flash_rst_n_
  );

  // Registers and nets
  wire        op;
  wire        wr_command;
  reg  [23:0] address;
  wire  [15:0] data;

  // spi read done
  wire ack;

  // spi flash controller
  spi_flash_controller spi_contr(
    .clk(wb_clk_i),
    .rst(wb_rst_i),
    .ce(!op),
    .ack(ack),
    .adr(address[23:0]),
    .dat_o(data),
    .SPI_MOSI(flash_mosi_),
    .SPI_MISO(flash_miso_),
    .SPI_CLK(flash_sck_),
    .SPI_SELN(flash_cs_n_)
  );

  // Combinatorial logic
  assign op = wb_stb_i & wb_cyc_i;

  assign wr_command   = op & wb_we_i;  // Wishbone write access Signal

  assign wb_ack_o = op & ack;
  assign wb_dat_o = data;

  // --------------------------------------------------------------------
  // Register addresses and defaults
  // --------------------------------------------------------------------
  `define FLASH_ALO   1'h0    // Lower 16 bits of address lines
  `define FLASH_AHI   1'h1    // Upper  6 bits of address lines
  always @(posedge wb_clk_i)  // Synchrounous
    if(wb_rst_i)
      address <= 24'b010000000000000000000000;  // Interupt Enable default
    else
      if(wr_command)          // If a write was requested
        case(wb_adr_i)        // Determine which register was writen to
            `FLASH_ALO: address[16: 0] <= {wb_dat_i,1'b0};
            `FLASH_AHI: address[23:17] <= {2'b01,wb_dat_i[3:0]};	// 4MB available
            default:    ;     // Default
        endcase               // End of case

endmodule
