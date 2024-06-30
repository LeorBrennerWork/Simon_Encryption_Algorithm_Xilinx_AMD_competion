library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.array_signal_pkg.all;

entity key_schedule_generator is
    port 
        (
        C_CLK: in std_logic; --Clock signal
        C_RST: in std_logic; --Reset signal
        C_KEY: in std_logic_vector(63 downto 0); --Key
        KEY_SCHDL: out array_signal(0 to 31) --Array of 32 subkeys
        );
end key_schedule_generator;

architecture key_schedule_generator_arc of key_schedule_generator is

    --Arrays to store outputs and inputs of the key schedule generator
    signal c_key_schedule_in : array_signal(0 to 30);
    signal c_key_schedule_out : array_signal(0 to 31);

    component sub_key_generator
        port 
            (
            S_CLK: in std_logic; 
            S_RST: in std_logic;
            Z_COUNTER: in integer range 0 to 32; 
            SUB_KEY_i_1: in std_logic_vector(15 downto 0);
            SUB_KEY_i_m: in std_logic_vector(15 downto 0);
            SUB_KEY_i_3: in std_logic_vector(15 downto 0); 
            SUB_KEY_i: out std_logic_vector(15 downto 0)
            );
    end component;
    
    begin
        --Syncs inputs of rounds x+1 with outputs of rounds x
        synch_key_round_signals : process 
        begin
            wait until rising_edge(C_CLK);
            if C_RST = '1' then
                c_key_schedule_in <= (others => (others => '0'));
            else
                c_key_schedule_in <= c_key_schedule_out(0 to 30);   
            end if; 
        end process;
        
        --Generate starting subkeys
        signal_out : process 
        begin
            wait until rising_edge(C_CLK);
            if C_RST = '1' then
                c_key_schedule_out(0) <= (others => '0');
                c_key_schedule_out(1) <= (others => '0');
                c_key_schedule_out(2) <= (others => '0');
                c_key_schedule_out(3) <= (others => '0');
            else 
                c_key_schedule_out(0) <= C_KEY(15 downto 0);
                c_key_schedule_out(1) <= C_KEY(31 downto 16);
                c_key_schedule_out(2) <= C_KEY(47 downto 32);
                c_key_schedule_out(3) <= C_KEY(63 downto 48);
            end if;
        end process;

        --Output full key schedule
        output : process 
        begin
            wait until rising_edge(C_CLK);
            if C_RST = '1' then
                KEY_SCHDL <= (others => (others => '0')); 
            else
                KEY_SCHDL <= c_key_schedule_out; 
            end if;   
        end process;

        sub_key_generator_4 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 0,
            SUB_KEY_i_1 => c_key_schedule_in(3),
            SUB_KEY_i_m => c_key_schedule_in(0),
            SUB_KEY_i_3 => c_key_schedule_in(1),
            SUB_KEY_i => c_key_schedule_out(4)
        );

        sub_key_generator_5 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 1,
            SUB_KEY_i_1 => c_key_schedule_in(4),
            SUB_KEY_i_m => c_key_schedule_in(1),
            SUB_KEY_i_3 => c_key_schedule_in(2),
            SUB_KEY_i => c_key_schedule_out(5)
        );
        sub_key_generator_6 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 2,
            SUB_KEY_i_1 => c_key_schedule_in(5),
            SUB_KEY_i_m => c_key_schedule_in(2),
            SUB_KEY_i_3 => c_key_schedule_in(3),
            SUB_KEY_i => c_key_schedule_out(6)
        );
        sub_key_generator_7 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 3,
            SUB_KEY_i_1 => c_key_schedule_in(6),
            SUB_KEY_i_m => c_key_schedule_in(3),
            SUB_KEY_i_3 => c_key_schedule_in(4),
            SUB_KEY_i => c_key_schedule_out(7)
        );
        sub_key_generator_8 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 4,
            SUB_KEY_i_1 => c_key_schedule_in(7),
            SUB_KEY_i_m => c_key_schedule_in(4),
            SUB_KEY_i_3 => c_key_schedule_in(5),
            SUB_KEY_i => c_key_schedule_out(8)
        );
        sub_key_generator_9 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 5,
            SUB_KEY_i_1 => c_key_schedule_in(8),
            SUB_KEY_i_m => c_key_schedule_in(5),
            SUB_KEY_i_3 => c_key_schedule_in(6),
            SUB_KEY_i => c_key_schedule_out(9)
        );
        sub_key_generator_10 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 6,
            SUB_KEY_i_1 => c_key_schedule_in(9),
            SUB_KEY_i_m => c_key_schedule_in(6),
            SUB_KEY_i_3 => c_key_schedule_in(7),
            SUB_KEY_i => c_key_schedule_out(10)
        );
        sub_key_generator_11 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 7,
            SUB_KEY_i_1 => c_key_schedule_in(10),
            SUB_KEY_i_m => c_key_schedule_in(7),
            SUB_KEY_i_3 => c_key_schedule_in(8),
            SUB_KEY_i => c_key_schedule_out(11)
        );
        sub_key_generator_12 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 8,
            SUB_KEY_i_1 => c_key_schedule_in(11),
            SUB_KEY_i_m => c_key_schedule_in(8),
            SUB_KEY_i_3 => c_key_schedule_in(9),
            SUB_KEY_i => c_key_schedule_out(12)
        );
        sub_key_generator_13 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 9,
            SUB_KEY_i_1 => c_key_schedule_in(12),
            SUB_KEY_i_m => c_key_schedule_in(9),
            SUB_KEY_i_3 => c_key_schedule_in(10),
            SUB_KEY_i => c_key_schedule_out(13)
        );
        sub_key_generator_14 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 10,
            SUB_KEY_i_1 => c_key_schedule_in(13),
            SUB_KEY_i_m => c_key_schedule_in(10),
            SUB_KEY_i_3 => c_key_schedule_in(11),
            SUB_KEY_i => c_key_schedule_out(14)
        );
        sub_key_generator_15 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 11,
            SUB_KEY_i_1 => c_key_schedule_in(14),
            SUB_KEY_i_m => c_key_schedule_in(11),
            SUB_KEY_i_3 => c_key_schedule_in(12),
            SUB_KEY_i => c_key_schedule_out(15)
        );
        sub_key_generator_16 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 12,
            SUB_KEY_i_1 => c_key_schedule_in(15),
            SUB_KEY_i_m => c_key_schedule_in(12),
            SUB_KEY_i_3 => c_key_schedule_in(13),
            SUB_KEY_i => c_key_schedule_out(16)
        );
        sub_key_generator_17 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 13,
            SUB_KEY_i_1 => c_key_schedule_in(16),
            SUB_KEY_i_m => c_key_schedule_in(13),
            SUB_KEY_i_3 => c_key_schedule_in(14),
            SUB_KEY_i => c_key_schedule_out(17)
        );
        sub_key_generator_18 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 14,
            SUB_KEY_i_1 => c_key_schedule_in(17),
            SUB_KEY_i_m => c_key_schedule_in(14),
            SUB_KEY_i_3 => c_key_schedule_in(15),
            SUB_KEY_i => c_key_schedule_out(18)
        );
        sub_key_generator_19 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 15,
            SUB_KEY_i_1 => c_key_schedule_in(18),
            SUB_KEY_i_m => c_key_schedule_in(15),
            SUB_KEY_i_3 => c_key_schedule_in(16),
            SUB_KEY_i => c_key_schedule_out(19)
        );
        sub_key_generator_20 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 16,
            SUB_KEY_i_1 => c_key_schedule_in(19),
            SUB_KEY_i_m => c_key_schedule_in(16),
            SUB_KEY_i_3 => c_key_schedule_in(17),
            SUB_KEY_i => c_key_schedule_out(20)
        );
        sub_key_generator_21 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 17,
            SUB_KEY_i_1 => c_key_schedule_in(20),
            SUB_KEY_i_m => c_key_schedule_in(17),
            SUB_KEY_i_3 => c_key_schedule_in(18),
            SUB_KEY_i => c_key_schedule_out(21)
        );
        sub_key_generator_22 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 18,
            SUB_KEY_i_1 => c_key_schedule_in(21),
            SUB_KEY_i_m => c_key_schedule_in(18),
            SUB_KEY_i_3 => c_key_schedule_in(19),
            SUB_KEY_i => c_key_schedule_out(22)
        );
        sub_key_generator_23 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 19,
            SUB_KEY_i_1 => c_key_schedule_in(22),
            SUB_KEY_i_m => c_key_schedule_in(19),
            SUB_KEY_i_3 => c_key_schedule_in(20),
            SUB_KEY_i => c_key_schedule_out(23)
        );
        sub_key_generator_24 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 20,
            SUB_KEY_i_1 => c_key_schedule_in(23),
            SUB_KEY_i_m => c_key_schedule_in(20),
            SUB_KEY_i_3 => c_key_schedule_in(21),
            SUB_KEY_i => c_key_schedule_out(24)
        );
        sub_key_generator_25 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 21,
            SUB_KEY_i_1 => c_key_schedule_in(24),
            SUB_KEY_i_m => c_key_schedule_in(21),
            SUB_KEY_i_3 => c_key_schedule_in(22),
            SUB_KEY_i => c_key_schedule_out(25)
        );
        sub_key_generator_26 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 22,
            SUB_KEY_i_1 => c_key_schedule_in(25),
            SUB_KEY_i_m => c_key_schedule_in(22),
            SUB_KEY_i_3 => c_key_schedule_in(23),
            SUB_KEY_i => c_key_schedule_out(26)
        );
        sub_key_generator_27 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 23,
            SUB_KEY_i_1 => c_key_schedule_in(26),
            SUB_KEY_i_m => c_key_schedule_in(23),
            SUB_KEY_i_3 => c_key_schedule_in(24),
            SUB_KEY_i => c_key_schedule_out(27)
        );
        sub_key_generator_28 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 24,
            SUB_KEY_i_1 => c_key_schedule_in(27),
            SUB_KEY_i_m => c_key_schedule_in(24),
            SUB_KEY_i_3 => c_key_schedule_in(25),
            SUB_KEY_i => c_key_schedule_out(28)
        );
        sub_key_generator_29 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 25,
            SUB_KEY_i_1 => c_key_schedule_in(28),
            SUB_KEY_i_m => c_key_schedule_in(25),
            SUB_KEY_i_3 => c_key_schedule_in(26),
            SUB_KEY_i => c_key_schedule_out(29)
        );
        sub_key_generator_30 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 26,
            SUB_KEY_i_1 => c_key_schedule_in(29),
            SUB_KEY_i_m => c_key_schedule_in(26),
            SUB_KEY_i_3 => c_key_schedule_in(27),
            SUB_KEY_i => c_key_schedule_out(30)
        );
        sub_key_generator_31 : sub_key_generator port map (
            S_CLK => C_CLK,
            S_RST => C_RST,
            Z_COUNTER => 27,
            SUB_KEY_i_1 => c_key_schedule_in(30),
            SUB_KEY_i_m => c_key_schedule_in(27),
            SUB_KEY_i_3 => c_key_schedule_in(28),
            SUB_KEY_i => c_key_schedule_out(31)
        );
        

end key_schedule_generator_arc;