LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY GCD IS 
    GENERIC ( DATA_WIDTH : integer := 32 );
    PORT (
        clk     : in  std_logic;
        rst     : in  std_logic;  
        start   : in  std_logic; 
        x_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        y_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        gcd_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        done_o  : out std_logic
    );
END GCD;

ARCHITECTURE Structural OF GCD IS
    -- Tín hiệu kết nối giữa Controller và Datapath
    signal sig_x_sel, sig_y_sel : std_logic;
    signal sig_x_ld, sig_y_ld   : std_logic;
    signal sig_gcd_ld           : std_logic;
    signal sig_x_neq_y, sig_x_lt_y : std_logic;
BEGIN


    Control_Unit : entity work.Controller
        port map (
            RST     => rst,
            CLK     => clk,
            Start   => start,
            X_sel   => sig_x_sel,
            Y_sel   => sig_y_sel,
            X_ld    => sig_x_ld,
            Y_ld    => sig_y_ld,
            GCD_ld  => sig_gcd_ld,
            X_neq_Y => sig_x_neq_y,
            X_lt_Y  => sig_x_lt_y,
            Done_o  => done_o
        );

  
    Data_Unit : entity work.Datapath
        generic map ( DATA_WIDTH => DATA_WIDTH )
        port map (
            RST     => rst,
            CLK     => clk,
            X_sel   => sig_x_sel,
            Y_sel   => sig_y_sel,
            X_ld    => sig_x_ld,
            Y_ld    => sig_y_ld,
            X_in    => x_in,
            Y_in    => y_in,
            X_neq_Y => sig_x_neq_y,
            X_lt_Y  => sig_x_lt_y,
            GCD_ld  => sig_gcd_ld,
            GCD_o   => gcd_o
        );

END Structural;
