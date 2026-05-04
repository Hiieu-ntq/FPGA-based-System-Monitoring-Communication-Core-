library ieee;
use ieee.std_logic_1164.all;

entity power_on_reset is
    generic (
        WAIT_CYCLES : integer := 255
    );
    port (
        clk   : in  std_logic;
        rst_n : out std_logic
    );
end entity;

architecture rtl of power_on_reset is
    signal por_cnt : integer range 0 to WAIT_CYCLES := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if por_cnt < WAIT_CYCLES then
                por_cnt <= por_cnt + 1;
                rst_n <= '0';  
            else
                rst_n <= '1';  
            end if;
        end if;
    end process;
end architecture;
