library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_byte_rx is
  port (
    clk       : in std_logic;
    reset_n   : in std_logic;
    tick_16x  : in std_logic;
    uart_rx   : in std_logic;
    data_byte : out std_logic_vector(7 downto 0);
    rx_done   : out std_logic
  );
end entity;

architecture rtl of uart_byte_rx is
  type state_type is (IDLE, START, DATA, STOP);
  signal state : state_type := IDLE;

  signal sample_cnt : integer range 0 to 15        := 0;
  signal bit_cnt    : integer range 0 to 7         := 0;
  signal shift_reg  : std_logic_vector(7 downto 0) := (others => '0');

  -- Metastability synchronizers
  signal rx_sync_1 : std_logic := '1';
  signal rx_sync_2 : std_logic := '1';

begin

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      rx_sync_1  <= '1';
      rx_sync_2  <= '1';
      state      <= IDLE;
      sample_cnt <= 0;
      bit_cnt    <= 0;
      shift_reg  <= (others => '0');
      rx_done    <= '0';

    elsif rising_edge(clk) then
      rx_sync_1 <= uart_rx;
      rx_sync_2 <= rx_sync_1;
      rx_done   <= '0';

      if tick_16x = '1' then
        case state is
          when IDLE =>
            if rx_sync_2 = '0' then
              sample_cnt <= 0;
              state      <= START;
            end if;

          when START =>
            if sample_cnt = 7 then
              if rx_sync_2 = '0' then
                sample_cnt <= 0;
                bit_cnt    <= 0;
                state      <= DATA;
              else
                state <= IDLE;
              end if;
            else
              sample_cnt <= sample_cnt + 1;
            end if;

          when DATA =>
            if sample_cnt = 15 then
              sample_cnt <= 0;
              shift_reg  <= rx_sync_2 & shift_reg(7 downto 1);

              if bit_cnt = 7 then
                state <= STOP;
              else
                bit_cnt <= bit_cnt + 1;
              end if;
            else
              sample_cnt <= sample_cnt + 1;
            end if;

          when STOP =>
            if sample_cnt = 15 then
              data_byte <= shift_reg;
              rx_done   <= '1';
              state     <= IDLE;
            else
              sample_cnt <= sample_cnt + 1;
            end if;
        end case;
      end if;
    end if;
  end process;

end architecture;