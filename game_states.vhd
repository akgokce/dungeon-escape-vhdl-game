LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY game_states IS
	PORT(	clk: IN std_logic;
			game_state: IN std_logic_vector (1 downto 0);
			frame_row, frame_column: IN std_logic_vector (9 downto 0);
			frame_pixel: OUT std_logic );
END game_states;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ARCHITECTURE behavioral OF game_states IS

	COMPONENT ROM_start --ROM for start screen
	  PORT (
		 clka : IN STD_LOGIC;
		 addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 douta : OUT STD_LOGIC_VECTOR(319 DOWNTO 0)
	  );
	END COMPONENT;
	
	COMPONENT ROM_win --ROM for win screen
	  PORT (
		 clka : IN STD_LOGIC;
		 addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 douta : OUT STD_LOGIC_VECTOR(319 DOWNTO 0)
	  );
	END COMPONENT;
	
	COMPONENT ROM_gameover --ROM for gameover screen
	  PORT (
		 clka : IN STD_LOGIC;
		 addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 douta : OUT STD_LOGIC_VECTOR(319 DOWNTO 0)
	  );
	END COMPONENT;
	
	FOR ALL: ROM_start USE ENTITY WORK.ROM_start(ROM_start_a);
	FOR ALL: ROM_win USE ENTITY WORK.ROM_win(ROM_win_a);
	FOR ALL: ROM_gameover USE ENTITY WORK.ROM_gameover(ROM_gameover_a);
	
	SIGNAL data_out_start, data_out_win, data_out_gameover: std_logic_vector (319 downto 0);
	SIGNAL address: std_logic_vector (7 downto 0);
	
	BEGIN
 		ROM1: ROM_start PORT MAP (clk, address, data_out_start);
		ROM2: ROM_win PORT MAP (clk, address, data_out_win);
		ROM3: ROM_gameover PORT MAP (clk, address, data_out_gameover);
		PROCESS(clk)
			BEGIN
				IF(frame_row<239 AND frame_column<319) THEN
					address<=frame_row(7 downto 0);
					IF(game_state=0) THEN
						frame_pixel <= data_out_start(319-conv_integer(frame_column));
					ELSIF(game_state=2) THEN
						frame_pixel <= data_out_win(319-conv_integer(frame_column));
					ELSIF(game_state=3) THEN
						frame_pixel <= data_out_gameover(319-conv_integer(frame_column));
					ELSE
						frame_pixel <= '0';
					END IF;
				ELSE
					frame_pixel <='0';
					address<="00000000";
				END IF;
				

					
		END PROCESS;
END behavioral;

