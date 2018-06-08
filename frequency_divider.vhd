
-------------------------Frequency Divider--------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

--Frequency divider for main_module which generates 25MHZ clock.
ENTITY frequency_divider IS
	PORT(
			board_clk, rst: IN std_logic;
			pixel_clk: OUT std_logic
			);
END frequency_divider;

ARCHITECTURE pixel OF frequency_divider IS
	SIGNAL temp: std_logic_vector (1 downto 0);
	BEGIN
		PROCESS(board_clk, rst)
			BEGIN
				IF(rst='1') THEN
					temp<="00";
				ELSIF(board_clk'event AND board_clk='0') THEN
					temp<=temp + 1;	
				END IF;
				pixel_clk<=temp(1);
			END PROCESS;
END pixel;

