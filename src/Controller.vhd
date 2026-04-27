

LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY Controller IS 
	PORT	(
		RST, CLK : IN STD_LOGIC;
		Start :IN STD_LOGIC;
		X_sel,Y_sel : OUT STD_LOGIC;
		X_ld,Y_ld : OUT STD_lOGIC;
		GCD_ld : OUT STD_LOGIC;
		X_neq_Y,X_lt_Y : IN STD_LOGIC;
		Done_o : OUT STD_LOGIC
		);
END Controller;

ARCHITECTURE RTL OF Controller IS

	Type State_type IS (S0,S1,S2,S3,S4,S5,S6,S7,S9,S10,S11,S12);
	Signal state : State_type;  
BEGIN 
-- FSM --
	PROCESS (RST,CLK)
		BEGIN 
		IF(RST = '1') THEN 
		state <= S0 ;
		ELSIF rising_edge(CLK) THEN 
CASE state IS
    WHEN S0 => 
            state <= S1;
    WHEN S1 => 
        IF(Start = '1') THEN 
            state <= S2;
        ELSE 
            state <= S1;
        END IF;
    WHEN S2 => 
            state <= S3;
    WHEN S3 => 
            state <= S4;
    WHEN S4 => 
        IF(X_neq_Y = '1') THEN
            state <= S5;
        ELSE 
            state <= S9;
        END IF;
    WHEN S5 => 
        IF (X_lt_Y = '1') THEN
            state <= S6;
        ELSE 
            state <= S7;
        END IF;
    WHEN S6 => 
            state <= S4;
    WHEN S7 => 
            state <= S4;
    WHEN S9 => 
            state <= S10;
    WHEN S10 =>
            state <= S11;
    WHEN S11 =>
        IF Start = '0' THEN 
            state <= S12;
        ELSE 
            state <= S11;
        END IF;
    WHEN S12 => 
            state <= S0;
    WHEN OTHERS => 
            state <= S0;
END CASE;
	END IF;
	END PROCESS;

--Combinational logic-- 
X_sel <= '1' WHEN state = S2 ELSE '0' ;
X_ld <= '1' WHEN state = S2 ELSE '0';
Y_sel <= '1' WHEN state = S3 ELSE '0' ;
Y_ld <= '1' WHEN state = S3 ELSE '0';
GCD_ld <= '1' WHEN state = S9 ELSE '0';
Done_o <= '1' WHEN state = S11 ELSE '0';

 END RTL;