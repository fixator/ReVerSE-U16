-------------------------------------------------------------------[31.05.2015]
-- uBus Master Version 1.0 (ZXBus)
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

entity ubus is
port (
	CLK_I		: in std_logic;	-- 84MHz
	RESET_I		: in std_logic;
	ZXBUS_I		: in std_logic_vector(23 downto 0);	-- ZXBus IN/OUT 24bit max (11.9047619047619ns * 24 = 285.7142857142857ns = 1T Z80@3.5MHz)
	ZXBUS_O		: out std_logic_vector(23 downto 0);
	-- uBus
	UBUS_AP		: out std_logic;
	UBUS_AN		: out std_logic;
	UBUS_BP		: in std_logic;
	UBUS_BN		: in std_logic);
end ubus;


architecture rtl of ubus is
type state_type is (init, shift);
signal state		: state_type;
signal shift_reg	: std_logic_vector(23 downto 0);
signal bit_count	: std_logic_vector(4 downto 0) := "00000";

begin

-- uBus to ZXBus v1.0
--+-----+----------+---------------+ +-----+----------+---------------+
--| a31 | IORQGE2# | NC            | | b31 | IORQ2#   | NC            |
--| a30 | GND      |               | | b30 | GND      |               |
--| a29 | +5V      |               | | b29 | -        | -             |
--| a28 | A11      | NC            | | b28 | +5V      |               |
--| a27 | A9       | NC            | | b27 | A10      | NC            |
--| a26 | BUSACK#  | NC            | | b26 | A8       | NC            |
--| a25 | ROMCS#   | Host -> ZXBus | | b25 | RFSH#    | NC            |
--| a24 | A4       | Host -> ZXBus | | b24 | M1#      | NC            |
--| a23 | A5       | Host -> ZXBus | | b23 | -        | -             |
--| a22 | A6       | Host -> ZXBus | | b22 | -        | -             |
--| a21 | A7       | Host -> ZXBus | | b21 | WAIT#    | ZXBus -> Host |
--| a20 | RESET#   | Host -> ZXBus | | b20 | -        | -             |
--| a19 | BUSRQ#   | NC            | | b19 | WR#      | Host -> ZXBus |
--| a18 | -        | -             | | b18 | RD#      | Host -> ZXBus |
--| a17 | -        | -             | | b17 | IORQ#    | Host -> ZXBus |
--| a16 | RS       | NC            | | b16 | MREQ#    | Host -> ZXBus |
--| a15 | RDROM#   | ZXBus -> Host | | b15 | HALT#    | NC            |
--| a14 | GND      |               | | b14 | NMI#     | NC            |
--| a13 | IORGE#   | ZXBus -> Host | | b13 | INT#     | NC            |
--| a12 | A3       | Host -> ZXBus | | b12 | D4       | Host -> ZXBus |
--| a11 | A2       | Host -> ZXBus | | b11 | D3       | Host -> ZXBus |
--| a10 | A1       | Host -> ZXBus | | b10 | D5       | Host -> ZXBus |
--| a9  | A0       | Host -> ZXBus | | b9  | D6       | Host -> ZXBus |
--| a8  | -        | -             | | b8  | D2       | Host -> ZXBus |
--| a7  | GND      |               | | b7  | D1       | Host -> ZXBus |
--| a6  | GND      |               | | b6  | D0       | Host -> ZXBus |
--| a5  | CLK      | NC            | | b5  | -        | -             |
--| a4  | DOS#     | NC            | | b4  | -        | -             |
--| a3  | +5V      |               | | b3  | D7       | Host -> ZXBus |
--| a2  | A12      | NC            | | b2  | A13      | NC            |
--| a1  | A14      | Host -> ZXBus | | b1  | A15      | Host -> ZXBus |
--+-----+----------+---------------+ +-----+----------+---------------+

-- Count: 23 22 21 20 19 18 17 16 15    14   13   12     11     10 09 08 07 06 05  04  03    02    01     00
-- OUT:   D7 D6 D5 D4 D3 D2 D1 D0 A15   A14  A7   A6     A5     A4 A3 A2 A1 A0 RD# WR# MREQ# IORQ# ROMCS# RESET#
-- IN:    D7 D6 D5 D4 D3 D2 D1 D0 WAIT# INT# NMI# RDROM# IORGE# X  X  X  X  X  X   X   X     X     X      X

process (RESET_I, CLK_I)
begin
	if (RESET_I = '1') then
		bit_count <= (others => '0');
		shift_reg <= (others => '1');
		state <= init;
	elsif (CLK_I'event and CLK_I = '0') then
		case state is
			when init =>
				if (UBUS_BP = '0') then	-- Start
					state <= shift;
				end if;
			when shift =>
				if (bit_count = "11111") then
					ZXBUS_O   <= shift_reg(22 downto 0) & UBUS_BN;
					shift_reg <= ZXBUS_I;
				else
					shift_reg <= shift_reg(22 downto 0) & UBUS_BN;
				end if;
				bit_count <= bit_count + "00001";
			when others => null;
		end case;
	end if;
end process;

UBUS_AP <= CLK_I;
UBUS_AN <= shift_reg(23);

end rtl;