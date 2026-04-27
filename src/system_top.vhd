library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_top is
    port (
        clk       : in  std_logic;
        
        -- 
        uart_rx   : in  std_logic;
        uart_tx   : out std_logic;
        
        btn_wdi   : in  std_logic;  -- S1: Nút kick watchdog (Active Low)
        btn_en    : in  std_logic;  -- S2: Nút Enable (Active Low)
        
        led_wdo   : out std_logic;  -- D3: Cảnh báo Watchdog (Sáng khi lỗi)
        led_enout : out std_logic   -- D4: Báo trạng thái hoạt động ENOUT
    );
end entity;

architecture rtl of system_top is

    -- Tín hiệu tự động Reset
    signal rst_n   : std_logic := '0';
    signal por_cnt : integer range 0 to 255 := 0;

    -- UART
    signal tick_1x, tick_16x : std_logic;
    signal rx_data  : std_logic_vector(7 downto 0);
    signal rx_done  : std_logic;
    signal tx_done, tx_busy : std_logic;

    -- FIFO RX & TX
    signal fifo_rx_rd_en, fifo_rx_empty : std_logic;
    signal fifo_rx_data : std_logic_vector(7 downto 0);
    signal fifo_tx_wr_en, fifo_tx_full : std_logic;
    signal fifo_tx_rd_en, fifo_tx_empty : std_logic;
    signal fifo_tx_din, fifo_tx_dout : std_logic_vector(7 downto 0);

    -- Tín hiệu kết nối FSM và GCD
    signal gcd_start, gcd_done : std_logic;
    signal gcd_a, gcd_b, gcd_result : std_logic_vector(31 downto 0);
    signal rst_active_high : std_logic;

    -- Tín hiệu kết nối FSM và Watchdog
    signal wdt_ctrl, wdt_twd, wdt_trst, wdt_arm_delay, wdt_status : std_logic_vector(31 downto 0);
    signal wdt_kick : std_logic;
    signal sig_wdo, sig_enout, sig_fault, sig_en_eff : std_logic;

    -- TX Control FSM
    type tx_state_t is (IDLE, WAIT_DATA, SEND);
    signal tx_state : tx_state_t := IDLE;
    signal send_en  : std_logic;

    -- Debounce
    signal wdi_shift, en_shift : std_logic_vector(15 downto 0) := (others => '1');
    signal wdi_clean, en_clean : std_logic := '1';

begin


    --  RESET tự động
    process(clk)
    begin
        if rising_edge(clk) then
            if por_cnt < 255 then
                por_cnt <= por_cnt + 1;
                rst_n <= '0';  
            else
                rst_n <= '1';  
            end if;
        end if;
    end process;

    rst_active_high <= not rst_n; 


    -- DEBOUNCE
    process(clk)
    begin
        if rising_edge(clk) then
            -- Xử lý nút S1 (WDI)
            wdi_shift <= wdi_shift(14 downto 0) & btn_wdi;
            if wdi_shift = x"0000" then wdi_clean <= '0';
            elsif wdi_shift = x"FFFF" then wdi_clean <= '1'; end if;

            -- Xử lý nút S2 (EN)
            en_shift <= en_shift(14 downto 0) & btn_en;
            if en_shift = x"0000" then en_clean <= '0';
            elsif en_shift = x"FFFF" then en_clean <= '1'; end if;
        end if;
    end process;

    -- KHỞI TẠO CÁC MODULE 
    -- Tốc độ Baud 115200 
    baud_inst : entity work.baud_gen
        generic map (CLK_FREQ => 27000000, BAUD_RATE => 115200)
        port map (clk => clk, rst_n => rst_n, tick_1x => tick_1x, tick_16x => tick_16x);

    uart_rx_inst : entity work.uart_byte_rx
        port map (clk => clk, reset_n => rst_n, tick_16x => tick_16x, uart_rx => uart_rx, data_byte => rx_data, rx_done => rx_done);

    fifo_rx_inst : entity work.fifo_rx
        port map (clk => clk, rst_n => rst_n, wr_en => rx_done, wr_data => rx_data, rd_en => fifo_rx_rd_en, rd_data => fifo_rx_data, empty => fifo_rx_empty, full => open, data_count => open);

    -- FSM 
    fsm_inst : entity work.fsm_controller
        port map (
            clk => clk, rst_n => rst_n,
            fifo_rx_empty => fifo_rx_empty, fifo_rx_data => fifo_rx_data, fifo_rx_rd_en => fifo_rx_rd_en,
            fifo_tx_full => fifo_tx_full, fifo_tx_data => fifo_tx_din, fifo_tx_wr_en => fifo_tx_wr_en,
            wdt_ctrl => wdt_ctrl, wdt_twd => wdt_twd, wdt_trst => wdt_trst, wdt_arm_delay => wdt_arm_delay,
            wdt_status => wdt_status, wdt_kick => wdt_kick,
            gcd_a => gcd_a, gcd_b => gcd_b, gcd_start => gcd_start, gcd_done => gcd_done, gcd_result => gcd_result
        );

    -- GCD
     gcd_inst : entity work.GCD
        generic map (DATA_WIDTH => 32)
        port map (
            clk => clk, rst => rst_active_high, start => gcd_start,
            x_in => gcd_a, y_in => gcd_b, done_o => gcd_done, gcd_o => gcd_result
        );

    wdt_status <= x"000000" & "000" & wdt_kick & sig_wdo & sig_enout & sig_fault & sig_en_eff;
    led_wdo <= sig_wdo;
    led_enout <= sig_enout;

    -- Khối giám sát Watchdog Core 
    wdt_inst : entity work.Watchdog_Core
        generic map ( CLK_FREQ => 27000000 )
        port map (
            clk          => clk,
            rst_n        => rst_n,
            wdi_clean    => wdi_clean,     --  S1 
            en_clean     => en_clean,      --  S2 
            en_sw        => wdt_ctrl(0),   -- Lấy từ cấu hình UART
            clr_fault    => wdt_ctrl(2),
            kick_uart    => wdt_kick,      -- Đá bằng UART CMD
            twd          => wdt_twd,       
            trst         => wdt_trst,      
            arm_delay    => wdt_arm_delay(15 downto 0),
            wdo          => sig_wdo,
            enout        => sig_enout,
            fault_active => sig_fault,
            en_effective => sig_en_eff
        );

    fifo_tx_inst : entity work.fifo_tx
        port map (clk => clk, rst_n => rst_n, wr_en => fifo_tx_wr_en, wr_data => fifo_tx_din, full => fifo_tx_full, rd_en => fifo_tx_rd_en, rd_data => fifo_tx_dout, empty => fifo_tx_empty, data_count => open);

    -- Gửi UART 
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_state <= IDLE; 
            fifo_tx_rd_en <= '0'; 
            send_en <= '0';
        elsif rising_edge(clk) then
            fifo_tx_rd_en <= '0'; 
            send_en <= '0';
            
            case tx_state is
                when IDLE =>
                    if (fifo_tx_empty = '0') and (tx_busy = '0') then
                        fifo_tx_rd_en <= '1'; 
                        tx_state <= WAIT_DATA;
                    end if;
                    
                when WAIT_DATA =>
                    send_en <= '1';
                    tx_state <= SEND; 
                    
                when SEND =>
                    if tx_busy = '1' then
                        tx_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    uart_tx_inst : entity work.uart_byte_tx
        port map (clk => clk, reset_n => rst_n, tick_1x => tick_1x, data_byte => fifo_tx_dout, send_en => send_en, uart_tx => uart_tx, tx_done => tx_done, tx_busy => tx_busy);

end architecture;
