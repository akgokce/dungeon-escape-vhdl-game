-----------------------DEBOUNCER------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
ENTITY debouncer IS
	PORT(
		clk, rst, upc, downc, leftc, rightc : IN std_logic;
		o_upp, o_downp, o_leftp, o_rightp : OUT std_logic);
END debouncer;


ARCHITECTURE behavioral OF debouncer IS
	
	BEGIN
		 
		
		debouncingu : PROCESS(clk,rst)
			VARIABLE temp : INTEGER RANGE 0 TO 2000000;
			BEGIN
				IF(rst ='1')	THEN
					temp:=0;
					o_upp<='0';
				ELSIF(rising_edge(clk)) THEN
					o_upp<='0';
					IF(upc='1') THEN
						IF(temp = 2000000) THEN
							temp:=0;
							o_upp<='1';
						ELSE
							temp:= temp + 1;
						END IF;
					ELSE
						temp:=0;
						o_upp<='0';
					END IF;
				END IF;
			END PROCESS;
			
		debouncingd : PROCESS(clk,rst)
			VARIABLE temp : INTEGER RANGE 0 TO 2000000;
			BEGIN
				IF(rst ='1')	THEN
					temp:=0;
					o_downp<='0';
				ELSIF(rising_edge(clk)) THEN
					o_downp<='0';
					IF(downc='1') THEN
						IF(temp = 2000000) THEN
							temp:=0;
							o_downp<='1';
						ELSE
							temp:= temp + 1;
						END IF;
					ELSE
						temp:=0;
						o_downp<='0';
					END IF;
				END IF;
			END PROCESS;
			
		debouncingl : PROCESS(clk,rst)
			VARIABLE temp : INTEGER RANGE 0 TO 2000000;
			BEGIN
				IF(rst ='1')	THEN
					temp:=0;
					o_leftp<='0';
				ELSIF(rising_edge(clk)) THEN
					o_leftp<='0';
					IF(leftc='1') THEN
						IF(temp = 2000000) THEN
							temp:=0;
							o_leftp<='1';
						ELSE
							temp:= temp + 1;
						END IF;
					ELSE
						temp:=0;
						o_leftp<='0';
					END IF;
				END IF;
			END PROCESS;
			
		debouncingr : PROCESS(clk,rst)
			VARIABLE temp : INTEGER RANGE 0 TO 2000000;
			BEGIN
				IF(rst ='1')	THEN
					temp:=0;
					o_rightp<='0';
				ELSIF(rising_edge(clk)) THEN
					o_rightp<='0';
					IF(rightc='1') THEN
						IF(temp = 2000000) THEN
							temp:=0;
							o_rightp<='1';
						ELSE
							temp:= temp + 1;
						END IF;
					ELSE
						temp:=0;
						o_rightp<='0';
					END IF;
				END IF;
			END PROCESS;
	

END behavioral;