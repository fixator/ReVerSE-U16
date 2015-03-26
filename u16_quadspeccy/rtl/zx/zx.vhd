-------------------------------------------------------------------[14.03.2015]
-- zx
-------------------------------------------------------------------------------
-- Engineer: 	MVV
--
-- 12.02.2011	первая версия
-- 01.03.2015
-- 14.03.2015	DMA Sound

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity zx is
generic (
	Loader		: std_logic := '0';
	CPU		: std_logic_vector(1 downto 0) := "00" );
port (
	RST_I		: in  std_logic;
	CLK_I		: in  std_logic;
	SEL_I		: in  std_logic;
	ENA_1_75MHZ_I	: in  std_logic;
	ENA_0_4375MHZ_I	: in  std_logic;
	-- CPU
	CPU_DAT_O	: out std_logic_vector(7 downto 0);
	CPU_ADR_O	: out std_logic_vector(15 downto 0);
	CPU_INT_I	: in  std_logic;
	CPU_CLK_I	: in  std_logic;
	CPU_ENA_I	: in  std_logic;
	CPU_RFSH_O	: out std_logic;
	CPU_RDn_O	: out std_logic;
	CPU_WRn_O	: out std_logic;
	CPU_IORQn_O	: out std_logic;
	CPU_INTA_O	: out std_logic;
	-- ROM
	ROM_DAT_I	: in  std_logic_vector(7 downto 0);
	-- RAM
	RAM_ADR_O	: out std_logic_vector(11 downto 0);
	RAM_DAT_I	: in  std_logic_vector(7 downto 0);
	RAM_WR_O	: out std_logic;
	RAM_RD_O	: out std_logic;
	-- Video
	VIDEO_CLK_I	: in  std_logic;
	VIDEO_ADR_I	: in  std_logic_vector(12 downto 0);
	VIDEO_DAT_O	: out std_logic_vector(7 downto 0);
	VIDEO_ATTR_I	: in std_logic_vector(7 downto 0);
	VIDEO_BORDER_I	: in std_logic;
	-- Port
	PORT_XXFE_O	: out std_logic_vector(7 downto 0);
	PORT_0001_O	: out std_logic_vector(7 downto 0);
	-- Keyboard
	KEYBOARD_DAT_I	: in  std_logic_vector(4 downto 0);
	KEYBOARD_FN_I	: in  std_logic_vector(12 downto 1);
	KEYBOARD_JOY_I	: in  std_logic_vector(4 downto 0);
	KEYBOARD_SOFT_I	: in  std_logic_vector(2 downto 0);
	-- Z Controller
	ZC_DAT_I	: in  std_logic_vector(7 downto 0);
	ZC_RD_O		: out std_logic;
	ZC_WR_O		: out std_logic;
	-- SPI Controller
	SPI_DAT_I	: in  std_logic_vector(7 downto 0);
	SPI_WR_O	: out std_logic;
	SPI_BUSY	: in  std_logic;
	-- I2C Controller
	I2C_DAT_I	: in  std_logic_vector(7 downto 0);
	I2C_WR_O	: out std_logic;
	-- DivMMC
	DIVMMC_SC_O	: out std_logic;
	DIVMMC_SCLK_O	: out std_logic;
	DIVMMC_MOSI_O	: out std_logic;
	DIVMMC_MISO_I	: in  std_logic;
	DIVMMC_SEL_O	: out std_logic;
	-- TurboSound
	SSG0_A_O	: out std_logic_vector(7 downto 0);
	SSG0_B_O	: out std_logic_vector(7 downto 0);
	SSG0_C_O	: out std_logic_vector(7 downto 0);
	SSG1_A_O	: out std_logic_vector(7 downto 0);
	SSG1_B_O	: out std_logic_vector(7 downto 0);
	SSG1_C_O	: out std_logic_vector(7 downto 0);
	-- SounDrive
	COVOX_A_O	: out std_logic_vector(7 downto 0);
	COVOX_B_O	: out std_logic_vector(7 downto 0);
	COVOX_C_O	: out std_logic_vector(7 downto 0);
	COVOX_D_O	: out std_logic_vector(7 downto 0);
	-- DMA Sound
	DMASOUND_DAT_I	: in  std_logic_vector(7 downto 0);
	DMASOUND_INT_I	: in  std_logic );

end zx;

architecture rtl of zx is

-- CPU
signal cpu_reset_n	: std_logic;
signal cpu_a_bus	: std_logic_vector(15 downto 0);
signal cpu_do_bus	: std_logic_vector(7 downto 0);
signal cpu_di_bus	: std_logic_vector(7 downto 0);
signal cpu_mreq_n	: std_logic;
signal cpu_iorq_n	: std_logic;
signal cpu_wr_n		: std_logic;
signal cpu_rd_n		: std_logic;
signal cpu_rfsh_n	: std_logic;
signal cpu_int_n	: std_logic;
signal cpu_inta		: std_logic;
signal cpu_m1_n		: std_logic;
signal cpu_nmi_n	: std_logic;
-- Memory
signal ram_a_bus	: std_logic_vector(11 downto 0);
-- Port
signal port_xxfe_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_1ffd_reg	: std_logic_vector(7 downto 0);
signal port_7ffd_reg	: std_logic_vector(7 downto 0);
signal port_dffd_reg	: std_logic_vector(7 downto 0);
signal port_0000_reg	: std_logic_vector(7 downto 0) := "00011111";
signal port_0001_reg	: std_logic_vector(7 downto 0) := "00000000";
-- Keyboard
signal kb_f_bus		: std_logic_vector(12 downto 1);
signal kb_fn		: std_logic_vector(12 downto 1);
signal key		: std_logic_vector(12 downto 1) := "000000000000";
-- Video
signal vid_wr		: std_logic;
signal vid_scr		: std_logic;
-- MC146818A
signal mc146818_wr	: std_logic;
signal mc146818_a_bus	: std_logic_vector(5 downto 0);
signal mc146818_do_bus	: std_logic_vector(7 downto 0);
signal port_bff7	: std_logic;
signal port_eff7_reg	: std_logic_vector(7 downto 0);
-- TurboSound
signal ssg_sel		: std_logic;
signal ssg_cn0_bus	: std_logic_vector(7 downto 0);
signal ssg_cn1_bus	: std_logic_vector(7 downto 0);
-- System
signal reset		: std_logic;
signal loader_act	: std_logic := Loader;
signal dos_act		: std_logic := '1';
signal selector		: std_logic_vector(4 downto 0);
signal mux		: std_logic_vector(3 downto 0);
-- divmmc
signal divmmc_do	: std_logic_vector(7 downto 0);
signal divmmc_amap	: std_logic;
signal divmmc_e3reg	: std_logic_vector(7 downto 0);	


begin

-- CPU
Z1: entity work.T80s
generic map (
	Mode		=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	T2Write		=> 1,	-- 0 => WR_n active in T3, 1 => WR_n active in T2
	IOWait		=> 1)	-- 0 => Single cycle I/O, 1 => Std I/O cycle
port map(
	RESET_n		=> cpu_reset_n,
	CLK_n		=> CPU_CLK_I and CPU_ENA_I, --CLK_I and CPU_ENA_I,
	WAIT_n		=> '1',
	INT_n		=> cpu_int_n,
	NMI_n		=> cpu_nmi_n,
	BUSRQ_n		=> '1',
	M1_n		=> cpu_m1_n,
	MREQ_n		=> cpu_mreq_n,
	IORQ_n		=> cpu_iorq_n,
	RD_n		=> cpu_rd_n,
	WR_n		=> cpu_wr_n,
	RFSH_n		=> cpu_rfsh_n,
	HALT_n		=> open,
	BUSAK_n		=> open,
	A		=> cpu_a_bus,
	DI		=> cpu_di_bus,
	DO		=> cpu_do_bus,
	SavePC      	=> open,
	SaveINT     	=> open,
	RestorePC   	=> (others => '1'),
	RestoreINT  	=> (others => '1'),
	RestorePC_n 	=> '1');

-- Video memory
Z2: entity work.altram1
port map (
	clock_a		=> CPU_CLK_I,
	clock_b		=> not VIDEO_CLK_I,
	address_a	=> vid_scr & cpu_a_bus(12 downto 0),
	address_b	=> port_7ffd_reg(3) & VIDEO_ADR_I,
	data_a		=> cpu_do_bus,
	data_b		=> (others => '1'),
	q_a		=> open,
	q_b		=> VIDEO_DAT_O,
	wren_a		=> vid_wr,
	wren_b		=> '0');
	
-- TurboSound
Z3: entity work.turbosound
port map (
	RESET		=> RST_I or reset,
	CLK		=> CLK_I,
	ENA		=> ENA_1_75MHZ_I,
	A		=> cpu_a_bus,
	DI		=> cpu_do_bus,
	WR_n		=> cpu_wr_n,
	IORQ_n		=> cpu_iorq_n,
	M1_n		=> cpu_m1_n,
	SEL		=> ssg_sel,
	CN0_DO		=> ssg_cn0_bus,
	CN0_A		=> SSG0_A_O,
	CN0_B		=> SSG0_B_O,
	CN0_C		=> SSG0_C_O,
	CN1_DO		=> ssg_cn1_bus,
	CN1_A		=> SSG1_A_O,
	CN1_B		=> SSG1_B_O,
	CN1_C		=> SSG1_C_O );

-- MC146818A
U13: entity work.mc146818a
port map (
	RESET		=> RST_I,
	CLK		=> CLK_I,
	ENA		=> ENA_0_4375MHZ_I,
	CS		=> '1',
	WR		=> mc146818_wr,
	A		=> mc146818_a_bus,
	DI		=> cpu_do_bus,
	DO		=> mc146818_do_bus);

-- Soundrive
U14: entity work.soundrive
port map (
	RESET		=> RST_I or reset,
	CLK		=> CPU_CLK_I,
	CS		=> not kb_fn(7),
	WR_n		=> cpu_wr_n,
	A		=> cpu_a_bus(7 downto 0),
	DI		=> cpu_do_bus,
	IORQ_n		=> cpu_iorq_n,
	DOS		=> dos_act,
	OUTA		=> COVOX_A_O,
	OUTB		=> COVOX_B_O,
	OUTC		=> COVOX_C_O,
	OUTD		=> COVOX_D_O);

-- DivMMC
U18: entity work.divmmc
port map (
	CLK		=> CLK_I,
	EN		=> kb_fn(6),
	RESET		=> RST_I or reset,
	ADDR		=> cpu_a_bus,
	DI		=> cpu_do_bus,
	DO		=> divmmc_do,
	WR_N		=> cpu_wr_n,
	RD_N		=> cpu_rd_n,
	IORQ_N		=> cpu_iorq_n,
	MREQ_N		=> cpu_mreq_n,
	M1_N		=> cpu_m1_n,
	E3REG		=> divmmc_e3reg,
	AMAP		=> divmmc_amap,
	CS_N		=> DIVMMC_SC_O,
	SCLK		=> DIVMMC_SCLK_O,
	MOSI		=> DIVMMC_MOSI_O,
	MISO		=> DIVMMC_MISO_I);

-------------------------------------------------------------------------------
-- Регистры
process (RST_I, CPU_CLK_I, SEL_I, cpu_a_bus, port_0000_reg, cpu_mreq_n, cpu_wr_n, cpu_do_bus, port_0001_reg)
begin
	if (RST_I = '1') then
		port_0000_reg <= "00011111";		-- маска по AND порта #DFFD (4MB)
		port_0001_reg <= "00000" & not Loader & "00";	-- bit2 = (0:Loader ON, 1:Loader OFF); bit1 = (0:SRAM<->cpu, 1:SRAM<->GS); bit0 = (0:M25P16, 1:ENC424J600)
		loader_act <= Loader;
	elsif (CPU_CLK_I'event and CPU_CLK_I = '1') then
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(15 downto 0) = X"0000" then port_0000_reg <= cpu_do_bus; end if;
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(15 downto 0) = X"0001" then port_0001_reg <= cpu_do_bus; end if;
		if cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus = X"0000" and port_0001_reg(2) = '1' then loader_act <= '0'; end if;
	end if;
end process;

process (RST_I, CPU_CLK_I, reset, cpu_a_bus, dos_act, port_1ffd_reg, port_7ffd_reg, port_dffd_reg, cpu_mreq_n, cpu_wr_n, cpu_do_bus)
begin
	if (RST_I = '1' or reset = '1') then
		port_eff7_reg <= (others => '0');
		port_1ffd_reg <= (others => '0');
		port_7ffd_reg <= (others => '0');
		port_dffd_reg <= (others => '0');
		dos_act <= '1';
	elsif (CPU_CLK_I'event and CPU_CLK_I = '1') then
		if cpu_iorq_n =  '0' and cpu_wr_n =   '0' and cpu_a_bus(7 downto 0) = X"FE" then port_xxfe_reg <= cpu_do_bus; end if;
		if cpu_iorq_n =  '0' and cpu_wr_n =   '0' and cpu_a_bus = X"EFF7" then port_eff7_reg <= cpu_do_bus; end if;
		if cpu_iorq_n =  '0' and cpu_wr_n =   '0' and cpu_a_bus = X"1FFD" then port_1ffd_reg <= cpu_do_bus; end if;
		if cpu_iorq_n =  '0' and cpu_wr_n =   '0' and cpu_a_bus = X"7FFD" and port_7ffd_reg(5) = '0' then port_7ffd_reg <= cpu_do_bus; end if;
		if cpu_iorq_n =  '0' and cpu_wr_n =   '0' and cpu_a_bus = X"DFFD" and port_7ffd_reg(5) = '0' then port_dffd_reg <= cpu_do_bus; end if;
		if cpu_iorq_n =  '0' and cpu_wr_n =   '0' and cpu_a_bus = X"DFF7" and port_eff7_reg(7) = '1' then mc146818_a_bus <= cpu_do_bus(5 downto 0); end if;
		if cpu_m1_n =    '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 8) = X"3D" and port_7ffd_reg(4) = '1' then dos_act <= '1';
		elsif cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00" then dos_act <= '0'; end if;
	end if;
end process;

------------------------------------------------------------------------------
-- Селектор
mux <= ((divmmc_amap or divmmc_e3reg(7)) and kb_fn(6)) & cpu_a_bus(15 downto 13);

-- SDRAM 32M:
-- 0000000-1FFFFFF

-- 2 2222 1111 1111 1100 0000 0000
-- 4 3210 9876 5432 1098 7654 3210

-- 0 00xx_xxxx xxxx_xxxx xxxx_xxxx	0000000-03FFFFF		CPU0 RAM	4MB
-- 0 0100_0xxx xxxx_xxxx xxxx_xxxx	0400000-047FFFF		CPU0 divMMC	512K

-- 0 0100_1000 00xx_xxxx xxxx_xxxx	0480000-0483FFF		GLUK		16K
-- 0 0100_1000 01xx_xxxx xxxx_xxxx	0484000-0487FFF		TR-DOS		16K
-- 0 0100_1000 10xx_xxxx xxxx_xxxx	0488000-048BFFF		ROM'86		16K
-- 0 0100_1000 11xx_xxxx xxxx_xxxx	048C000-048FFFF		ROM'82		16K
-- 0 0100_1001 000x_xxxx xxxx_xxxx	0490000-0491FFF		divMMC	 	 8K
-- 0 0xxx_xxxx xxxx_xxxx xxxx_xxxx	0492000-07FFFFF		FREE

-- 0 10xx_xxxx xxxx_xxxx xxxx_xxxx	0800000-0BFFFFF		CPU1 RAM	4MB
-- 0 1100_0xxx xxxx_xxxx xxxx_xxxx	0C00000-0C7FFFF		CPU1 divMMC	512K
-- 0 1xxx_xxxx xxxx_xxxx xxxx_xxxx	0C80000-0FFFFFF		FREE

-- 1 00xx_xxxx xxxx_xxxx xxxx_xxxx	1000000-13FFFFF		CPU2 RAM	4MB
-- 1 0100_0xxx xxxx_xxxx xxxx_xxxx	1400000-147FFFF		CPU2 divMMC	512K
-- 1 0xxx_xxxx xxxx_xxxx xxxx_xxxx	1480000-17FFFFF		FREE

-- 1 10xx_xxxx xxxx_xxxx xxxx_xxxx	1800000-1BFFFFF		CPU3 RAM	4MB
-- 1 1100_0xxx xxxx_xxxx xxxx_xxxx	1C00000-1C7FFFF		CPU3 divMMC	512K
-- 1 1xxx_xxxx xxxx_xxxx xxxx_xxxx	1C80000-1FFFFFF		FREE

process (mux, port_7ffd_reg, port_dffd_reg, port_0000_reg, ram_a_bus, cpu_a_bus, dos_act, port_1ffd_reg, divmmc_e3reg, kb_fn)
begin
	case mux is
--		when "1000" 	   => ram_a_bus <= "10000" & not(divmmc_e3reg(6)) & "00" & not(divmmc_e3reg(6)) & '0' & divmmc_e3reg(6) & divmmc_e3reg(6);			-- ESXDOS ROM 0000-1FFF
		when "0000" 	   => ram_a_bus <= "001001000" & ((not(dos_act) and not(port_1ffd_reg(1))) or kb_fn(6)) & (port_7ffd_reg(4) and not(port_1ffd_reg(1))) & '0';	-- Seg0 ROM 0000-1FFF
		when "0001" 	   => ram_a_bus <= "001001000" & ((not(dos_act) and not(port_1ffd_reg(1))) or kb_fn(6)) & (port_7ffd_reg(4) and not(port_1ffd_reg(1))) & '1';	-- Seg0 ROM 2000-3FFF
		when "1000" 	   => ram_a_bus <= "001001001000";														-- ESXDOS ROM 0000-1FFF
		
		when "1001" 	   => ram_a_bus <= CPU & "1000" & divmmc_e3reg(5 downto 0);											-- ESXDOS RAM 2000-3FFF
		when "0010"|"1010" => ram_a_bus <= CPU & "0000001010";														-- Seg1 RAM 4000-5FFF
		when "0011"|"1011" => ram_a_bus <= CPU & "0000001011";														-- Seg1 RAM 6000-7FFF
		when "0100"|"1100" => ram_a_bus <= CPU & "0000000100";														-- Seg2 RAM 8000-9FFF
		when "0101"|"1101" => ram_a_bus <= CPU & "0000000101";														-- Seg2 RAM A000-BFFF
		when "0110"|"1110" => ram_a_bus <= CPU & (port_dffd_reg(5 downto 0) and port_0000_reg(5 downto 0)) & port_7ffd_reg(2 downto 0) & '0';				-- Seg3 RAM C000-DFFF
		when "0111"|"1111" => ram_a_bus <= CPU & (port_dffd_reg(5 downto 0) and port_0000_reg(5 downto 0)) & port_7ffd_reg(2 downto 0) & '1';				-- Seg3 RAM E000-FFFF
		when others => null;
	end case;
end process;

-------------------------------------------------------------------------------
-- SDRAM
--RAM_WR_O <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and ((mux = "1001" and (divmmc_e3reg(1 downto 0) /= "11" and divmmc_e3reg(6) /= '1')) or mux(3 downto 2) = "11" or mux(3 downto 2) = "01" or mux(3 downto 1) = "101" or mux(3 downto 1) = "001") else '0';
RAM_WR_O <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (mux = "1001" or mux(3 downto 2) = "11" or mux(3 downto 2) = "01" or mux(3 downto 1) = "101" or mux(3 downto 1) = "001") else '0';
RAM_RD_O <= not (cpu_mreq_n or cpu_rd_n);

-------------------------------------------------------------------------------
-- Port I/O
I2C_WR_O	<= '1' when (cpu_a_bus(7 downto 5) = "100" and cpu_a_bus(3 downto 0) = "1100" and cpu_wr_n = '0' and cpu_iorq_n = '0') else '0';	-- Port xx8C/xx9C[xxxxxxxx_100n1100]
mc146818_wr 	<= '1' when (port_bff7 = '1' and cpu_wr_n = '0') else '0';
port_bff7 	<= '1' when (cpu_iorq_n = '0' and cpu_a_bus = X"BFF7" and cpu_m1_n = '1' and port_eff7_reg(7) = '1') else '0';
SPI_WR_O 	<= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 1) = "0000001") else '0';
ZC_WR_O 	<= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else '0';
ZC_RD_O 	<= '1' when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else '0';
PORT_XXFE_O	<= port_xxfe_reg;
PORT_0001_O	<= port_0001_reg;

-------------------------------------------------------------------------------
-- Функциональные клавиши Fx

-- F1 = CPU0, F2 = CPU1, F3 = CPU2, F4 = CPU4, F5 = NMI, F6 = Z-Controller/DivMMC, F7 = SounDrive, F12 = CPU_RESET, Scroll = HARD_RESET, Pause = ZX_RESET
process (CLK_I, SEL_I, key, KEYBOARD_FN_I, kb_fn)
begin
	if (CLK_I'event and CLK_I = '1' and SEL_I = '1') then
		key <= KEYBOARD_FN_I;
		if (KEYBOARD_FN_I /= key) then
			kb_fn <= kb_fn xor key;
		end if;
	end if;
end process;

-------------------------------------------------------------------------------
-- Шина данных cpu
process (selector, ROM_DAT_I, RAM_DAT_I, SPI_DAT_I, SPI_BUSY, I2C_DAT_I, mc146818_do_bus, KEYBOARD_DAT_I, ZC_DAT_I, KEYBOARD_JOY_I, ssg_cn0_bus, ssg_cn1_bus, divmmc_do, port_7ffd_reg, port_dffd_reg, VIDEO_ATTR_I, DMASOUND_DAT_I)
begin
	case selector is
		when "00000" => cpu_di_bus <= ROM_DAT_I;
		when "00001" => cpu_di_bus <= RAM_DAT_I;
		when "00010" => cpu_di_bus <= SPI_DAT_I;
		when "00011" => cpu_di_bus <= SPI_BUSY & "1111111";
		when "00100" => cpu_di_bus <= I2C_DAT_I;
		when "00101" => cpu_di_bus <= mc146818_do_bus;
		when "00110" => cpu_di_bus <= "111" & KEYBOARD_DAT_I;
		when "00111" => cpu_di_bus <= ZC_DAT_I;
		when "01000" => cpu_di_bus <= "000" & KEYBOARD_JOY_I;
		when "01001" => cpu_di_bus <= ssg_cn0_bus;
		when "01010" => cpu_di_bus <= ssg_cn1_bus;
		when "01011" => cpu_di_bus <= divmmc_do;
		when "01100" => cpu_di_bus <= port_7ffd_reg;
		when "01101" => cpu_di_bus <= port_dffd_reg;
		when "01110" => cpu_di_bus <= VIDEO_ATTR_I;
		when "01111" => cpu_di_bus <= DMASOUND_DAT_I;
		when others  => cpu_di_bus <= (others => '1');
	end case;
end process;

selector <= 	"00000" when (cpu_mreq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 14) = "00" and loader_act = '1') else					-- ROM
		"00001" when (cpu_mreq_n = '0' and cpu_rd_n = '0') else 											-- RAM
		"00010" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"02" and SEL_I = '1') else					-- SPI
		"00011" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"03" and SEL_I = '1') else					-- SPI
		"00100" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 5) = "100" and cpu_a_bus(3 downto 0) = "1100" and SEL_I = '1') else 	-- I2C
		"00101" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and port_bff7 = '1' and port_eff7_reg(7) = '1') else 						-- MC146818A
		"00110" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"FE" and SEL_I = '1') else 					-- Клавиатура, порт xxFE
		"00111" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111" and SEL_I = '1') else 	-- Z-Controller
		"01000" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"1F" and dos_act = '0') else 					-- Joystick, порт xx1F
		"01001" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"FFFD" and ssg_sel = '0') else 					-- TurboSound
		"01010" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"FFFD" and ssg_sel = '1') else					-- TurboSound
		"01011" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"EB" and kb_fn(6) = '1') else					-- DivMMC
		"01100" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"7FFD") else							-- чтение порта 7FFD
		"01101" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"DFFD") else							-- чтение порта DFFD
		"01110" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"FF" and dos_act = '0' and VIDEO_BORDER_I = '1') else		-- порт атрибутов #FF
		"01111" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"50") else							-- DMA Sound
		(others => '1');

cpu_reset_n 	<= '0' when (RST_I = '1' or reset = '1' or (KEYBOARD_FN_I(12) = '1' and SEL_I = '1')) else '1';	-- CPU сброс
cpu_nmi_n 	<= '0' when (KEYBOARD_FN_I(5) = '1' and SEL_I = '1') else '1';		-- NMI
cpu_int_n	<= not (DMASOUND_INT_I or CPU_INT_I);
cpu_inta	<= not (cpu_iorq_n or cpu_m1_n);
reset 		<= '1' when (KEYBOARD_SOFT_I(2) = '1' and SEL_I = '1') else '0';	-- HARD_RESET

DIVMMC_SEL_O	<= kb_fn(6);	-- DivMMC/Z-Controller
CPU_DAT_O	<= cpu_do_bus;
CPU_ADR_O 	<= cpu_a_bus;
RAM_ADR_O 	<= ram_a_bus;

CPU_RFSH_O	<= not (cpu_rfsh_n or cpu_mreq_n);
CPU_RDn_O	<= cpu_rd_n;
CPU_WRn_O	<= cpu_wr_n;
CPU_IORQn_O	<= cpu_iorq_n;
CPU_INTA_O	<= cpu_inta;

-------------------------------------------------------------------------------
-- Video
vid_wr	<= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and ((ram_a_bus = CPU & "0000001010") or (ram_a_bus = CPU & "0000001110")) else '0'; 
vid_scr	<= '1' when (ram_a_bus = CPU & "0000001110") else '0';


end rtl;