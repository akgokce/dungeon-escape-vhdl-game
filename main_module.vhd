LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY main_module IS
	PORT (
			nreset: in std_logic;
			board_clk: in std_logic;
			u,d,r,l: in std_logic;
			vsync: out std_logic;
			hsync: out std_logic;
			red: out std_logic_vector(2 downto 0);
			green: out std_logic_vector(2 downto 0);
			blue: out std_logic_vector(1 downto 0);
			SSEG_CA: OUT std_logic_vector(7 downto 0);
			SSEG_AN: OUT std_logic_vector(3 downto 0));
END;


ARCHITECTURE behavioral OF main_module IS
	
	
	COMPONENT frequency_divider
		PORT(
			board_clk, rst: IN std_logic;
			pixel_clk: OUT std_logic
			);
	END COMPONENT;
	
	COMPONENT debouncer 
		PORT(
			clk, rst, upc, downc, leftc, rightc : IN std_logic;
			o_upp, o_downp, o_leftp, o_rightp : OUT std_logic);
	END COMPONENT;
	
	COMPONENT elapsed_time 
		PORT (
			board_clk: IN std_logic;
			rst: IN std_logic;
			enable: IN std_logic;
			time_out: OUT std_logic;
			SSEG_CA: OUT std_logic_vector(7 downto 0);
			SSEG_AN: OUT std_logic_vector(3 downto 0));
	END COMPONENT;
	
	COMPONENT game_states 
		PORT(	clk: IN std_logic;
				game_state: IN std_logic_vector (1 downto 0);
				frame_row, frame_column: IN std_logic_vector (9 downto 0);
				frame_pixel: OUT std_logic );
	END COMPONENT;
	
	
	FOR ALL: frequency_divider USE ENTITY WORK.frequency_divider(pixel);
	FOR ALL: debouncer USE ENTITY WORK.debouncer(behavioral);
	FOR ALL: elapsed_time USE ENTITY WORK.elapsed_time(behavioral);
	FOR ALL: game_states USE ENTITY WORK.game_states(behavioral);
	
	
	SIGNAL du, dd, dl, dr, frame_pixel, timer_enable, time_out : std_logic;
	SIGNAL pixel_clk, h_display, end_of_line, v_display, end_of_frame : std_logic;
	SIGNAL h_count, v_count, frame_row, frame_column : std_logic_vector (9 downto 0);
	SIGNAL game_state : std_logic_vector (1 downto 0);
  
	TYPE array_type_16x16 IS ARRAY (0 to 15) OF std_logic_vector(15 downto 0); -- Array type for 16x16 pixel blocks
																										-- Each block represented below 
	CONSTANT wall : array_type_16x16:=
				(	"1111111111111111",
					"1001001001001001",
					"1000100100100101",
					"1010010010010011",
					"1001001001001001",
					"1100100100100101",
					"1010010010010011",
					"1001001001001001",
					"1100100100100101",
					"1010010010010011",
					"1001001001001001",
					"1100100100100101",
					"1010010010010011",
					"1001001001001001",
					"1100100100100101",
					"1111111111111111");
							
	CONSTANT player: 	array_type_16x16:=
				(	"0000000000000000",
					"0000011111100000",
					"0001111111111000",
					"0011111111111100",
					"0111111111111110",
					"1111111111111110",
					"1111111111100000",
					"1111111000000000",
					"1111111000000000",
					"1111111111100000",
					"1111111111111110",
					"0111111111111110",
					"0011111111111100",
					"0001111111111000",
					"0000011111100000",
					"0000000000000000");
					
	CONSTANT monster: array_type_16x16:=
				( 	"0000000000000000",
					"0000111111110000",
					"0111111111111110",
					"1111111111111111",
					"1111111111111111",
					"1111000111100011",
					"1111000111100011",
					"1111111111111111",
					"1111111111111111",
					"1111111111111111",
					"1111111111111111",
					"1111111111111111",
					"1111111111111111",
					"1111111111111111",
					"1101111001111011",
					"1000110000110001");
				
	CONSTANT obstacle: array_type_16x16:=
				( 	"0000000110000000",
					"0000001111000000",
					"0000001111000000",
					"0000011111100000",
					"0000011111100000",
					"0001111111111000",
					"0111110000111110",
					"1111100000011111",
					"1111100000001111",
					"0111110000111110",
					"0001111111111000",
					"0000011111100000",
					"0000011111100000",
					"0000001111000000",
					"0000001111000000",
					"0000000110000000");
				
	CONSTANT key: array_type_16x16:=
				( 	"0000001111000000",
					"0000011111100000",
					"0000111001110000",
					"0001100000011000",
					"0001110000111000",
					"0000111001110000",
					"0000011111100000",
					"0000001111000000",
					"0000001001000000",
					"0000111001000000",
					"0000111001000000",
					"0000001001000000",
					"0000001001000000",
					"0001111001000000",
					"0001000001000000",
					"0001111111000000");
				
	CONSTANT background : array_type_16x16:=
				( 	"1000100010000100",
					"0100010000010000",
					"1110000001001100",
					"0010011000000000",
					"0011100100000110",
					"0011100000000010",
					"0000000010000000",
					"0000100010001100",
					"0110000001000000",
					"0001000010010000",
					"0000111000001000",
					"0000010000000000",
					"0000000000011100",
					"0000100000001100",
					"0001110000010000",
					"0000100011100000");
	
	--TYPE array_type_30x120 IS ARRAY (29 downto 0) OF std_logic_vector (119 downto 0);
	TYPE array_type_30x120 IS ARRAY (0 to 29, 0 to 119) OF std_logic; --Array type for main controlling array which keeps the track of each block's state.
	SIGNAL mapcontrol : array_type_30x120;
	
	BEGIN
		
		F: frequency_divider PORT MAP(board_clk, nreset, pixel_clk);
		
		D0: debouncer PORT MAP(pixel_clk, nreset, u, d, l, r, du, dd, dl, dr); 
		
		T: elapsed_time PORT MAP(board_clk, nreset, timer_enable, time_out, SSEG_CA, SSEG_AN);
		
		G: game_states PORT MAP (board_clk, game_state, frame_row, frame_column, frame_pixel);
		
		frame_row<=v_count - 151;
		frame_column<=h_count - 304;
	
		
		HsyncGen : PROCESS(pixel_clk,nreset) -- Horizontal Synchronous Signal Generator
			VARIABLE h_display_var, end_of_line_var: std_logic;
			VARIABLE h_count_var :std_logic_vector (9 downto 0);
			BEGIN
				IF(nreset='1') THEN
					hsync<='0';
					h_count_var:="0000000000";
					h_display_var:='0';
					end_of_line_var:='0';
				ELSIF(rising_edge(pixel_clk)) THEN
					h_count_var:=h_count_var + 1;
					IF(h_count_var=800) THEN
						hsync<='0';
						h_count_var:="0000000000";
						h_display_var:='0';
						end_of_line_var:='0';
					ELSIF(h_count_var<96) THEN
						hsync<='0';
						h_display_var:='0';
						end_of_line_var:='0';
					ELSIF(h_count_var<144) THEN
						hsync<='1';
						h_display_var:='0';
						end_of_line_var:='0';
					ELSIF(h_count_var<784) THEN
						hsync<='1';
						h_display_var:='1';
						end_of_line_var:='0';
					ELSIF(h_count_var=799) THEN
						hsync<='1';
						h_display_var:='0';
						end_of_line_var:='1';
					ELSE
						hsync<='1';
						h_display_var:='0';
						end_of_line_var:='0';
					END IF;
				END IF;
				end_of_line<=end_of_line_var;
				h_display<=h_display_var;
				h_count<=h_count_var;
		END PROCESS;
		
		VsyncGen : PROCESS(pixel_clk,nreset) -- Vertical Synchronous Signal Generator
			VARIABLE v_display_var, end_of_frame_var: std_logic;
			VARIABLE v_count_var:std_logic_vector (9 downto 0);
			BEGIN
				IF(nreset='1') THEN
					vsync<='0';
					v_count_var:="0000000000";
					v_display_var:='0';
					end_of_frame_var:='0';
				ELSIF(rising_edge(pixel_clk)) THEN
					IF(end_of_line='1') THEN
						v_count_var:=v_count_var + 1;
					ELSE
						v_count_var:=v_count_var;
					END IF;
					IF(v_count_var=521) THEN
						vsync<='0';
						v_count_var:="0000000000";
						v_display_var:='0';
						end_of_frame_var:='1';
					ELSIF(v_count_var<2) THEN
						vsync<='0';
						v_display_var:='0';
						end_of_frame_var:='0';
					ELSIF(v_count_var<31) THEN
						vsync<='1';
						v_display_var:='0';
						end_of_frame_var:='0';
					ELSIF(v_count_var<511) THEN
						vsync<='1';
						v_display_var:='1';
						end_of_frame_var:='0';
					ELSE
						vsync<='1';
						v_display_var:='0';
						end_of_frame_var:='0';
					END IF;
				END IF;
				v_display<=v_display_var;
				v_count<=v_count_var;
				end_of_frame<=end_of_frame_var;
		END PROCESS;
		

		FrameGen :  PROCESS(pixel_clk,nreset) --Main process of the module that generates frame and control object position
			VARIABLE control_r_vec, control_c_vec : std_logic_vector (9 downto 0);
			VARIABLE control_r, control_c : INTEGER RANGE 0 TO 40;
			VARIABLE image_r, background_r: std_logic_vector (0 to 15);
			VARIABLE grid_r, grid_c : INTEGER RANGE 0 TO 15;
			VARIABLE player_rpos, player_rpos_n : INTEGER RANGE 1 TO 30;
			VARIABLE player_cpos, player_cpos_n : INTEGER RANGE 1 TO 40;
			VARIABLE monster_pos, monster_pos_n : INTEGER RANGE 0 TO 3;
			VARIABLE monster_counter : INTEGER RANGE 0 TO 45;
			VARIABLE monster_direction : INTEGER RANGE -1 TO 1;
			
			BEGIN
				IF(nreset='1') THEN
				--State codes of the blocks as follows:
				--	wall : 			000
				--	player  : 		001
				-- obstacle  : 	010
				--	backgrround : 	100
				--	monster  : 		110
				-- key  : 			111
				mapcontrol <=(
--    0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39
--    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |	
	"100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100",  -- 0
	"100001000000000000000010100000000100000100000100000000000000010010000000100100000000000000000000010100010010010010010100",  -- 1
	"100000100100100100000010100000000100100000100000000000100000000000100000100100000100000000100000000000000000000000010100",  -- 2
	"100000100000000000000010100000000100010100000000100100000000100000000100010100000010100000010100000100010000000000010100",  -- 3
	"100000100000000000000010100000000100000000100000000100010100000000000000000100000100000000100000000100010000000000010100",  -- 4
	"100000100000100100100100100000000100000100000100000100100000000000100000000100100010000100000000010100010110000000010100",  -- 5
	"100000000000000000000000000000000100000000000000000100000000100100000100000100100100000000100000000100010000000000010100",  -- 6
	"100010010010010010010010010000000100100010000000100000000100000000000000000100100010100000010100000100010000000110010100",  -- 7
	"100100100100100100100100100000000100000000000100000000100000000100100000010100100100000000100000000100010000000000010100",  -- 8
	"100000000000000000000000000000000100000000100000100000100100000000000100100100100000000100000000100100010110000000010100",  -- 9
	"100000000010100100100100100100100100100000000100000000000100100010000000100100010000100010000010100100010000000000010100",  -- 10
	"100000000000010100100100100100100100000000000000000100000100000100000100000100100000000100000000100100010000000000010100",  -- 11
	"100010010000000010100100100100100100100000100100100000000100000000000000100100000100000000100000000100010000111000010100",  -- 12
	"100100100010000000010100100100100100000000000000000000100100100100100000000100000010100000010100000100010010010010010100",  -- 13
	"100100100100010000000010100100100100000100000100010000000000000000000100000000000100000000100010000100100100100100100100",  -- 14
	"100100100100100010000000010100100100000000100010100100100100010100000100000000000000000010100010000000000000000000000100",  -- 15
	"100100100100100100010000000010100100100000000000000000100100100000000100000100100100100100100100100100100100100100000100",  -- 16
	"100100100100100100100010000000010100010000100100000000100100000000000100000100010010010010010010010010010010010010000100",  -- 17
	"100100100100100100100100010000010100010000100000000100000000000100000100000100010000000000000000000000000000000000000100",  -- 18
	"100000000000000000000000000000000100100000000000100010100000100000000100000100000000010010010010010010010010010010010100",  -- 19
	"100000100100100100100100100100100100000100000100000000000100000000100000000100000100100100100100100100100100100100100100",  -- 20
	"100000100100100100100100100100100100100000000000000100000100100000000000010100000100000000000100000000000100000000000100",  -- 21
	"100000100100100100100100100100100100000000100000100000000000000100000000100100000100000010000100000010000100000010000100",  -- 22
	"100000100100100100100100100100100100000100000000100100000000100000100000000100000100000100000100000100000100000100000100",  -- 23
	"100000000000000100100100100100100100000000100100100000000010100000000000000100000100000100000100000100000100000100000100",  -- 24
	"100010010000000010010010010010010010000000100000000000000100000000100000000100000100000100000100000100000100000100000100",  -- 25
	"100100100010000000000000000000000000000000100100000100010000100000000000100100000100000100000100000100000100000100000100",  -- 26
	"100100100010000010010010010010010010000000100000000000100000000000100000000100000010000100000010000100000010000100000100",  -- 27
	"100010010000000100100100100100100100100100100000100000000000100000000100000100000000000100000000000100000000000100000100",  -- 28
	"100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100"); -- 29
--    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
--    0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39
					game_state<="00";
					player_rpos:=1;
					player_cpos:=1;
					player_rpos_n:=1;
					player_cpos_n:=1;
					monster_pos:=0;
					monster_counter:=0;
					monster_direction:=-1;
					red<="000";
					green<="000";
					blue<="00";
					
				ELSIF(rising_edge(pixel_clk)) THEN
					IF(game_state=0) THEN   --Start screen state (00)
						timer_enable<='0';
	
						IF(du='1' OR dd='1' OR dr='1' OR dl='1') THEN
							game_state<="01";
						ELSE
							game_state<=game_state;
						END IF;
						
						IF(v_display='1' AND h_display='1') THEN
							IF(h_count>=304 AND h_count<624 AND v_count>=151 AND v_count<391) THEN
								IF (frame_pixel='1') THEN
									red<="111";
									green<="111";
									blue<="11";
								ELSE
									red<="000";
									green<="000";
									blue<="00";
								END IF;
							ELSE
								red<="000";
								green<="000";
								blue<="00";
							END IF;
						ELSE
							red<="000";
							green<="000";
							blue<="00";
						END IF;
								
					ELSIF (game_state=1) THEN   --Actual gameplay state (01)
					--Updates the position of the player if any button data is present.
					
						timer_enable<='1';
						
						IF(time_out='1') THEN --If the time exceeds 180 seconds, game is over.
							game_state<="11";
						ELSE
							game_state<=game_state;
						END IF;
						
						IF(du='1') THEN
							player_rpos_n:=player_rpos-1;
						ELSIF(dd='1') THEN
							player_rpos_n:=player_rpos+1;
						ELSIF(dr='1') THEN
							player_cpos_n:=player_cpos-1;
						ELSIF(dl='1') THEN
							player_cpos_n:=player_cpos+1;
						ELSE
							player_rpos_n:=player_rpos;
							player_cpos_n:=player_cpos;
						END IF;
					
					
						IF(mapcontrol((player_rpos_n), (player_cpos_n)*3 + 0) = '1' AND
							mapcontrol((player_rpos_n), (player_cpos_n)*3 + 1) = '0' AND
							mapcontrol((player_rpos_n), (player_cpos_n)*3 + 2) = '0') THEN
							--If the new position of the player is already a wall, reverse back its position to its previous state.
							
							player_rpos_n:=player_rpos;
							player_cpos_n:=player_cpos;
							
							
						ELSIF(mapcontrol((player_rpos_n), (player_cpos_n)*3 + 1) = '1' AND
								mapcontrol((player_rpos_n), (player_cpos_n)*3 + 2) = '0') THEN
								--If the player hits a monster of obstacle (110 or 010), game over.
							
								game_state<="11";
							
						ELSIF(mapcontrol((player_rpos_n), (player_cpos_n)*3 + 0) = '1' AND
								mapcontrol((player_rpos_n), (player_cpos_n)*3 + 1) = '1' AND
								mapcontrol((player_rpos_n), (player_cpos_n)*3 + 2) = '1') THEN
								--If the player acquiers the key, exit door will be placed.
								
							mapcontrol(28,39*3 + 0) <= '0'; -- Placing the door 
							mapcontrol(28,39*3 + 1) <= '0';		
							mapcontrol(28,39*3 + 2) <= '0';
							
						ELSIF(player_rpos_n=28 AND player_cpos_n=39) THEN 
								--If the player reaches the exit, game is won.
					
							game_state<="10";
							
						END IF;
						

						--If the new position of the player is background, update the sates, replace previous its previous state with the background.
						mapcontrol((player_rpos), (player_cpos)*3 + 0)<= '0';
						mapcontrol((player_rpos), (player_cpos)*3 + 1)<= '0';
						mapcontrol((player_rpos), (player_cpos)*3 + 2)<= '0';
						mapcontrol((player_rpos_n), (player_cpos_n)*3 + 0)<= '0';
						mapcontrol((player_rpos_n), (player_cpos_n)*3 + 1)<= '0';
						mapcontrol((player_rpos_n), (player_cpos_n)*3 + 2)<= '1';
				
						
						player_rpos:=player_rpos_n;
						player_cpos:=player_cpos_n;
						
		
						
						IF(end_of_frame='1') THEN  --At the and of each frame, move monster unless it is ahead of an obstacle.
							monster_counter:= monster_counter +1;
							IF(monster_counter=45) THEN
								monster_counter:=0;
								monster_pos_n:=monster_pos + monster_direction;
								IF(mapcontrol(5, (35+monster_pos_n)*3 + 0) = '0' AND
									mapcontrol(5, (35+monster_pos_n)*3 + 1) = '1' AND
									mapcontrol(5, (35+monster_pos_n)*3 + 2) = '0') THEN
									
									monster_direction:= 0 - monster_direction;  -- If an obstacle encounterd, change the direction of movement.
									monster_pos_n:=monster_pos;
									
								ELSE
									monster_direction:= monster_direction;
								END IF;
							ELSE
								monster_counter:= monster_counter;
							END IF;
						ELSE
							monster_counter:=monster_counter;
						END IF;

						--Execute the movement of the monster.
						mapcontrol(5,(35+monster_pos)*3 + 0) <= '0';
						mapcontrol(5,(35+monster_pos)*3 + 1) <= '0';
						mapcontrol(5,(35+monster_pos)*3 + 2) <= '0';
						mapcontrol(5,(35+monster_pos_n)*3 + 0) <= '1';
						mapcontrol(5,(35+monster_pos_n)*3 + 1) <= '1';		
						mapcontrol(5,(35+monster_pos_n)*3 + 2) <= '0';						
						
						mapcontrol(7,(37-monster_pos)*3 + 0) <= '0';
						mapcontrol(7,(37-monster_pos)*3 + 1) <= '0';
						mapcontrol(7,(37-monster_pos)*3 + 2) <= '0';
						mapcontrol(7,(37-monster_pos_n)*3 + 0) <= '1';
						mapcontrol(7,(37-monster_pos_n)*3 + 1) <= '1';		
						mapcontrol(7,(37-monster_pos_n)*3 + 2) <= '0';
						
						mapcontrol(9,(35+monster_pos)*3 + 0) <= '0';
						mapcontrol(9,(35+monster_pos)*3 + 1) <= '0';
						mapcontrol(9,(35+monster_pos)*3 + 2) <= '0';
						mapcontrol(9,(35+monster_pos_n)*3 + 0) <= '1';
						mapcontrol(9,(35+monster_pos_n)*3 + 1) <= '1';		
						mapcontrol(9,(35+monster_pos_n)*3 + 2) <= '0';
						
						monster_pos:=monster_pos_n;
						
						control_c_vec := (h_count - 144); --Instead of using seperate counter for control_c and grid_c, use h_count signal generated by HSYNC Genetrator
						grid_c    := conv_integer(control_c_vec(3 downto 0)); --Count inside the grid 0 to 15
						control_c_vec := '0'&'0'&'0'&'0'&control_c_vec(9 downto 4); --Divide by 16 to count grid by grid
						control_c := conv_integer(control_c_vec);
						
						control_r_vec := (v_count - 31); --Instead of using seperate counter for control_r and grid_r, use h_count signal generated by VSYNC Genetrator
						grid_r    := conv_integer(control_r_vec(3 downto 0)); --Count inside the grid 0 to 15
						control_r_vec := '0'&'0'&'0'&'0'&control_r_vec(9 downto 4); --Divide by 16 to count grid by grid
						control_r := conv_integer(control_r_vec);
						
						IF(v_display='1' AND h_display='1') THEN
							IF(control_r<=29 AND control_c<=39) THEN 	--Check each state of the block and generate respective color output.
																					--If contol variables exceeds the index, generate no color output.
							
								background_r:=background(grid_r);
								
								--Wall state: 100
								IF(mapcontrol(control_r,control_c*3 + 0) = '1' AND
									mapcontrol(control_r,control_c*3 + 1) = '0' AND
									mapcontrol(control_r,control_c*3 + 2) = '0') THEN
									image_r:=wall(grid_r);
									IF (image_r(grid_c) = '1') THEN
										red<="011";
										green<="001";
										blue<="10";
									ELSE
										red<="000";
										green<="000";
										blue<="00";
									END IF;
									
								--Player state: 001
								ELSIF(mapcontrol(control_r,control_c*3 + 0) = '0' AND
										mapcontrol(control_r,control_c*3 + 1) = '0' AND
										mapcontrol(control_r,control_c*3 + 2) = '1') THEN
									image_r:=player(grid_r);
									IF (image_r(grid_c) = '1') THEN
										red<="111";
										green<="110";
										blue<="00";
									ELSIF (background_r(grid_c) = '1') THEN
										red<="001";
										green<="001";
										blue<="01";
									ELSE
										red<="001";
										green<="011";
										blue<="01";
									END IF;
								
								--Obstacle state: 010
								ELSIF(mapcontrol(control_r,control_c*3 + 0) = '0' AND
										mapcontrol(control_r,control_c*3 + 1) = '1' AND
										mapcontrol(control_r,control_c*3 + 2) = '0') THEN
									image_r:=obstacle(grid_r);
									IF (image_r(grid_c) = '1') THEN
										red<="101";
										green<="101";
										blue<="10";
									ELSIF (background_r(grid_c) = '1') THEN
										red<="001";
										green<="001";
										blue<="01";
									ELSE
										red<="001";
										green<="011";
										blue<="01";
									END IF;
									
								
								--Monster state: 110
								ELSIF(mapcontrol(control_r,control_c*3 + 0) = '1' AND
										mapcontrol(control_r,control_c*3 + 1) = '1' AND
										mapcontrol(control_r,control_c*3 + 2) = '0') THEN
									image_r:=monster(grid_r);
									IF (image_r(grid_c) = '1') THEN
										red<="010";
										green<="111";
										blue<="01";
									ELSIF (background_r(grid_c) = '1') THEN
										red<="001";
										green<="001";
										blue<="01";
									ELSE
										red<="001";
										green<="011";
										blue<="01";
									END IF;
									
									--Key state: 111
								ELSIF(mapcontrol(control_r,control_c*3 + 0) = '1' AND
										mapcontrol(control_r,control_c*3 + 1) = '1' AND
										mapcontrol(control_r,control_c*3 + 2) = '1') THEN
									image_r:=key(grid_r);
									IF (image_r(grid_c) = '1') THEN
										red<="111";
										green<="111";
										blue<="00";
									ELSIF (background_r(grid_c) = '1') THEN
										red<="001";
										green<="001";
										blue<="01";
									ELSE
										red<="001";
										green<="011";
										blue<="01";
									END IF;
								
									--Background state: 000
								ELSIF(mapcontrol(control_r,control_c*3 + 0) = '0' AND
										mapcontrol(control_r,control_c*3 + 1) = '0' AND
										mapcontrol(control_r,control_c*3 + 2) = '0') THEN
									IF (background_r(grid_c) = '1') THEN
										red<="001";
										green<="001";
										blue<="01";
									ELSE
										red<="001";
										green<="011";
										blue<="01";
									END IF;
								ELSE
									red<="000";
									green<="000";
									blue<="00";
								END IF;
							ELSE
								red<="000";
								green<="000";
								blue<="00";
							END IF;
						ELSE
							red<="000";
							green<="000";
							blue<="00";
						END IF;
					ELSIF(game_state=2) THEN  -- Game is won state (10)
						timer_enable<='0';
						IF(v_display='1' AND h_display='1') THEN
							IF(h_count>=304 AND h_count<624 AND v_count>=151 AND v_count<391) THEN
								IF (frame_pixel='1') THEN
									red<="111";
									green<="111";
									blue<="11";
								ELSE
									red<="000";
									green<="000";
									blue<="00";
								END IF;
							ELSE
								red<="000";
								green<="000";
								blue<="00";
							END IF;
						ELSE
							red<="000";
							green<="000";
							blue<="00";
						END IF;
							
					ELSE -- Game over state (11)
						timer_enable<='0';
						IF(v_display='1' AND h_display='1') THEN
							IF(h_count>=304 AND h_count<624 AND v_count>=151 AND v_count<391) THEN
								IF (frame_pixel='1') THEN
									red<="111";
									green<="111";
									blue<="11";
								ELSE
									red<="000";
									green<="000";
									blue<="00";
								END IF;
							ELSE
								red<="000";
								green<="000";
								blue<="00";
							END IF;
						ELSE
							red<="000";
							green<="000";
							blue<="00";
						END IF;
					END IF;
				END IF;
				
			END PROCESS;
END behavioral;
