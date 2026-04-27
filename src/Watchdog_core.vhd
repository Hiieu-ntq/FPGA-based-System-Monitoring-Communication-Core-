LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Watchdog_Core IS
    GENERIC (
        CLK_FREQ : INTEGER := 27_000_000
    );
    PORT(
        clk          : IN  STD_LOGIC;
        rst_n        : IN  STD_LOGIC;

        wdi_clean    : IN  STD_LOGIC;
        en_clean     : IN  STD_LOGIC;

        en_sw        : IN  STD_LOGIC;
        clr_fault    : IN  STD_LOGIC;
        kick_uart    : IN  STD_LOGIC;

        twd          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        trst         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        arm_delay    : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);

        wdo          : OUT STD_LOGIC;
        enout        : OUT STD_LOGIC;
        fault_active : OUT STD_LOGIC;
        en_effective : OUT STD_LOGIC
    );
END ENTITY Watchdog_Core;

ARCHITECTURE RTL OF Watchdog_Core IS

    TYPE state_type IS (IDLE, ARM_DELAY_ST, MONITOR_ST, FAULT_ST);
    SIGNAL current_state : state_type := IDLE;

    SIGNAL en_core          : STD_LOGIC := '0';
    SIGNAL wdi_delay        : STD_LOGIC := '1';
    SIGNAL wdi_falling_edge : STD_LOGIC := '0';

    SIGNAL kick_uart_d    : STD_LOGIC := '0';
    SIGNAL kick_uart_edge : STD_LOGIC := '0';
 
    SIGNAL wdi_event        : STD_LOGIC := '0';

    CONSTANT CYCLES_PER_US : INTEGER := CLK_FREQ / 1_000_000;

    SIGNAL cnt_us_base : INTEGER RANGE 0 TO CYCLES_PER_US - 1 := 0;
    SIGNAL cnt_ms_base : INTEGER RANGE 0 TO 999 := 0;

    SIGNAL tick_1us : STD_LOGIC := '0';
    SIGNAL tick_1ms : STD_LOGIC := '0';

    SIGNAL timer_us : UNSIGNED(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL timer_ms : UNSIGNED(31 DOWNTO 0) := (OTHERS => '0');

BEGIN

    en_core <= en_clean AND en_sw;

    PROCESS(clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            kick_uart_d <= '0';
        ELSIF rising_edge(clk) THEN
            kick_uart_d <= kick_uart;
        END IF;
    END PROCESS;

    kick_uart_edge <= '1' WHEN (kick_uart_d = '0' AND kick_uart = '1') ELSE '0';

    PROCESS(clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            wdi_delay <= '1';
        ELSIF rising_edge(clk) THEN
            wdi_delay <= wdi_clean;
        END IF;
    END PROCESS;

    wdi_falling_edge <= '1' WHEN (wdi_delay = '1' AND wdi_clean = '0') ELSE '0';

    wdi_event <= wdi_falling_edge OR kick_uart_edge;

    PROCESS(clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            cnt_us_base <= 0;
            cnt_ms_base <= 0;
            tick_1us    <= '0';
            tick_1ms    <= '0';
        ELSIF rising_edge(clk) THEN
            tick_1us <= '0';
            tick_1ms <= '0';
            IF cnt_us_base = CYCLES_PER_US - 1 THEN
                cnt_us_base <= 0;
                tick_1us    <= '1';
                IF cnt_ms_base = 999 THEN
                    cnt_ms_base <= 0;
                    tick_1ms    <= '1';
                ELSE
                    cnt_ms_base <= cnt_ms_base + 1;
                END IF;
            ELSE
                cnt_us_base <= cnt_us_base + 1;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            current_state <= IDLE;
            timer_us      <= (OTHERS => '0');
            timer_ms      <= (OTHERS => '0');
            wdo           <= '1';
            enout         <= '0';
            fault_active  <= '0';
            en_effective  <= '0';
        ELSIF rising_edge(clk) THEN
            IF en_core = '0' THEN
                current_state <= IDLE;
                timer_us      <= (OTHERS => '0');
                timer_ms      <= (OTHERS => '0');
                wdo           <= '1';
                enout         <= '0';
                fault_active  <= '0';
                en_effective  <= '0';
            ELSE
                CASE current_state IS
                    WHEN IDLE =>
                        timer_us      <= (OTHERS => '0');
                        timer_ms      <= (OTHERS => '0');
                        wdo           <= '1';
                        enout         <= '0';
                        fault_active  <= '0';
                        en_effective  <= '0';
                        current_state <= ARM_DELAY_ST;

                    WHEN ARM_DELAY_ST =>
                        wdo          <= '1';
                        enout        <= '0';
                        fault_active <= '0';
                        en_effective <= '0';
                        timer_ms     <= (OTHERS => '0');
                        IF UNSIGNED(arm_delay) = 0 THEN
                            current_state <= MONITOR_ST;
                            timer_us      <= (OTHERS => '0');
                            timer_ms      <= (OTHERS => '0');
                            enout         <= '1';
                            en_effective  <= '1';
                        ELSIF tick_1us = '1' THEN
                            IF timer_us + 1 >= UNSIGNED(arm_delay) THEN
                                current_state <= MONITOR_ST;
                                timer_us      <= (OTHERS => '0');
                                timer_ms      <= (OTHERS => '0');
                                enout         <= '1';
                                en_effective  <= '1';
                            ELSE
                                timer_us <= timer_us + 1;
                            END IF;
                        END IF;

                    WHEN MONITOR_ST =>
                        wdo          <= '1';
                        enout        <= '1';
                        fault_active <= '0';
                        en_effective <= '1';
                        timer_us     <= (OTHERS => '0');
                        IF wdi_event = '1' THEN
                            timer_ms <= (OTHERS => '0');
                        ELSIF tick_1ms = '1' THEN
                            IF timer_ms + 1 >= UNSIGNED(twd) THEN
                                current_state <= FAULT_ST;
                                timer_ms      <= (OTHERS => '0');
                                wdo           <= '0';
                                fault_active  <= '1';
                                enout         <= '1';
                                en_effective  <= '1';
                            ELSE
                                timer_ms <= timer_ms + 1;
                            END IF;
                        END IF;

                    WHEN FAULT_ST =>
                        wdo          <= '0';
                        enout        <= '1';
                        fault_active <= '1';
                        en_effective <= '1';
                        timer_us     <= (OTHERS => '0');
                        IF clr_fault = '1' THEN
                            current_state <= MONITOR_ST;
                            timer_ms      <= (OTHERS => '0');
                            wdo           <= '1';
                            fault_active  <= '0';
                        ELSIF UNSIGNED(trst) = 0 THEN
                            current_state <= MONITOR_ST;
                            timer_ms      <= (OTHERS => '0');
                            wdo           <= '1';
                            fault_active  <= '0';
                        ELSIF tick_1ms = '1' THEN
                            IF timer_ms + 1 >= UNSIGNED(trst) THEN
                                current_state <= MONITOR_ST;
                                timer_ms      <= (OTHERS => '0');
                                wdo           <= '1';
                                fault_active  <= '0';
                            ELSE
                                timer_ms <= timer_ms + 1;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        current_state <= IDLE;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE RTL;