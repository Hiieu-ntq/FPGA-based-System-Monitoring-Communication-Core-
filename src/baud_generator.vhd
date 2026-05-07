library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen is
    generic (
        CLK_FREQ  : integer := 27000000;
        BAUD_RATE : integer := 115200
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        tick_1x   : out std_logic;
        tick_16x  : out std_logic
    );
end entity;

architecture rtl of baud_gen is
    constant DIV_16X : integer := CLK_FREQ / (BAUD_RATE * 16);
    signal cnt_16x   : integer range 0 to DIV_16X := 0;
    signal cnt_1x    : integer range 0 to 15 := 0;
begin

process(clk, rst_n)
begin
    if rst_n = '0' then
        cnt_16x  <= 0;
        cnt_1x   <= 0;
        tick_1x  <= '0';
        tick_16x <= '0';
    elsif rising_edge(clk) then
        tick_1x  <= '0';
        tick_16x <= '0';

        if cnt_16x = DIV_16X - 1 then
            cnt_16x  <= 0;
            tick_16x <= '1';
            
            if cnt_1x = 15 then
                cnt_1x <= 0;
                tick_1x <= '1';
            else
                cnt_1x <= cnt_1x + 1;
            end if;
        else
            cnt_16x <= cnt_16x + 1;
        end if;
    end if;
end process;

end architecture;
