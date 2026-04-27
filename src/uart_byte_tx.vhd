library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_byte_tx is
    port (
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        tick_1x    : in  std_logic;
        data_byte  : in  std_logic_vector(7 downto 0);
        send_en    : in  std_logic;
        uart_tx    : out std_logic;
        tx_done    : out std_logic;
        tx_busy    : out std_logic
    );
end entity;

architecture rtl of uart_byte_tx is
    signal bit_cnt    : integer range 0 to 10 := 0; 
    signal busy       : std_logic := '0';
    signal data_reg   : std_logic_vector(7 downto 0);
    signal send_d     : std_logic := '0';
    signal send_pulse : std_logic;
begin

    tx_busy <= busy;
    send_pulse <= send_en and not send_d;

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            send_d <= '0';
        elsif rising_edge(clk) then
            send_d <= send_en;
        end if;
    end process;

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            busy    <= '0';
            bit_cnt <= 0;
            uart_tx <= '1';
            tx_done <= '0';
        elsif rising_edge(clk) then
            tx_done <= '0';

            if send_pulse = '1' and busy = '0' then
                busy     <= '1';
                data_reg <= data_byte;
                bit_cnt  <= 0;
            end if;

            if busy = '1' and tick_1x = '1' then
                case bit_cnt is
                    when 0 => uart_tx <= '0'; -- start
                    when 1 => uart_tx <= data_reg(0);
                    when 2 => uart_tx <= data_reg(1);
                    when 3 => uart_tx <= data_reg(2);
                    when 4 => uart_tx <= data_reg(3);
                    when 5 => uart_tx <= data_reg(4);
                    when 6 => uart_tx <= data_reg(5);
                    when 7 => uart_tx <= data_reg(6);
                    when 8 => uart_tx <= data_reg(7);
                    when 9 => uart_tx <= '1'; 
                    when 10=> uart_tx <= '1'; 
                    when others => uart_tx <= '1';
                end case;

                if bit_cnt = 10 then
                    busy    <= '0';
                    tx_done <= '1';
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;