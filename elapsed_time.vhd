LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY elapsed_time IS
	PORT (
		board_clk: IN std_logic;
		rst: IN std_logic;
		enable: IN std_logic;
		time_out : OUT std_logic;
		SSEG_CA: OUT std_logic_vector(7 downto 0);
		SSEG_AN: OUT std_logic_vector(3 downto 0));
END elapsed_time;

--7 Segment Driver------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY nexys3_sseg_driver IS
    PORT( 
		MY_CLK 	: IN  STD_LOGIC;
		DIGIT0  : IN  std_logic_vector (7 downto 0);
		DIGIT1  : IN  std_logic_vector (7 downto 0);
		DIGIT2  : IN  std_logic_vector (7 downto 0);
		DIGIT3  : IN  std_logic_vector (7 downto 0);
		SSEG_CA : OUT std_logic_vector (7 downto 0);
		SSEG_AN : OUT std_logic_vector (3 downto 0)
	);
END nexys3_sseg_driver;

ARCHITECTURE Behavioral OF nexys3_sseg_driver IS

	SIGNAL refrclk	: std_logic := '0';
	SIGNAL ch_sel	: INTEGER RANGE 0 TO 3 := 0;
	SIGNAL counter	: INTEGER RANGE 0 TO 124999 := 0;

BEGIN

FREQ_DIV: PROCESS (MY_CLK) BEGIN
	IF rising_edge(MY_CLK) THEN
		IF (counter = 124999) THEN -- 400Hz Clock, each SSEG will be refreshed with a freq 100Hz 
			refrclk <= NOT refrclk;
			counter <= 0;
		ELSE
			counter <= counter + 1;
		END IF;
	END IF;
END PROCESS;
    
PROCESS(refrclk) BEGIN
	IF rising_edge(refrclk) THEN
		IF (ch_sel = 3) THEN
			ch_sel <= 0;
		ELSE
			ch_sel <= ch_sel + 1;
		END IF;
	END IF;
END PROCESS;
	
WITH ch_sel SELECT
	SSEG_AN <= 
		"0111" WHEN 0,
		"1011" WHEN 1,
		"1101" WHEN 2,
		"1110" WHEN 3;

WITH ch_sel SELECT
	SSEG_CA <= 
		DIGIT0 WHEN 0,
		DIGIT1 WHEN 1,
		DIGIT2 WHEN 2,
		DIGIT3 WHEN 3;

END Behavioral;



----BCD to 7 Segment Decoder------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


ENTITY BCD_to_seven_segment is
	PORT ( 
		d: IN std_logic_vector (3 downto 0);
		s: OUT std_logic_vector ( 7 downto 0)	);
END BCD_to_seven_segment;
ARCHITECTURE dataflow of BCD_to_seven_segment is
BEGIN
	WITH d SELECT
	s <="11000000" WHEN "0000",
	"11111001" WHEN "0001",
	"10100100" WHEN "0010",
	"10110000" WHEN "0011",
	"10011001" WHEN "0100",
	"10010010" WHEN "0101",
	"10000010" WHEN "0110",
	"11111000" WHEN "0111",
	"10000000" WHEN "1000",
	"10010000" WHEN "1001",
	"11111111" WHEN OTHERS;
END dataflow;



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


ARCHITECTURE behavioral OF elapsed_time IS
	
	COMPONENT bcdto7
		PORT ( 
		d: IN std_logic_vector (3 downto 0);
		s: OUT std_logic_vector ( 7 downto 0)	);
	END COMPONENT;
	
	COMPONENT driver7seg
		PORT( 
		MY_CLK  : IN  STD_LOGIC;
		DIGIT0  : IN  std_logic_vector (7 downto 0);
		DIGIT1  : IN  std_logic_vector (7 downto 0);
		DIGIT2  : IN  std_logic_vector (7 downto 0);
		DIGIT3  : IN  std_logic_vector (7 downto 0);
		SSEG_CA : OUT std_logic_vector (7 downto 0);
		SSEG_AN : OUT std_logic_vector (3 downto 0));
	END COMPONENT;

	FOR ALL: bcdto7 USE ENTITY WORK.BCD_to_seven_segment(dataflow);
	FOR ALL: driver7seg USE ENTITY WORK.nexys3_sseg_driver(behavioral);

	SIGNAL hdig, mdig, ldig: std_logic_vector (7 downto 0);
	SIGNAL hdigb, mdigb, ldigb: std_logic_vector (3 downto 0);
	
BEGIN

	
	B2: bcdto7 PORT MAP(hdigb, hdig);
	B1: bcdto7 PORT MAP(mdigb, mdig);
	B0: bcdto7 PORT MAP(ldigb, ldig);
	
	segdiv: driver7seg PORT MAP(board_clk, "11111111",  hdig, mdig, ldig, sseg_ca, sseg_an);
	
	PROCESS(board_clk, rst)
	
	VARIABLE count: INTEGER RANGE 0 TO 100000000;
	VARIABLE vhdigb, vmdigb, vldigb : std_logic_vector(3 downto 0);
	VARIABLE templ, tempm, time_out_var : std_logic;
		BEGIN
		IF(rst='1') THEN
			count:=0;
			templ:='0';
			tempm:='0';
			vhdigb:="0000";
			vmdigb:="0000";
			vldigb:="0000";
			time_out_var:='0';
		ELSIF(rising_edge(board_clk)) THEN
			IF(enable='1') THEN
				IF(count=100000000) THEN
					count:=0;
				ELSE
					count:=count+1;
				END IF;
			ELSE
				count:=count;
			END IF;
			
			IF(count=100000000) THEN
				IF(vldigb=9) THEN
					vldigb:="0000";
					templ:='1';
				ELSE
					vldigb:=vldigb+1;
					templ:='0';
				END IF;
			ELSE
				templ:='0';
			END IF;
			
			IF(templ='1') THEN
				IF(vmdigb=9) THEN
					vmdigb:="0000";
					tempm:='1';
				ELSE
					vmdigb:=vmdigb+1;
					tempm:='0';
				END IF;
			ELSE
				tempm:='0';
			END IF;
			
			IF(tempm='1') THEN
				IF(vhdigb=9) THEN
					vhdigb:="0000";
				ELSE
					vhdigb:=vhdigb+1;
				END IF;
			END IF;	
		END IF;
			
			IF(vhdigb=1 AND vmdigb=8 AND vldigb=0) THEN
				time_out_var:='1';
			ELSE
				time_out_var:=time_out_var;
			END IF;
			
			time_out<=time_out_var;

			hdigb<=vhdigb;
			mdigb<=vmdigb;
			ldigb<=vldigb;
		END PROCESS;

END behavioral;



