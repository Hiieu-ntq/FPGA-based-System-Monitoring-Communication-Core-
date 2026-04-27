

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY Datapath IS 
	GENERIC ( DATA_WIDTH :Integer := 16 );
	PORT	(
		RST, CLK : IN STD_LOGIC;
		X_sel,Y_sel : IN STD_LOGIC;
		X_ld, Y_ld : IN STD_LOGIC;
		X_in,Y_in : IN STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
		X_neq_Y,X_lt_Y : OUT STD_LOGIC;
		GCD_ld : IN STD_LOGIC;
		GCD_o : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
		);
END Datapath;

ARCHITECTURE RTL OF Datapath IS
SIGNAL X_src, XsubY,Y_src,YsubX,X,Y :STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
 BEGIN
	-- Multiplexer for X -- 
	X_src <= X_in WHEN X_sel = '1' ELSE XsubY;

	-- Multiplexer for Y --
	Y_src <= Y_in WHEN Y_sel = '1' ELSE YsubX;

	-- Comparator X not equal Y or not ?--
	X_neq_Y <= '1' WHEN X /= Y ELSE '0';

	-- Comparator X lessthan Y or not -- 
	X_lt_Y <= '1' WHEN X < Y ELSE '0';

	-- X_sub_Y--
	XsubY <= X - Y ;

	-- Y_sub_X--
	YsubX <= Y - X ;

	-- Regn_X --
	Reg_X :entity work.Regn 
		GENERIC MAP ( DATA_WIDTH => DATA_WIDTH)
	PORT MAP(
		RST => RST,
		CLK => CLK,
		En => X_ld,
		D => X_src,
		Q => X
		
		);

	-- Regn_Y -- 
	Reg_Y : entity work.Regn 
		GENERIC MAP ( DATA_WIDTH => DATA_WIDTH)
	PORT MAP(
		RST => RST,
		CLK => CLK,
		En => Y_ld,
		D => Y_src,
		Q => Y
	
		);
	-- Regn_GCD_o -- 
	Reg_GCD : entity work.Regn 
		GENERIC MAP ( DATA_WIDTH => DATA_WIDTH)
	PORT MAP(
		RST => RST,
		CLK => CLK,
		En => GCD_ld,
		D => X,
		Q => GCD_o
	
		);

 END RTL;