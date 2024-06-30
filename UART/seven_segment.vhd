library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity seven_segment is
    port 
        ( 
        Clk : in STD_LOGIC; --Clock signal
        Rst : in STD_LOGIC; --Reset signal
        Trigger : in STD_LOGIC; --Triggers 7 seg output
        seven_segment_data : out STD_LOGIC_VECTOR(10 downto 0) --4 bits for anode activate, 7 bits for output
        );
end seven_segment;

architecture Behavioral of seven_segment is

    --seven segment counter to refresh each display after 2.6 ms
    signal seven_seg_counter : std_logic_vector(17 downto 0);

    begin
        
        --Control output of seven segment display based on state of cipher
        seven_segment_output : process
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                seven_segment_data <= (others => '0');
            else
                if Trigger = '1' then
                    case seven_seg_counter(17 downto 16) is
                        when "00" => 
                            seven_segment_data <= "01111000010";
                            
                        when "01" => 
                            seven_segment_data <= "10110000001";

                        when "10" => 
                            seven_segment_data <= "11011101010";

                        when "11" => 
                            seven_segment_data <= "11100110000";

                        when others => 
                            null;
                        end case;
                else
                    seven_segment_data <= (others => '0'); 
                end if;
            end if;
        end process;

        --Control counter for seven segment display
        seven_segment_counter : process
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                seven_seg_counter <= (others => '0');
            else 
                if seven_seg_counter = "111111111111111111" then
                    seven_seg_counter <= (others => '0');
                else
                    seven_seg_counter <= seven_seg_counter + 1; 
                end if;
            end if;
        end process;
        
end Behavioral;