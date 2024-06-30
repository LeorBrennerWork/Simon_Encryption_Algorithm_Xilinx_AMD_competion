library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity uart_rxd is
    Port ( r_CLK : in STD_LOGIC; --Clock signal
           r_RST : in STD_LOGIC; --Reset signal
           rxd_data_in : in STD_LOGIC; --Data from computer
           Data_to_Cipher : out STD_LOGIC_VECTOR (7 downto 0); --Output data to algorithm
           rxd_done : out STD_LOGIC --Flag when done receiving current byte
           );
end uart_rxd;

architecture Behavioral of uart_rxd is

type rxd_state_machine is (IDLE, START, RECEIVE, FINISH_RX, RDY_TX);
signal my_rxd_state_machine : rxd_state_machine;

signal baud_rate_counter : std_logic_vector(10 downto 0); --clk is 100MHz / 9600 bps baud rate = 10416 ticks / 16 = 651 ticks per cycle = 11 bits
signal baud_rdy : std_logic; --'1' when baud_rate_counter is at 10416
signal bit_index_counter : integer range 0 to 7; --tells us which bit of the data to send
signal check_start_end_bit : std_logic; --checks new transmission for '0' start bit
signal baud_middle : std_logic; --flag in order to receive sample from middle byte
signal middle_counter : std_logic_vector(3 downto 0); 


begin

    --Runs at 16x baud rate in order to capture the middle of each input pulse with high accuracy
    baud_clk : process 
    begin
        wait until rising_edge(r_CLK);
        if r_RST = '1' then
            baud_rate_counter <= (others => '0');
            baud_rdy <= '0';
            baud_middle <= '0';
            middle_counter <= (others => '0'); 
        elsif baud_rate_counter = "1010001011" then
            baud_rdy <= '1';
            if middle_counter = "0111" then
                baud_middle <= '1';
            else
                baud_middle <= '0';
            end if;
            if middle_counter <= "1111" then
                middle_counter <= middle_counter + 1;
            else
                middle_counter <= (others => '0');
            end if; 
            baud_rate_counter <= (others => '0'); 
        else
            baud_rdy <= '0';
            baud_rate_counter <= baud_rate_counter + 1;
        end if;
    end process;

    --receiver state machine
    output : process 
    begin
        wait until rising_edge(r_CLK);
        if r_RST = '1' then
            my_rxd_state_machine <= IDLE;
            bit_index_counter <= 0;
            Data_to_Cipher <= (others => '0');
            rxd_done <= '0'; 
        else
            if baud_rdy = '1' then  

                case my_rxd_state_machine is

                    when IDLE =>
                        rxd_done <= '0';
                        bit_index_counter <= 0;
                        Data_to_Cipher <= (others => '0');
                        if rxd_data_in = '0' and baud_middle = '1' then --when start bit is detected   
                            my_rxd_state_machine <= START;
                        end if;

                    when START =>
                        check_start_end_bit <= rxd_data_in; --start bit should be '0'
                        if check_start_end_bit = '1' then 
                            my_rxd_state_machine <= IDLE;  
                        else 
                            my_rxd_state_machine <= RECEIVE;
                        end if;

                    when RECEIVE =>
                        if baud_middle = '1' then
                            Data_to_Cipher(bit_index_counter) <= rxd_data_in;
                            if bit_index_counter < 7 then   
                                bit_index_counter <= bit_index_counter + 1;
                            else
                                my_rxd_state_machine <= FINISH_RX;
                            end if;
                        end if;

                    when FINISH_RX =>
                        my_rxd_state_machine <= RDY_TX;
                        
                    when RDY_TX => 
                        rxd_done <= '1';
                        my_rxd_state_machine <= IDLE;

                    when others =>
                        null;

                end case;
            end if;
        end if;

    end process;
    
end Behavioral;



