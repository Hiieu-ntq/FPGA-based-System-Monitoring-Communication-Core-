library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_controller is
    Port (
        clk             : in  STD_LOGIC;
        rst_n           : in  STD_LOGIC;
        -- UART FIFO Interface
        fifo_rx_empty   : in  STD_LOGIC;
        fifo_rx_rd_en   : out STD_LOGIC;
        fifo_rx_data    : in  STD_LOGIC_VECTOR(7 downto 0);
        fifo_tx_full    : in  STD_LOGIC;
        fifo_tx_wr_en   : out STD_LOGIC;
        fifo_tx_data    : out STD_LOGIC_VECTOR(7 downto 0);
        -- Watchdog Interface
        wdt_ctrl        : out STD_LOGIC_VECTOR(31 downto 0);
        wdt_twd         : out STD_LOGIC_VECTOR(31 downto 0);
        wdt_trst        : out STD_LOGIC_VECTOR(31 downto 0);
        wdt_arm_delay   : out STD_LOGIC_VECTOR(31 downto 0);
        wdt_status      : in  STD_LOGIC_VECTOR(31 downto 0);
        wdt_kick        : out STD_LOGIC;
        -- GCD Interface
        gcd_a           : out STD_LOGIC_VECTOR(31 downto 0);
        gcd_b           : out STD_LOGIC_VECTOR(31 downto 0);
        gcd_start       : out STD_LOGIC;
        gcd_done        : in  STD_LOGIC;
        gcd_result      : in  STD_LOGIC_VECTOR(31 downto 0)
    );
end fsm_controller;

architecture Behavioral of fsm_controller is
    -- FSM States 
    type state_type is (ST_IDLE, ST_READ_WAIT, ST_READ_DELAY, ST_COLLECT, ST_EXECUTE, ST_WAIT_GCD, ST_PREP_TX, ST_TX_PUSH);
    signal state : state_type;

    -- Buffers
    type byte_arr is array(0 to 8) of std_logic_vector(7 downto 0);
    signal rx_buf : byte_arr := (others => (others => '0'));
    signal tx_buf : byte_arr := (others => (others => '0'));

    signal byte_cnt : integer range 0 to 15 := 0;
    signal tx_cnt   : integer range 0 to 15 := 0;

    -- Internal Registers
    signal reg_ctrl      : std_logic_vector(31 downto 0) := x"00000000"; -- Mặc định Disable sau Reset (Yêu cầu 4.1.1)
    signal reg_twd       : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1600, 32));
    signal reg_trst      : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(200, 32));
    signal reg_arm_delay : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(150, 32));
    signal reg_gcd_a     : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_gcd_b     : std_logic_vector(31 downto 0) := (others => '0');

begin
    wdt_ctrl <= reg_ctrl; wdt_twd <= reg_twd; wdt_trst <= reg_trst;
    wdt_arm_delay <= reg_arm_delay; gcd_a <= reg_gcd_a; gcd_b <= reg_gcd_b;

    process(clk, rst_n)
        variable calc_chk : std_logic_vector(7 downto 0);
        variable cmd, addr : std_logic_vector(7 downto 0);
        variable data_val : std_logic_vector(31 downto 0);
    begin
        if rst_n = '0' then
            state <= ST_IDLE;
            byte_cnt <= 0; tx_cnt <= 0;
            fifo_rx_rd_en <= '0'; fifo_tx_wr_en <= '0';
            wdt_kick <= '0'; gcd_start <= '0';
        elsif rising_edge(clk) then
            fifo_rx_rd_en <= '0';
            fifo_tx_wr_en <= '0';
            wdt_kick <= '0';
            reg_ctrl(2) <= '0'; -- Tự động xóa bit CLR_FAULT sau 1 chu kỳ (Yêu cầu 4.2.8)
            gcd_start <= '0';

            case state is
                -- --- KHỐI NHẬN DỮ LIỆU ---
                when ST_IDLE =>
                    byte_cnt <= 0;
                    if fifo_rx_empty = '0' then
                        state <= ST_READ_WAIT;
                    end if;

                when ST_READ_WAIT =>
                    if fifo_rx_empty = '0' then
                        fifo_rx_rd_en <= '1'; 
                        state <= ST_READ_DELAY; 
                    end if;

                when ST_READ_DELAY =>
                    state <= ST_COLLECT;

                when ST_COLLECT =>
                    rx_buf(byte_cnt) <= fifo_rx_data;
                    
                    if byte_cnt = 0 then
                        if fifo_rx_data = x"55" then
                            byte_cnt <= 1;
                            state <= ST_READ_WAIT; 
                        else
                            state <= ST_IDLE;      -- Sai header reset 
                        end if;
                    elsif byte_cnt < 8 then
                        byte_cnt <= byte_cnt + 1;
                        state <= ST_READ_WAIT;     -- Tiếp tục vòng lặp nhận
                    else
                        -- Đã nhận đủ phần tử thứ 9 (checksum)
                        calc_chk := rx_buf(1) xor rx_buf(2) xor rx_buf(3) xor rx_buf(4) xor rx_buf(5) xor rx_buf(6) xor rx_buf(7);
                        if fifo_rx_data = calc_chk then
                            state <= ST_EXECUTE;
                        else
                            state <= ST_IDLE;
                        end if;
                        byte_cnt <= 0;
                    end if;

                -- --- KHỐI XỬ LÝ ---
                when ST_EXECUTE =>
                    cmd      := rx_buf(1);
                    addr     := rx_buf(2);
                    data_val := rx_buf(4) & rx_buf(5) & rx_buf(6) & rx_buf(7);

                    --(ACK/Response)
                    tx_buf(0) <= x"55"; tx_buf(1) <= cmd; tx_buf(2) <= addr;
                    tx_buf(3) <= x"04";
                    tx_buf(4) <= rx_buf(4); tx_buf(5) <= rx_buf(5);
                    tx_buf(6) <= rx_buf(6); tx_buf(7) <= rx_buf(7);

                    case cmd is
                        when x"01" => -- WRITE REG
                            if    addr = x"00" then reg_ctrl <= data_val;
                            elsif addr = x"04" then reg_twd  <= data_val;
                            elsif addr = x"08" then reg_trst <= data_val;
                            elsif addr = x"0C" then reg_arm_delay <= data_val;
                            elsif addr = x"14" then reg_gcd_a <= data_val;
                            elsif addr = x"18" then reg_gcd_b <= data_val;
                            end if;
                            state <= ST_PREP_TX;

                        when x"02" | x"04" => -- READ / GET STATUS
                            if    addr = x"00" then data_val := reg_ctrl;
                            elsif addr = x"04" then data_val := reg_twd;
                            elsif addr = x"08" then data_val := reg_trst;
                            elsif addr = x"0C" then data_val := reg_arm_delay;
                            elsif addr = x"10" then data_val := wdt_status;
                            elsif addr = x"14" then data_val := reg_gcd_a;
                            elsif addr = x"18" then data_val := reg_gcd_b;
                            elsif addr = x"1C" then data_val := gcd_result;
                            end if;
                            tx_buf(4) <= data_val(31 downto 24); tx_buf(5) <= data_val(23 downto 16);
                            tx_buf(6) <= data_val(15 downto 8);  tx_buf(7) <= data_val(7 downto 0);
                            state <= ST_PREP_TX;

                        when x"03" => -- KICK WDT
                            wdt_kick <= '1';
                            state <= ST_PREP_TX;

                        when x"05" => -- START GCD
                            gcd_start <= '1';
                            state <= ST_WAIT_GCD;

                        when others =>
                            state <= ST_IDLE;
                    end case;

                when ST_WAIT_GCD =>
                    if gcd_done = '1' then
                        tx_buf(2) <= x"1C"; 
                        tx_buf(4) <= gcd_result(31 downto 24); tx_buf(5) <= gcd_result(23 downto 16);
                        tx_buf(6) <= gcd_result(15 downto 8);  tx_buf(7) <= gcd_result(7 downto 0);
                        state <= ST_PREP_TX;
                    end if;

                -- --- KHỐI PHẢN HỒI ---
                when ST_PREP_TX =>
                    -- Tính Checksum cho gói trả về
                    tx_buf(8) <= tx_buf(1) xor tx_buf(2) xor tx_buf(3) xor tx_buf(4) xor tx_buf(5) xor tx_buf(6) xor tx_buf(7);
                    tx_cnt <= 0;
                    state <= ST_TX_PUSH;

                when ST_TX_PUSH =>
                    if fifo_tx_full = '0' then
                        fifo_tx_wr_en <= '1';
                        fifo_tx_data <= tx_buf(tx_cnt);
                        if tx_cnt = 8 then
                            state <= ST_IDLE; -- Hoàn tất gửi đủ 9 byte -> về IDLE
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;
                    end if; 

            end case;
        end if;
    end process;
end Behavioral;
