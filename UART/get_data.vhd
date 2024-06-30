library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity get_data is
    port 
        ( 
        Clk : in STD_LOGIC; --Clock signal
        Rst : in STD_LOGIC; --Reset signal
        rxd_data_in_top : in STD_LOGIC; --Data received
        start_cipher : out STD_LOGIC; --Flag to start encryption
        data : out STD_LOGIC_VECTOR (103 downto 0) --Data send to encryption algorithm
        );
end get_data;

architecture Behavioral of get_data is

    component uart_rxd 
        port 
        (
        r_CLK : in STD_LOGIC;
        r_Rst : in STD_LOGIC;
        rxd_data_in : in STD_LOGIC;
        Data_to_Cipher : out STD_LOGIC_VECTOR (7 downto 0);
        rxd_done : out STD_LOGIC
        );
    end component;


    signal data_internal : std_logic_vector(7 downto 0);
    --We need 8 "encryption/decryption" bits, 32 plaintext bits and 64 key bits => 32/8 + 64/8 = 12 bytes 
    --so we need to receive 13 bytes of data before sending it to the cipher algorithm.
    signal data_combine_counter : integer range 0 to 13;

    --all_data stores all the inputed data internally
    signal all_data : std_logic_vector(103 downto 0);

    --Flags for when system is done receiving data
    signal rxd_done_internal : std_logic;
    signal rxd_done_prev : std_logic;
    signal rxd_done_current : std_logic;

    begin 

        --Transforms rxd_done_internal (long '1' pulse) into 1 clock cycle pulse to tell the Basys3 to receive another byte
        sync_rxd_done : process
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                rxd_done_current <= '0';
                rxd_done_prev <= '0';
            else
                if rxd_done_internal = '1' and rxd_done_prev = '0' then
                    rxd_done_current <= '1';
                    rxd_done_prev <= '1';
                elsif rxd_done_internal = '0' then
                    rxd_done_current <= '0';
                    rxd_done_prev <= '0';
                else
                    rxd_done_current <= '0';
                end if;
            end if;
        end process;

        --Combines all 13 bytes of data into 1 register
        combine_data : process 
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then 
                all_data <= (others => '0');
                data_combine_counter <= 0;
                start_cipher <= '0';
            else
                if rxd_done_current = '1' then 
                    if data_combine_counter = 12 then 
                        start_cipher <= '1';
                        all_data((103-(data_combine_counter*8)) downto (103-(data_combine_counter*8 + 7))) <= data_internal;
                        data_combine_counter <= 0;
                    else
                        all_data((103-(data_combine_counter*8)) downto (103-(data_combine_counter*8 + 7))) <= data_internal;
                        data_combine_counter <= data_combine_counter + 1;
                        start_cipher <= '0';
                    end if;
                end if;
            end if; 
        end process;

        --Transfers internal data register to output of module
        output : process 
        begin
            wait until rising_edge(Clk);
            data <= all_data;
        end process;


        rxd_do : uart_rxd port map (
            r_CLK => Clk,
            r_Rst => Rst,
            rxd_data_in => rxd_data_in_top,
            Data_to_Cipher => data_internal,
            rxd_done => rxd_done_internal
        );
end Behavioral;