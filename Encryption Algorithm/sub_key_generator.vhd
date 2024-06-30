library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


entity sub_key_generator is
    port 
        (
        S_CLK: in std_logic; --Clock signal
        S_RST: in std_logic; --Reset signal
        Z_COUNTER: in integer range 0 to 27; --Checks which bit of the Z constant to use
        SUB_KEY_i_1: in std_logic_vector(15 downto 0); --Subkey[i-1]
        SUB_KEY_i_m: in std_logic_vector(15 downto 0); --Subkey[i-m]
        SUB_KEY_i_3: in std_logic_vector(15 downto 0); --Subkey[i-3]
        SUB_KEY_i: out std_logic_vector(15 downto 0) --Subkey[i]
        );
end sub_key_generator;

architecture sub_key_generator_arc of sub_key_generator is

    constant const : std_logic_vector(15 downto 0) := "1111111111111100"; --Const = 0xff...fc
    constant z_const : std_logic_vector(31 downto 0) := "10110011100001101010010001011111"; --Z_const for simon 32/64
    signal SR3 : std_logic_vector(15 downto 0); --Register to store right shifted data
    
    begin 
        --generates subkey for current round  
        generate_subkey : process
        begin
            wait until rising_edge(S_CLK);
            if S_RST = '1' then
                SUB_KEY_i <= (others => '0');
                SR3 <= (others => '0');
            else
                SR3 <= (SUB_KEY_i_1(2 downto 0) & SUB_KEY_i_1(15 downto 3)) xor SUB_KEY_i_3;
                SUB_KEY_i <= SR3 xor (SR3(0) & SR3(15 downto 1)) xor SUB_KEY_i_m xor const xor ("000000000000000" & z_const(Z_COUNTER)); 
            end if; 
        end process;
end sub_key_generator_arc;
