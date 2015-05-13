

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

ENTITY USB_PS2 IS
	PORT
	(
		USB	: IN STD_LOGIC_VECTOR  (7 DOWNTO 0);
		PS2	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END USB_PS2;


ARCHITECTURE USB_PS2_AR OF USB_PS2 IS

BEGIN
--=========================================
U1: process (USB)
begin
	CASE USB IS
		when X"e1" =>  PS2 <= x"12"; -- Left shift  (CAPS SHIFT)
		when X"e5" =>  PS2 <= x"59"; -- Right shift (SYMB SHIFT)
		when X"1d" =>  PS2 <= x"1a"; -- Z
		when X"1b" =>  PS2 <= x"22"; -- X
		when X"06" =>  PS2 <= x"21"; -- C		
		when X"19" =>  PS2 <= x"2a"; -- V	
				--
		when X"04" =>  PS2 <= x"1c"; -- A
		when X"16" =>  PS2 <= x"1b"; -- S
		when X"07" =>  PS2 <= x"23"; -- D
		when X"09" =>  PS2 <= x"2b"; -- F
		when X"0a" =>  PS2 <= x"34"; -- G
				--
		when X"14" =>  PS2 <= x"15"; -- Q
		when X"1a" =>  PS2 <= x"1d"; -- W
		when X"08" =>  PS2 <= x"24"; -- E		
		when X"15" =>  PS2 <= x"2d"; -- R	
		when X"17" =>  PS2 <= x"2c"; -- T	
				--
		when X"1e" => PS2 <= x"16"; -- 1	
		when X"1f" => PS2 <= x"1e"; -- 2
		when X"20" => PS2 <= x"26"; -- 3	
		when X"21" => PS2 <= x"25"; -- 4
		when X"22" => PS2 <= x"2e"; -- 5
				--
		when X"27" => PS2 <= x"45"; -- 0
		when X"26" => PS2 <= x"46"; -- 9
		when X"25" => PS2 <= x"3e"; -- 8
		when X"24" => PS2 <= x"3d"; -- 7
		when X"23" => PS2 <= x"36"; -- 6
				--
		when X"13" => PS2 <= x"4d"; -- P
		when X"12" => PS2 <= x"44"; -- O	
		when X"0c" => PS2 <= x"43"; -- I
		when X"18" => PS2 <= x"3c"; -- U
		when X"1c" => PS2 <= x"35"; -- Y
				--
		when X"28" => PS2 <= x"5a"; -- ENTER
		when X"0f" => PS2 <= x"4b"; -- L
		when X"0e" => PS2 <= x"42"; -- K
		when X"0d" => PS2 <= x"3b"; -- J	
		when X"0b" => PS2 <= x"33"; -- H		
				--
		when X"2c" => PS2 <= x"29"; -- SPACE	
		when X"e4" => PS2 <= x"14"; -- CTRL (Symbol Shift)
		when X"10" => PS2 <= x"3a"; -- M		
		when X"11" => PS2 <= x"31"; -- N
		when X"05" => PS2 <= x"32"; -- B
		-- Cursor keys
		when X"50" => PS2 <= x"6b"; -- Left (CAPS 5)
		when X"51" => PS2 <= x"72"; -- Down (CAPS 6)
		when X"52" => PS2 <= x"75"; -- Up (CAPS 7	
		when X"4f" => PS2 <= x"74"; -- Right (CAPS 8)
		-- Other special keys sent to the ULA as key combinations
		when X"2a" => PS2 <= x"66"; -- Backspace (CAPS 0)	
		when X"39" => PS2 <= x"58"; -- Caps lock (CAPS 2)		
		when X"2b" => PS2 <= x"0d"; -- Tab (CAPS SPACE)		
		when X"37" => PS2 <= x"49"; -- .		
		when X"2d" => PS2 <= x"4e"; -- -
		when X"35" => PS2 <= x"0e"; -- ` (EDIT)
		when X"36" => PS2 <= x"41"; -- ,
		when X"33" => PS2 <= x"4c"; -- ;
		when X"34" => PS2 <= x"52"; -- "	
		when X"31" => PS2 <= x"5d"; -- :		
		when X"2e" => PS2 <= x"55"; -- =		
		when X"2f" => PS2 <= x"54"; -- (	
		when X"30" => PS2 <= x"5b"; -- )	
		when X"38" => PS2 <= x"4a"; -- ?	
		--------------------------------------------
		-- Soft keys
		when X"3a" => PS2 <= x"05"; -- F1
		when X"3b" => PS2 <= x"06"; -- F2
		when X"3c" => PS2 <= x"04"; -- F3
		when X"3d" => PS2 <= x"0c"; -- F4
		when X"3e" => PS2 <= x"03"; -- F5
		when X"3f" => PS2 <= x"0b"; -- F6
		when X"40" => PS2 <= x"83"; -- F7
		when X"41" => PS2 <= x"0a"; -- F8
		when X"42" => PS2 <= x"01"; -- F9
		when X"43" => PS2 <= x"09"; -- F10
		when X"44" => PS2 <= x"78"; -- F11
		when X"45" => PS2 <= x"07"; -- F12	
		-- Hardware keys
		when X"46" => PS2 <= x"7c";	-- PrtScr
		when X"47" => PS2 <= x"7e";	-- Scroll Lock
		when X"48" => PS2 <= x"77";	-- Pause
		when X"65" => PS2 <= x"2f";	-- WinMenu
		when X"e7" => PS2 <= x"27";	-- Right GUI
		when X"29" => PS2 <= x"76";	-- Esc
		when X"49" => PS2 <= x"70";	-- Insert
		when X"4a" => PS2 <= x"6c";	-- Home
		when X"4b" => PS2 <= x"7d";	-- Page Up
		when X"4c" => PS2 <= x"71";	-- Delete
		when X"4d" => PS2 <= x"69";	-- End
		when X"4e" => PS2 <= x"7a";	-- Page Down
		----------------------------------------------------
		when X"e0" => PS2 <= x"14";	-- Left  Ctrl
		when X"e2" => PS2 <= x"11";	-- Left  Alt
		when X"e3" => PS2 <= x"1F";	-- Left  GUI -- RESET 
		when X"e6" => PS2 <= x"11";	-- Right Alt
		
		when others => null;
	END CASE;
end process;
--=========================================	
END USB_PS2_AR;

