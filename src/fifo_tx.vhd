library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_tx is
    generic (
        FIFO_DEPTH : integer := 32;
        DATA_WIDTH : integer := 8
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        wr_en       : in  std_logic;
        wr_data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        full        : out std_logic;
        rd_en       : in  std_logic;
        rd_data     : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty       : out std_logic;
        data_count  : out unsigned(7 downto 0)
    );
end entity;

architecture rtl of fifo_tx is
    type memory_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_mem : memory_type := (others => (others => '0'));
    signal wr_ptr : integer range 0 to FIFO_DEPTH-1 := 0;
    signal rd_ptr : integer range 0 to FIFO_DEPTH-1 := 0;
    signal count  : integer range 0 to FIFO_DEPTH := 0;
begin
    --Standard FIFO 
    empty   <= '1' when count = 0 else '0';
    full    <= '1' when count = FIFO_DEPTH else '0';
    data_count <= to_unsigned(count, 8);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            rd_data <= (others => '0'); 
            
        elsif rising_edge(clk) then
            --  ghi dữ liệu vào FIFO
            if (wr_en = '1' and count < FIFO_DEPTH) then
                fifo_mem(wr_ptr) <= wr_data;
                if wr_ptr = FIFO_DEPTH-1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
            end if;

            -- đọc dữ liệu ra 
            if (rd_en = '1' and count > 0) then
                rd_data <= fifo_mem(rd_ptr);
                if rd_ptr = FIFO_DEPTH-1 then
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
                end if;
            end if;

            -- Quản lý biến đếm số lượng phần tử
            if (wr_en = '1' and rd_en = '0' and count < FIFO_DEPTH) then
                count <= count + 1;
            elsif (wr_en = '0' and rd_en = '1' and count > 0) then
                count <= count - 1;
            end if;
        end if;
    end process;
end architecture;