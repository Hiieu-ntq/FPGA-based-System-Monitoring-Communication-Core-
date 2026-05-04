library ieee;
use ieee.std_logic_1164.all;

entity uart_tx_control is
    port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        fifo_tx_empty  : in  std_logic;
        tx_busy        : in  std_logic;
        fifo_tx_rd_en  : out std_logic;
        send_en        : out std_logic
    );
end entity;

architecture rtl of uart_tx_control is
    type tx_state_t is (IDLE, WAIT_DATA, SEND);
    signal state : tx_state_t := IDLE;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            fifo_tx_rd_en <= '0';
            send_en <= '0';
        elsif rising_edge(clk) then
            fifo_tx_rd_en <= '0';
            send_en <= '0';
            
            case state is
                when IDLE =>
                    if (fifo_tx_empty = '0') and (tx_busy = '0') then
                        fifo_tx_rd_en <= '1';
                        state <= WAIT_DATA;
                    end if;
                    
                when WAIT_DATA =>
                    send_en <= '1';
                    state <= SEND;
                    
                when SEND =>
                    if tx_busy = '1' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end architecture;
