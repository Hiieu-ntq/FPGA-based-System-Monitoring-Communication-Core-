library ieee;
use ieee.std_logic_1164.all;

package MissU_lib is 
    -- =======================================================
    -- 1.Component UART_BYTE_TX 
    -- =======================================================
component uart_byte_tx is
    port (
        clk         : in  std_logic;                      
        reset_n     : in  std_logic;                     
       data_byte   : in  std_logic_vector(7 downto 0);   
        send_en     : in  std_logic;                     
        baud_set    : in  std_logic_vector(2 downto 0);  
        
        uart_tx     : out std_logic;                    
        tx_done     : out std_logic;                    
        uart_state  : out std_logic                  
    );
end component;

    -- =======================================================
    -- 2.Component UART_BYTE_RX 
    -- =======================================================
component uart_byte_rx is
    port (
        clk         : in  std_logic;                    
        reset_n     : in  std_logic;                    
        uart_rx     : in  std_logic;                    
        baud_set    : in  std_logic_vector(2 downto 0); 
        data_byte   : out std_logic_vector(7 downto 0); 
        rx_done     : out std_logic                     
    );
end component;

    -- =======================================================
    -- 3.Component UART_DATA_TX : Module truyền đa byte  
    -- =======================================================
component uart_data_tx is
    generic (
        DATA_WIDTH : integer := 32;      -- Độ rộng dữ liệu (ví dụ 32 bit = 4 byte)
        MSB_FIRST  : boolean := true     -- True: gửi byte cao trước, False: gửi byte thấp trước
    );
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        data_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        send_en    : in  std_logic;      -- Xung bắt đầu gửi
        baud_set   : in  std_logic_vector(2 downto 0);
        uart_tx    : out std_logic;
        tx_done    : out std_logic;      -- Báo hiệu đã gửi xong toàn bộ chuỗi
        tx_busy    : out std_logic       -- Báo hiệu đang bận
    );
end component;
    -- =======================================================
    -- 4.Component UART_DATA_RX : Module nhận đa byte  
    -- =======================================================
 component uart_data_rx is
    generic (
        DATA_WIDTH : integer := 32;
        MSB_FIRST  : boolean := true;
        CLK_FREQ   : integer := 27000000 -- Tần số clock hệ thống để tính timeout
    );
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        uart_rx    : in  std_logic;
        baud_set   : in  std_logic_vector(2 downto 0);
        data_out   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        rx_done    : out std_logic;      -- Báo hiệu nhận đủ DATA_WIDTH
        timeout    : out std_logic       -- Báo hiệu quá thời gian chờ byte tiếp theo
    );
end component;

    -- =======================================================
    -- 5.Controller
    -- =======================================================
component Controller IS 
	PORT	(
		RST, CLK : IN STD_LOGIC;
		Start :IN STD_LOGIC;
		X_sel,Y_sel : OUT STD_LOGIC;
		X_ld,Y_ld : OUT STD_lOGIC;
		GCD_ld : OUT STD_LOGIC;
		X_neq_Y,X_lt_Y : IN STD_LOGIC;
		Done_o : OUT STD_LOGIC
		);
END component;
    
    -- =======================================================
    -- 6. Datapath 
    -- =======================================================
 component Datapath IS 
	GENERIC ( DATA_WIDTH :Integer := 16);
	PORT	(
		RST, CLK : IN STD_LOGIC;
		X_sel,Y_sel : IN STD_LOGIC;
		X_ld, Y_ld : IN STD_LOGIC;
		X_in,Y_in : IN STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
		X_neq_Y,X_lt_Y : OUT STD_LOGIC;
		GCD_ld : IN STD_LOGIC;
		GCD_o : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
		);
END component;

    -- =======================================================
    -- 7.GCD 
    -- =======================================================
component GCD IS 
	GENERIC ( DATA_WIDTH :Integer := 16);
	PORT	(
		RST, CLK : IN STD_LOGIC;
		Start :IN STD_LOGIC;
		X_in,Y_in : IN STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		GCD_o : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
		Done_o : OUT STD_LOGIC
		);
END component;

    -- =======================================================
    -- 8.Regn 
    -- =======================================================
component Regn  IS 
	GENERIC ( DATA_WIDTH :Integer := 16);
	PORT	(
		RST, CLK : IN STD_LOGIC;
		En :IN STD_LOGIC;
		D : IN STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
		Q : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
		
		);
END component;

    -- =======================================================
    -- 9.UartProtocolDecoder  
    -- =======================================================
component UartProtocolDecoder is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        clk             : in  std_logic;        -- System Clock (27 MHz)
        rst_n           : in  std_logic;        -- Active-low Reset
        
        -- Byte-level UART Interface (from uart_byte_rx)
        rx_data_byte    : in  std_logic_vector(7 downto 0);
        rx_done         : in  std_logic;        -- High pulse when a byte is received
        
        -- GCD Control Interface
        reg_x           : out std_logic_vector(DATA_WIDTH-1 downto 0);
        reg_y           : out std_logic_vector(DATA_WIDTH-1 downto 0);
        gcd_start       : out std_logic;        -- Start pulse for GCD module
        gcd_done_i      : in  std_logic;        -- Input from GCD done signal
        gcd_res_i       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Watchdog Control Interface
        wdt_kick        : out std_logic;        -- Pulse to reset Watchdog timer
        reg_twd         : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Byte-level UART Interface (to uart_byte_tx)
        tx_data_byte    : out std_logic_vector(7 downto 0);
        tx_send_en      : out std_logic;        -- Pulse to trigger transmission
        tx_done_i       : in  std_logic         -- High pulse when transmission ends
    );
end component;

end MissU_lib ;