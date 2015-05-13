-------------------------------------------------------------------[07.09.2014]
-- KEYBOARD CONTROLLER USB HID 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity usb_keyb is
port (
	CLK		: in std_logic; -- 12.5Mhz (origin - )
	RESET		: in std_logic; -- active HI!!!
	--------------------------------------------ZX-----------------
	KEYF		: out std_logic_vector(4 downto 0);
	KEYJOY	: out std_logic_vector(4 downto 0);
	----------------------------------------------------------------
	SCANCODE_RD_n  : in std_logic;                      --< active LO
	SCANCODE		   : out std_logic_vector(7 downto 0);  --> OUT
	FIFO_b         : out std_logic;                     --> RX FIFO not empy active HI
	----------------------------------------------------------------
	RST_OUT		   : out std_logic;                      --> Soft Reset
	--------------------------------------------
	RX				   : in std_logic                        --< USB_RX
	); 
end usb_keyb;

architecture rtl of usb_keyb is
-- Interface to RX block
signal keyb_data	: std_logic_vector(7 downto 0);

-- Internal signals
-------------------------------------------------------------------------------------
signal check_press, check_release  : std_logic_vector(15 downto 0);
signal CLK_B, SW_1, SW_2 			  : integer;
type   LIN_BUFF_t is array (14 downto 0) of std_logic_vector(7 downto 0);
type   DB_LIN_BUFF_t is array (1 downto 0) of LIN_BUFF_t;
signal DB_LIN_BUFF : DB_LIN_BUFF_t;
--------------------------------------
signal USB 				: std_logic_vector(7 downto 0);
signal PS2_Set2 		: std_logic_vector(7 downto 0);
signal PS2 				: std_logic_vector(7 downto 0);
signal key_scancode 	: std_logic_vector(7 downto 0);
--//==RX BUFF ===============================================
signal buff_in				: std_logic_vector(7 downto 0);
signal buff_out			: std_logic_vector(7 downto 0);
signal RD_r					: std_logic_vector(1 downto 0);
-------------------------
signal RX_head_cnt		: unsigned(7 downto 0) := "00000000";	
signal RX_tail_cnt		: unsigned(7 downto 0) := "00000000";
signal RX_fifo_out		: std_logic_vector(7 downto 0);
signal WR_RX_BUFF    	: std_logic := '0';
signal rx_fifo_notempty : std_logic := '0'; 
signal rx_fifo_full		: std_logic := '0';


component ps2_keyb_xtcodes is
port (
    at_code       : in   std_logic_vector(6 downto 0);
    xt_code       : out  std_logic_vector(6 downto 0)
  );
end component;

begin
---------------TEST ------------------
--TST_WR  <= WR_RX_BUFF;
--TST_DAT <= buff_in;
--------------------------------------


	inst_rx : entity work.receiver
	port map (
		CLK      => CLK,
		nRESET   => not RESET,
		RX       => RX,          --< USB_RX
		DATA     => keyb_data    --> KEYB_DATA
		);

	KEYJOY 	<= "00000";
	KEYF 		<= "00000";
	--SCANCODE	<= scan; =====================
	SCANCODE	<= key_scancode;   -- from buffer 
	FIFO_b <= rx_fifo_notempty; -- buffer cnt
	
	process (RESET, CLK, keyb_data)
	begin
		if RESET = '1' then
			-------------------2014_09_21--
			CLK_B <= 0;
			SW_1  <= 0;
			SW_2  <= 1;
			RX_head_cnt <= X"00";
			RX_tail_cnt <= X"00";
			WR_RX_BUFF  <= '0';	
			RST_OUT     <= '0'; 
			-----------------------------------------
		elsif CLK'event and CLK = '1' then
		CLK_B <= CLK_B + 1;
			case keyb_data is
				when X"02" =>
					--------------------
					CLK_B <= 0; 
					check_press   <= "0011111111111111";
					check_release <= "0011111111111111";
					if (SW_1 = 0) then 
						SW_1 <= 1;
						SW_2 <= 0; 	
					else 
						SW_1 <= 0;
						SW_2 <= 1;
					end if;				
				-----------------------------------------------------
				when others => null;
			end case;
			--======================================================
			--======================================================
			--scan -  1clk delay.
			case CLK_B is
				when 0 =>                  --USB E0 : Left Control
					DB_LIN_BUFF(SW_1)(6) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(6)) then
						check_press (6) <= '0'; 
						check_release (6) <= '0';
					elsif (keyb_data =  x"E0")            then
						check_release (6) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(6) =  x"E0") then 
						check_press (6) <= '0';
					end if;	
				------------------------------------------------	
				when 1 => 						--USB E1 : Left Shift
					DB_LIN_BUFF(SW_1)(7) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(7)) then
						check_press (7) <= '0'; 
						check_release (7) <= '0';
					elsif (keyb_data =  x"E1")            then
						check_release (7) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(7) =  x"E1") then 
						check_press (7) <= '0';
					end if;	
				when 2 => 						--USB E2 : Left ALT
					DB_LIN_BUFF(SW_1)(8) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(8)) then
						check_press (8) <= '0'; 
						check_release (8) <= '0';
					elsif (keyb_data =  x"E2")            then
						check_release (8) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(8) =  x"E2") then 
						check_press (8) <= '0';
					end if;	  
				when 3 => 						--USB E3 : Left GUI
					DB_LIN_BUFF(SW_1)(9) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(9)) then
						check_press (9) <= '0'; 
						check_release (9) <= '0';
					elsif (keyb_data =  x"E3")            then
						check_release (9) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(9) =  x"E3") then 
						check_press (9) <= '0';
					end if;
					------------------Areset------------------------
					if(keyb_data = x"E3") then 
						RST_OUT <= '1'; 
					else 
						RST_OUT <= '0'; 
					end if;
					------------------------------------------------
				when 4 => 						--USB E4 : Right Control
					DB_LIN_BUFF(SW_1)(10) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(10)) then
						check_press (10) <= '0'; 
						check_release (10) <= '0';
					elsif (keyb_data =  x"E4")             then
						check_release (10) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(10) =  x"E4") then 
						check_press (10) <= '0';
					end if;	 
				when 5 => 						--USB E5 : Right Shift
					DB_LIN_BUFF(SW_1)(11) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(11)) then
						check_press (11) <= '0'; 
						check_release (11) <= '0';
					elsif (keyb_data =  x"E5")             then
						check_release (11) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(11) =  x"E5") then 
						check_press (11) <= '0';
					end if;	 
				when 6 => 						--USB E6 : Right ALT
					DB_LIN_BUFF(SW_1)(12) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(12)) then
						check_press (12) <= '0'; 
						check_release (12) <= '0';
					elsif (keyb_data =  x"E6")             then
						check_release (12) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(12) =  x"E6") then 
						check_press (12) <= '0';
					end if;	  
				when 7 => 						--USB E7 : Right GUI
					DB_LIN_BUFF(SW_1)(13) <= keyb_data ;	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(13)) then
						check_press (13) <= '0'; 
						check_release (13) <= '0';
					elsif (keyb_data =  x"E7")            then
						check_release (13) <= '0';
					elsif (DB_LIN_BUFF(SW_2)(13) =  x"E7") then 
						check_press (13) <= '0';
					end if;	
	         --====================================
				--when 8 => --NOT USED
				--============================================
				--==================================== N0 ====
				when 9 =>  --N10    -- FIRST KEY (keyb_data) 
					DB_LIN_BUFF(SW_1)(0) <= keyb_data; 
				   ------ 0	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(0)) then
						check_press   (0) <= '0';
						check_release (0) <= '0'; 	
					end if;
					------ 1
					if(keyb_data =  DB_LIN_BUFF(SW_2)(1)) then
						check_press (0) <= '0';
						check_release (1) <= '0'; 	
					end if;
					------ 2
					if(keyb_data =  DB_LIN_BUFF(SW_2)(2)) then
						check_press (0) <= '0';
						check_release (2) <= '0'; 	
					end if;
					------ 3
					if(keyb_data =  DB_LIN_BUFF(SW_2)(3)) then
						check_press (0) <= '0';
						check_release (3) <= '0'; 	
					end if;
					------ 4
					if(keyb_data =  DB_LIN_BUFF(SW_2)(4)) then
						check_press (0) <= '0'; 
						check_release (4) <= '0'; 
					end if;
					------ 5
					if(keyb_data =  DB_LIN_BUFF(SW_2)(5)) then
						check_press (0) <= '0'; 
						check_release (5) <= '0'; 
					end if;
				--==================================== N1 ====	
				when 10 =>
					DB_LIN_BUFF(SW_1)(1) <= keyb_data;
					------ 0	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(0)) then
						check_press (1) <= '0';
						check_release (0) <= '0'; 	
					end if;
					------ 1
					if(keyb_data =  DB_LIN_BUFF(SW_2)(1)) then
						check_press (1) <= '0';
						check_release (1) <= '0'; 	
					end if;
					------ 2
					if(keyb_data =  DB_LIN_BUFF(SW_2)(2)) then
						check_press (1) <= '0';
						check_release (2) <= '0'; 	
					end if;
					------ 3
					if(keyb_data =  DB_LIN_BUFF(SW_2)(3)) then
						check_press (1) <= '0';
						check_release (3) <= '0'; 	
					end if;
					------ 4
					if(keyb_data =  DB_LIN_BUFF(SW_2)(4)) then
						check_press (1) <= '0';
						check_release (4) <= '0'; 	
					end if;
					------ 5
					if(keyb_data =  DB_LIN_BUFF(SW_2)(5)) then
						check_press (1) <= '0';
						check_release (5) <= '0'; 	
					end if;
				--==================================== N2 ====
				when 11 =>
					DB_LIN_BUFF(SW_1)(2) <= keyb_data;
					------ 0	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(0)) then
						check_press (2) <= '0';
						check_release (0) <= '0'; 	
					end if;
					------ 1
					if(keyb_data =  DB_LIN_BUFF(SW_2)(1)) then
						check_press (2) <= '0';
						check_release (1) <= '0'; 	
					end if;
					------ 2
					if(keyb_data =  DB_LIN_BUFF(SW_2)(2)) then
						check_press (2) <= '0';
						check_release (2) <= '0'; 	
					end if;
					------ 3
					if(keyb_data =  DB_LIN_BUFF(SW_2)(3)) then
						check_press (2) <= '0';
						check_release (3) <= '0'; 	
					end if;
					------ 4
					if(keyb_data =  DB_LIN_BUFF(SW_2)(4)) then
						check_press (2) <= '0';
						check_release (4) <= '0'; 	
					end if;
					------ 5
					if(keyb_data =  DB_LIN_BUFF(SW_2)(5)) then
						check_press (2) <= '0';
						check_release (5) <= '0'; 	
					end if;
				--==================================== N3 ====	
				when 12 =>
					DB_LIN_BUFF(SW_1)(3) <= keyb_data;
					------ 0	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(0)) then
						check_press (3) <= '0';
						check_release (0) <= '0'; 	
					end if;
					------ 1
					if(keyb_data =  DB_LIN_BUFF(SW_2)(1)) then
						check_press (3) <= '0';
						check_release (1) <= '0'; 	
					end if;
					------ 2
					if(keyb_data =  DB_LIN_BUFF(SW_2)(2)) then
						check_press (3) <= '0';
						check_release (2) <= '0'; 	
					end if;
					------ 3
					if(keyb_data =  DB_LIN_BUFF(SW_2)(3)) then
						check_press (3) <= '0';
						check_release (3) <= '0'; 	
					end if;
					------ 4
					if(keyb_data =  DB_LIN_BUFF(SW_2)(4)) then
						check_press (3) <= '0';
						check_release (4) <= '0'; 	
					end if;
					------ 5
					if(keyb_data =  DB_LIN_BUFF(SW_2)(5)) then
						check_press (3) <= '0';
						check_release (5) <= '0'; 	
					end if;
				--==================================== N4 ====	
				when 13 =>
					DB_LIN_BUFF(SW_1)(4) <= keyb_data;
					------ 0	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(0)) then
						check_press (4) <= '0';
						check_release (0) <= '0'; 	
					end if;
					------ 1
					if(keyb_data =  DB_LIN_BUFF(SW_2)(1)) then
						check_press (4) <= '0';
						check_release (1) <= '0'; 	
					end if;
					------ 2
					if(keyb_data =  DB_LIN_BUFF(SW_2)(2)) then
						check_press (4) <= '0';
						check_release (2) <= '0'; 	
					end if;
					------ 3
					if(keyb_data =  DB_LIN_BUFF(SW_2)(3)) then
						check_press (4) <= '0';
						check_release (3) <= '0'; 	
					end if;
					------ 4
					if(keyb_data =  DB_LIN_BUFF(SW_2)(4)) then
						check_press (4) <= '0';
						check_release (4) <= '0'; 	
					end if;
					------ 5
					if(keyb_data =  DB_LIN_BUFF(SW_2)(5)) then
						check_press (4) <= '0';
						check_release (5) <= '0'; 	
					end if;
				--==================================== N5 ====
				when 14 =>
					DB_LIN_BUFF(SW_1)(5) <= keyb_data;
					------ 0	
					if(keyb_data =  DB_LIN_BUFF(SW_2)(0)) then
						check_press (5) <= '0';
						check_release (0) <= '0'; 	
					end if;
					------ 1
					if(keyb_data =  DB_LIN_BUFF(SW_2)(1)) then
						check_press (5) <= '0';
						check_release (1) <= '0'; 	
					end if;
					------ 2
					if(keyb_data =  DB_LIN_BUFF(SW_2)(2)) then
						check_press (5) <= '0';
						check_release (2) <= '0'; 	
					end if;
					------ 3
					if(keyb_data =  DB_LIN_BUFF(SW_2)(3)) then
						check_press (5) <= '0';
						check_release (3) <= '0'; 	
					end if;
					------ 4
					if(keyb_data =  DB_LIN_BUFF(SW_2)(4)) then
						check_press (5) <= '0';
						check_release (4) <= '0'; 	
					end if;
					------ 5
					if(keyb_data =  DB_LIN_BUFF(SW_2)(5)) then
						check_press (5) <= '0';
						check_release (5) <= '0'; 	
					end if;
				--============================================
				--==================================================================================
				--=========================================  E0 Left Control
				----break
				when 15 =>
					buff_in <= x"F0"; -- break
				   if (check_release (6) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= x"E0";
				when 16 =>				
					buff_in <= '1' & PS2(6 downto 0);  -- buff_in <= x"9D";
				----press
				when 17 =>           -- press
					buff_in <= '0' & PS2(6 downto 0);  -- buff_in <= x"1D";
					if (check_press (6) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				--===========================================
			   --=========================================E1 Left Shift
				----break
				when 18 =>
					buff_in <= x"F0"; -- break
				   if (check_release (7) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= x"E1";
				when 19 =>	         -- 
					buff_in <= '1' & PS2(6 downto 0); -- Left Shift PS2 (Set1)  -- <= x"AA";
				----press
				when 20 =>           
					buff_in <= '0' & PS2(6 downto 0); -- PS2 (Set1) Left Shift  -- <= x"2A"; 
					if (check_press (7) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				--===========================================
				--========================================= E2 Left Alt
				----break
				when 21 =>
					buff_in <= x"F0"; -- break
				   if (check_release (8) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= x"E2";    
				when 22 =>           
					buff_in <= '1' & PS2(6 downto 0); --buff_in <= x"B8"; -- PS2 (Set1) Left Shift
				----press
				when 23 =>          
					buff_in <= '0' & PS2(6 downto 0); --buff_in <= x"38"; -- PS2 (Set1) Left Alt
					if (check_press (8) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				--===========================================
				--=========================================E3 LEFT GUI
				----break
				when 24 =>
					buff_in <= x"E0"; -- extended /break
				   if (check_release (9) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 25 =>	
					buff_in <= x"F0"; -- break
					USB <= x"E3";
				when 26 =>
					buff_in <= '1' & PS2(6 downto 0);
				----press	
				when 27 =>           
					buff_in <= x"E0"; -- extended
					if (check_press (9) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 28 =>
					buff_in <= '0' & PS2(6 downto 0);  
				--===========================================
				--=========================================E4 Right Control
				----break
				when 29 =>
					buff_in <= x"E0"; -- extended /break
				   if (check_release (10) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 30 =>	
					buff_in <= x"F0"; -- break
					USB <= x"E4";
				when 31 =>
					buff_in <= '1' & PS2(6 downto 0);
				----press	
				when 32 =>           
					buff_in <= x"E0"; -- extended
					if (check_press (10) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 33 =>
					buff_in <= '0' & PS2(6 downto 0);
				--===========================================
				--=========================================E5
				----break
				when 34 =>
					buff_in <= x"F0"; -- break
				   if (check_release (11) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= x"E5";
				when 35 =>
					buff_in <= '1' & PS2(6 downto 0);
				----press
				when 36 =>           -- press
					buff_in <= '0' & PS2(6 downto 0);
					if (check_press (11) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				--===========================================
				--=========================================E6
				----break
				when 37 =>
					buff_in <= x"E0"; -- extended /break
				   if (check_release (12) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 38 =>	
					buff_in <= x"F0"; -- break
					USB <= x"E6";
				when 39 =>
					buff_in <= '1' & PS2(6 downto 0);
				----press	
				when 40 =>           
					buff_in <= x"E0"; -- extended
					if (check_press (12) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 41 =>
					buff_in <= '0' & PS2(6 downto 0);
				--===========================================
				--=========================================E7
				----break
				when 42 =>
					buff_in <= x"E0"; -- extended /break
				   if (check_release (13) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 43 =>	
					buff_in <= x"F0"; -- break
					USB <= x"E7";
				when 44 =>
					buff_in <= '1' & PS2(6 downto 0);
				----press	
				when 45 =>           
					buff_in <= x"E0"; -- extended
					if (check_press (13) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
				when 46 =>
					buff_in <= '0' & PS2(6 downto 0);		
				--==================================================================================
			   -- which keys was release --------------------
				------------N1	
				when 47 =>
					buff_in <= x"F0"; -- break
				   if (check_release (0) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= DB_LIN_BUFF(SW_2)(0);
				when 48 => 		
					buff_in <= '1' & PS2(6 downto 0);
				------------N2		
				when 49 =>
					buff_in <= x"F0"; -- break
				   if (check_release (1) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= DB_LIN_BUFF(SW_2)(1);
				when 50 =>
					buff_in <= '1' & PS2(6 downto 0);
				------------N3	
				when 51 =>
					buff_in <= x"F0"; -- break
				   if (check_release (2) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= DB_LIN_BUFF(SW_2)(2);
				when 52 =>  
					buff_in <= '1' & PS2(6 downto 0);
				------------N4
				when 53 =>
					buff_in <= x"F0"; -- break
				   if (check_release (3) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= DB_LIN_BUFF(SW_2)(3);
				when 54 =>  
					buff_in <= '1' & PS2(6 downto 0);
				------------N5	
				when 55 =>
					buff_in <= x"F0"; -- break
				   if (check_release (4) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= DB_LIN_BUFF(SW_2)(4);
				when 56 =>
					buff_in <= '1' & PS2(6 downto 0);
				------------N6
				when 57 =>
					buff_in <= x"F0"; -- break
				   if (check_release (5) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					USB <= DB_LIN_BUFF(SW_2)(5);	
				when 58 => 
					buff_in <= '1' & PS2(6 downto 0);
				--============================================
				--============================================
			   -- which keys was pressed --------------------
					USB <= DB_LIN_BUFF(SW_1)(0);
				when 59 =>  -------------------------
				   if (check_press (0) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					buff_in <= '0' & PS2(6 downto 0);
				----------
					USB <= DB_LIN_BUFF(SW_1)(1);
				when 60 =>
				   if (check_press (1) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					buff_in <= '0' & PS2(6 downto 0);
				----------
					USB <= DB_LIN_BUFF(SW_1)(2);
				when 61 =>  
				   if (check_press (2) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					buff_in <= '0' & PS2(6 downto 0);
				-----------
					USB <= DB_LIN_BUFF(SW_1)(3);
				when 62 =>  
				   if (check_press (3) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					buff_in <= '0' & PS2(6 downto 0);
				-----------
					USB <= DB_LIN_BUFF(SW_1)(4);
				when 63 =>
				   if (check_press (4) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					buff_in <= '0' & PS2(6 downto 0);
				-----------
					USB <= DB_LIN_BUFF(SW_1)(5);
				when 64 => 
					buff_in <= DB_LIN_BUFF(SW_1)(5);
					if (check_press (5) = '1') then
						WR_RX_BUFF  <= '1' ;  else WR_RX_BUFF  <= '0' ; 					
					end if;
					buff_in <= '0' & PS2(6 downto 0);
				--===============================================================================
				--===========================================
				when others =>
					WR_RX_BUFF  <= '0'   ; 
					buff_in <= x"00" ;	
			end case;
			--======================================================
			--------------------------------------------------------------------
			--==== RX =============================================
			--WR===================================================
			if WR_RX_BUFF = '1' then                 --- WRITE DATA
				RX_head_cnt <= RX_head_cnt + 1;
			end if;
			--RD===================================================
			if  rx_fifo_notempty = '1' then
				RD_r(0) <= SCANCODE_RD_n;               --- READ  DATA
			end if;	
			RD_r(1) <= RD_r(0);
			if RD_r = "10" then --__ SYNCRO--
				RX_tail_cnt <= RX_tail_cnt + 1;	
			end if;
			-------rx_fifo_not/empty-----------------
			if (RX_head_cnt = RX_tail_cnt) then
				rx_fifo_notempty <= '0'; -- EMPTY
				key_scancode <= X"00";  
			else
				rx_fifo_notempty <= '1'; -- NOT EMPTY
				key_scancode <= buff_out;
			end if;
			------
			if (RX_head_cnt = RX_tail_cnt - 1) or ((RX_head_cnt = X"FF") and  (RX_tail_cnt = X"00")) then
				rx_fifo_full 	<= '1'; -- TX FIFO - FULL
			else
				rx_fifo_full 	<= '0'; -- TX FIFO - not fill
			end if;		
			-----------------------------------------------	
		--===============================================================================================	
		end if;
	end process;
	
---------- USB to PS/2 Set2 TABLE       -----------------		
USB_PS2_TAB: entity work.USB_PS2
port map (
	USB			=> USB,        --<===INPUT
	PS2	 	   => PS2_Set2    -->===OUTPUT         
	);

-----------PS/2 Set2 to PS/2 Set1 TABLE -----------------


PS2Set2_to_PS2_Set1: ps2_keyb_xtcodes 
port map(
   at_code => PS2_Set2(6 downto 0), --<===INPUT
   xt_code => PS2(6 downto 0)       -->===OUTPUT PS2_Set1 
  );
	PS2(7) <= '0';   
  

RX_FIFO: entity work.RAM_256B
port map (
	clock			=> CLK, 
	data	 	   => buff_in,         --<===INPUT  
	wraddress	=> std_logic_vector(RX_head_cnt),
	rdaddress	=> std_logic_vector(RX_tail_cnt),
 	wren	 	   => WR_RX_BUFF,
	q	 		   => buff_out         --===>OUTPUT
	);

	
end architecture;
