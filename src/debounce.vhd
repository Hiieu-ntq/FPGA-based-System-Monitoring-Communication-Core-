library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        DB_LIMIT : integer := 540000 
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        btn_in    : in  std_logic;
        btn_clean : out std_logic
    );
end entity;

architecture rtl of debounce is
    signal cnt   : integer range 0 to DB_LIMIT := 0;
    signal prev  : std_logic := '1';
    signal clean : std_logic := '1';
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= 0;
            clean <= '1';
            prev <= '1';
        elsif rising_edge(clk) then
            if btn_in /= prev then
                cnt <= 0;
            elsif cnt < DB_LIMIT then
                cnt <= cnt + 1;
            else
                clean <= prev;
            end if;
            prev <= btn_in;
        end if;
    end process;
    btn_clean <= clean;
end architecture;
