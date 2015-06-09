-------------------------------------------------------------------[31.05.2015]
-- uBus to ZXBus Version 1.0
-- DEVBOARD ReVerSE-U16
-------------------------------------------------------------------------------
-- Engineer: 	MVV
--
-- 30.05.2015	Initial version 1.0
-------------------------------------------------------------------------------
--
-- Copyright (c) 2015 MVV
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.


library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity zxbus is
port 	(
	-- uBUS
	UBUS_AP		: in std_logic;
	UBUS_AN		: in std_logic;
	UBUS_BP		: out std_logic;
	UBUS_BN		: out std_logic;
		-- ZXBus
	ZXBUS_WAIT	: in std_logic;
	ZXBUS_INT	: in std_logic;
	ZXBUS_NMI	: in std_logic;
	ZXBUS_RDROM	: in std_logic;
	ZXBUS_IORGE	: in std_logic;
	ZXBUS_D		: inout std_logic_vector(7 downto 0);
	ZXBUS_A		: out std_logic_vector(15 downto 0);
	ZXBUS_M1	: out std_logic;
	ZXBUS_MREQ	: out std_logic;
	ZXBUS_IORQ	: out std_logic;
	ZXBUS_RD	: out std_logic;
	ZXBUS_WR	: out std_logic;
	ZXBUS_ROMCS	: out std_logic;
	ZXBUS_DOS	: out std_logic;
	ZXBUS_RESET	: out std_logic
	);
end zxbus;


architecture rtl of zxbus is
signal shift_reg	: std_logic_vector(31 downto 0);
signal bit_count	: std_logic_vector(4 downto 0) := "00000";
signal data_out		: std_logic_vector(7 downto 0);
signal addr_out		: std_logic_vector(15 downto 0);
signal m1_out		: std_logic := '1';
signal rd_out		: std_logic := '1';
signal wr_out		: std_logic := '1';
signal mreq_out		: std_logic := '1';
signal iorq_out		: std_logic := '1';
signal romcs_out	: std_logic := '1';
signal dos_out		: std_logic := '1';
signal reset_out	: std_logic := '1';

begin

-------------------------------------------------------------------------------
-- uBus to ZXBus v1.0
--+-----+----------+---------------+ +-----+----------+---------------+
--| A31 | IORQGE2# | NC            | | B31 | IORQ2#   | NC            |
--| A30 | GND      |               | | B30 | GND      |               |
--| A29 | +5V      |               | | B29 | -        | -             |
--| A28 | A11      | Host -> ZXBus | | B28 | +5V      |               |
--| A27 | A9       | Host -> ZXBus | | B27 | A10      | Host -> ZXBus |
--| A26 | BUSACK#  | NC            | | B26 | A8       | Host -> ZXBus |
--| A25 | ROMCS#   | Host -> ZXBus | | B25 | RFSH#    | NC            |
--| A24 | A4       | Host -> ZXBus | | B24 | M1#      | Host -> ZXBus |
--| A23 | A5       | Host -> ZXBus | | B23 | -        | -             |
--| A22 | A6       | Host -> ZXBus | | B22 | -        | -             |
--| A21 | A7       | Host -> ZXBus | | B21 | WAIT#    | ZXBus -> Host |
--| A20 | RESET#   | Host -> ZXBus | | B20 | -        | -             |
--| A19 | BUSRQ#   | NC            | | B19 | WR#      | Host -> ZXBus |
--| A18 | -        | -             | | B18 | RD#      | Host -> ZXBus |
--| A17 | -        | -             | | B17 | IORQ#    | Host -> ZXBus |
--| A16 | RS       | NC            | | B16 | MREQ#    | Host -> ZXBus |
--| A15 | RDROM#   | ZXBus -> Host | | B15 | HALT#    | NC            |
--| A14 | GND      |               | | B14 | NMI#     | ZXBus -> Host |
--| A13 | IORGE#   | ZXBus -> Host | | B13 | INT#     | ZXBus -> Host |
--| A12 | A3       | Host -> ZXBus | | B12 | D4       | Host -> ZXBus |
--| A11 | A2       | Host -> ZXBus | | B11 | D3       | Host -> ZXBus |
--| A10 | A1       | Host -> ZXBus | | B10 | D5       | Host -> ZXBus |
--| A9  | A0       | Host -> ZXBus | | B9  | D6       | Host -> ZXBus |
--| A8  | -        | -             | | B8  | D2       | Host -> ZXBus |
--| A7  | GND      |               | | B7  | D1       | Host -> ZXBus |
--| A6  | GND      |               | | B6  | D0       | Host -> ZXBus |
--| A5  | CLK      | NC            | | B5  | -        | -             |
--| A4  | DOS#     | Host -> ZXBus | | B4  | -        | -             |
--| A3  | +5V      |               | | B3  | D7       | Host -> ZXBus |
--| A2  | A12      | Host -> ZXBus | | B2  | A13      | Host -> ZXBus |
--| A1  | A14      | Host -> ZXBus | | B1  | A15      | Host -> ZXBus |
--+-----+----------+---------------+ +-----+----------+---------------+
--
--         0-7   8-23   24  25  26  27    28    29     30   31
-- AN_I <- D7..0 A15..8 M1# RD# WR# MREQ# IORQ# ROMCS# DOS# RESET#
--         0-7   8     9    10   11     12     13-31
-- BP_O -> D7..0 WAIT# INT# NMI# RDROM# IORGE# X
-------------------------------------------------------------------------------

process (UBUS_AP)
begin	
	if UBUS_AP'event and UBUS_AP = '1' then
		if bit_count = "11111" then
			UBUS_BN   <= '1';
			shift_reg <= ZXBUS_D & ZXBUS_WAIT & ZXBUS_INT & ZXBUS_NMI & ZXBUS_RDROM & ZXBUS_IORGE & "XXXXXXXXXXXXXXXXXXX";
			data_out  <= shift_reg(30 downto 23);
			addr_out  <= shift_reg(22 downto 7);
			m1_out    <= shift_reg(6);
			rd_out    <= shift_reg(5);
			wr_out    <= shift_reg(4);
			mreq_out  <= shift_reg(3);
			iorq_out  <= shift_reg(2);
			romcs_out <= shift_reg(1);
			dos_out   <= shift_reg(0);
			reset_out <= UBUS_AN;
		else
			UBUS_BN <= '0';
			shift_reg <= shift_reg(30 downto 0) & UBUS_AN;
		end if;
		bit_count <= bit_count + "00001";
	end if;
end process;

UBUS_BP		<= shift_reg(31);
ZXBUS_D		<= data_out when rd_out = '1' else (others => 'Z');	
ZXBUS_A		<= addr_out;
ZXBUS_M1	<= m1_out;
ZXBUS_MREQ	<= mreq_out;
ZXBUS_IORQ	<= iorq_out;
ZXBUS_RD	<= rd_out;
ZXBUS_WR	<= wr_out;
ZXBUS_ROMCS	<= romcs_out;
ZXBUS_DOS	<= dos_out;
ZXBUS_RESET	<= reset_out;	

end rtl;