-------------------------------------------------------------------[11.09.2015]
-- TurboSound
-------------------------------------------------------------------------------
-- Engineer: 	MVV
--
-- 15.10.2011	Initial

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity turbosound is
port( 
	I_RESET		: in std_logic;
	I_CLK		: in std_logic;
	I_ENA		: in std_logic;
	I_ADDR		: in std_logic_vector(15 downto 0);
	I_DATA		: in std_logic_vector(7 downto 0);
	I_WR_N		: in std_logic;
	I_IORQ_N	: in std_logic;
	I_M1_N		: in std_logic;
	O_SEL		: out std_logic;
	O_CN0_DATA	: out std_logic_vector(7 downto 0);
	O_CN0_A		: out std_logic_vector(7 downto 0);
	O_CN0_B		: out std_logic_vector(7 downto 0);
	O_CN0_C		: out std_logic_vector(7 downto 0);
	O_CN1_DATA	: out std_logic_vector(7 downto 0);
	O_CN1_A		: out std_logic_vector(7 downto 0);
	O_CN1_B		: out std_logic_vector(7 downto 0);
	O_CN1_C		: out std_logic_vector(7 downto 0));
end turbosound;
 
architecture turbosound_arch of turbosound is
	signal bc1	: std_logic;
	signal bdir	: std_logic;
	signal ssg	: std_logic;
begin
	bc1  <= '1' when (I_IORQ_N = '0' and I_ADDR(15) = '1' and I_ADDR(1) = '0' and I_M1_N = '1' and I_ADDR(14) = '1') else '0';
	bdir <= '1' when (I_IORQ_N = '0' and I_ADDR(15) = '1' and I_ADDR(1) = '0' and I_M1_N = '1' and I_WR_N = '0') else '0';
	O_SEL  <= ssg;
	
	process(I_CLK, I_RESET)
	begin
		if (I_RESET = '1') then
			ssg <= '0';
		elsif (I_CLK'event and I_CLK = '1') then
			if (I_DATA(7 downto 1) = "1111111" and bdir = '1' and bc1 = '1') then
				ssg <= I_DATA(0);
			end if;
		end if;
	end process;

ssg0_unit: entity work.ay8910(rtl)
		port map(
			RESET  		=> I_RESET,
			CLK    		=> I_CLK,
			DI  		=> I_DATA,
			DO 		=> O_CN0_DATA,
			ENA   		=> I_ENA,
			CS   		=> not ssg,
			BDIR   		=> bdir,
			BC   		=> bc1,
			OUT_A		=> O_CN0_A,
			OUT_B		=> O_CN0_B,
			OUT_C		=> O_CN0_C);

ssg1_unit: entity work.ay8910(rtl)
		port map(
			RESET  		=> I_RESET,
			CLK    		=> I_CLK,
			DI  		=> I_DATA,
			DO 		=> O_CN1_DATA,
			ENA   		=> I_ENA,
			CS   		=> ssg,
			BDIR   		=> bdir,
			BC   		=> bc1,
			OUT_A		=> O_CN1_A,
			OUT_B		=> O_CN1_B,
			OUT_C		=> O_CN1_C);
end turbosound_arch;