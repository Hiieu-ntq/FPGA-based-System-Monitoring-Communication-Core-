library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GCD is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;  
        start   : in  std_logic; 

        x_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        y_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        gcd_o   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        done_o  : out std_logic
    );
end entity;

architecture rtl of GCD is

    type state_type is (IDLE, LOAD, CALC, DONE);
    signal state : state_type := IDLE;

    signal x_reg, y_reg : unsigned(DATA_WIDTH-1 downto 0) := (others => '0');
    signal result       : unsigned(DATA_WIDTH-1 downto 0) := (others => '0');

    signal done_reg : std_logic := '0';

begin

    gcd_o  <= std_logic_vector(result);
    done_o <= done_reg;

    process(clk, rst)
    begin
        if rst = '1' then
            state    <= IDLE;
            x_reg    <= (others => '0');
            y_reg    <= (others => '0');
            result   <= (others => '0');
            done_reg <= '0';

        elsif rising_edge(clk) then
            done_reg <= '0';

            case state is

                when IDLE =>
                    if start = '1' then
                        state <= LOAD;
                    end if;

                when LOAD =>
                    x_reg <= unsigned(x_in);
                    y_reg <= unsigned(y_in);
                    state <= CALC;

                when CALC =>
                    if x_reg = y_reg then
                        result <= x_reg;
                        state  <= DONE;

                    elsif x_reg > y_reg then
                        x_reg <= x_reg - y_reg;

                    else
                        y_reg <= y_reg - x_reg;
                    end if;

                when DONE =>
                    done_reg <= '1'; 
                    state    <= IDLE;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

end architecture;