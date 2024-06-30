library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;


entity uart_txd_combine is
    Port ( t_CLK : in STD_LOGIC; --Clock signal
           t_Rst : in STD_LOGIC; --Reset signal
           input_data : in STD_LOGIC_VECTOR (7 downto 0); --Data to transmit
           Start_txd : in STD_LOGIC; --Flag to start transmitting
           txd_data_out : out STD_LOGIC; --Transmitted data
           end_of_txd : out STD_LOGIC --Flag when finished transmitting
         );
end uart_txd_combine;

architecture Behavioral of uart_txd_combine is

--state machine definitions
type txd_state_machine is (IDLE, START, TRANSMIT, FINISH);
signal my_txd_state_machine : txd_state_machine;

signal input_data_internal : std_logic_vector(7 downto 0); --Input data to transmit in the state machine
signal baud_rate_counter : std_logic_vector(14 downto 0); --clk is 100MHz / 9600 bps baud rate = 10416 ticks = 14 bits
signal baud_rdy : std_logic; --'1' when baud_rate_counter is at 10416
signal bit_index_counter : integer range 0 to 7; --tells us which bit of the data to send

begin

    --Baud clk to syncronize the 100MHz Basys3 clock and the 9600 bps serial port clock
    baud_clk : process 
    begin
        wait until rising_edge(t_CLK);
        if t_Rst = '1' then
            baud_rate_counter <= (others => '0');
            baud_rdy <= '0';
        elsif baud_rate_counter = "10100010110000" then 
            baud_rdy <= '1';
            baud_rate_counter <= (others => '0');
        else
            baud_rdy <= '0';
            baud_rate_counter <= baud_rate_counter + 1;
        end if;
    end process;


    --Transmitting state machine
    output : process 
    begin
        wait until rising_edge(t_CLK);
        if t_Rst = '1' then
            my_txd_state_machine <= IDLE;
            bit_index_counter <= 0;
            input_data_internal <= (others => '0');
            end_of_txd <= '0';
            txd_data_out <= '0';
        else
            if baud_rdy = '1' then  

                case my_txd_state_machine is

                    when IDLE =>
                        bit_index_counter <= 0;
                        if Start_txd = '1' then    
                            my_txd_state_machine <= START;
                        end if;
                        end_of_txd <= '0';

                    when START =>
                        my_txd_state_machine <= TRANSMIT;
                        txd_data_out <= '0'; --start bit
                        input_data_internal <= input_data;

                    when TRANSMIT =>
                        txd_data_out <= input_data_internal(bit_index_counter);
                        if bit_index_counter < 7 then   
                            bit_index_counter <= bit_index_counter + 1;
                        else
                            my_txd_state_machine <= FINISH;
                        end if;

                    when FINISH =>
                        txd_data_out <= '1'; --end bit
                        my_txd_state_machine <= IDLE;
                        end_of_txd <= '1';

                    when others =>
                        null;

                end case;
            end if;
        end if;

    end process;


    
end Behavioral;
