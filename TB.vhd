LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TB IS
END TB;
 
ARCHITECTURE behavior OF TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT main_module
    PORT(
         nreset : IN  std_logic;
         board_clk : IN  std_logic;
         u : IN  std_logic;
         d : IN  std_logic;
         r : IN  std_logic;
         l : IN  std_logic;
         vsync : OUT  std_logic;
         hsync : OUT  std_logic;
         red : OUT  std_logic_vector(2 downto 0);
         green : OUT  std_logic_vector(2 downto 0);
         blue : OUT  std_logic_vector(1 downto 0);
         SSEG_CA : OUT  std_logic_vector(7 downto 0);
         SSEG_AN : OUT  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal nreset : std_logic := '0';
   signal board_clk : std_logic := '0';
	signal pixel_clk : std_logic := '0';
   signal u : std_logic := '0';
   signal d : std_logic := '0';
   signal r : std_logic := '0';
   signal l : std_logic := '0';

 	--Outputs
   signal vsync : std_logic;
   signal hsync : std_logic;
   signal red : std_logic_vector(2 downto 0);
   signal green : std_logic_vector(2 downto 0);
   signal blue : std_logic_vector(1 downto 0);
   signal SSEG_CA : std_logic_vector(7 downto 0);
   signal SSEG_AN : std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant board_clk_period : time := 10 ns;
	constant pixel_clk_period : time := 40 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: main_module PORT MAP (
          nreset => nreset,
          board_clk => board_clk,
          u => u,
          d => d,
          r => r,
          l => l,
          vsync => vsync,
          hsync => hsync,
          red => red,
          green => green,
          blue => blue,
          SSEG_CA => SSEG_CA,
          SSEG_AN => SSEG_AN
        );

   -- Clock process definitions
   board_clk_process :process
   begin
		board_clk <= '0';
		wait for board_clk_period/2;
		board_clk <= '1';
		wait for board_clk_period/2;
   end process;
	
	pixel_clk_process :process
   begin
		pixel_clk <= '0';
		wait for pixel_clk_period/2;
		pixel_clk <= '1';
		wait for pixel_clk_period/2;
   end process;
 
 

   -- Stimulus process
   stim_proc: process
   begin		
		nreset<='0' after 10ns,
				  '1' after 20ns,
				  '0' after 30ns;
      wait for 100 ns;	

      wait for board_clk_period*10;
		u<='0' after 10ns,
	   	'1' after 20ns,
		   '0' after 30ns;
		d<='0';  
		r<='0'; 
		l<='1'; wait for 50 ms;
		l<='0';
      wait;
   end process;
END;
