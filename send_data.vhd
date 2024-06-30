library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.all;

entity send_data is
    port 
        ( 
        Clk : in STD_LOGIC; --Clock signal
        Rst : in STD_LOGIC; --Reset signal
        ciphertext_send : in STD_LOGIC; --Flag for when to start transmission
        data : in STD_LOGIC_VECTOR (31 downto 0); --Data to send
        txd_data_out_top : out STD_LOGIC --Data sent
        );
end send_data;

architecture Behavioral of send_data is

    component uart_txd_combine 
        port 
        (
        t_CLK : in STD_LOGIC;
        t_Rst : in STD_LOGIC;
        input_data : in STD_LOGIC_VECTOR (7 downto 0);
        Start_txd : in STD_LOGIC;
        txd_data_out : out STD_LOGIC;
        end_of_txd : out STD_LOGIC
        );
    end component;


    signal send_data_internal : std_logic_vector(7 downto 0); --Byte of data sent per "round"
    signal txd_done_internal : std_logic; --Flag when each byte is done being transmitted
    signal ciphertext_send_hold : std_logic; --Flag to keep transmitting from when the ciphertext is ready to be sent until it is finished being sent
    signal start_transmission : std_logic; --Flag to start transmission
    signal data_divide_counter : integer range 0 to 4; --Counter for sending 4 bytes
    --Flags to shorten long pulse to 1 clock cycle pulse
    signal txd_done_prev : std_logic;  
    signal txd_done_current : std_logic;

    


    begin 

        --Transforms txd_done_internal (long '1' pulse) into 1 clock cycle pulse to tell the Basys3 to send another byte
        sync_txd_done : process
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                txd_done_current <= '0';
                txd_done_prev <= '0';
            else
                if txd_done_internal = '1' and txd_done_prev = '0' then
                    txd_done_current <= '1';
                    txd_done_prev <= '1';
                elsif txd_done_internal = '0' then
                    txd_done_current <= '0';
                    txd_done_prev <= '0';
                else
                    txd_done_current <= '0';
                end if;
            end if;
        end process;

        --Divides data into 4 bytes and sends them one at a time
        divide_data : process 
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then 
                data_divide_counter <= 0;
                ciphertext_send_hold <= '0';
                send_data_internal <= (others => '0'); 
                start_transmission <= '0';
            else
                if ciphertext_send = '1' and data_divide_counter = 0 then
                    send_data_internal <= data(31 downto 24);
                    data_divide_counter <= data_divide_counter + 1;
                    ciphertext_send_hold <= '1';
                    start_transmission <= '1';

                elsif ciphertext_send_hold = '1' and txd_done_current = '1' then
                    if data_divide_counter = 4 then
                        data_divide_counter <= 0;
                        ciphertext_send_hold <= '0';
                        start_transmission <= '0';
                    else
                        send_data_internal <= data((31-(data_divide_counter*8)) downto (31-(data_divide_counter*8 + 7)));
                        data_divide_counter <= data_divide_counter + 1;
                        ciphertext_send_hold <= '1';
                    end if;
                end if;
            end if; 
        end process;
        
        txd_do : uart_txd_combine port map (
            t_CLK => Clk,
            t_Rst => Rst,
            input_data => send_data_internal,
            Start_txd => start_transmission,
            end_of_txd => txd_done_internal,
            txd_data_out => txd_data_out_top
        );
end Behavioral;