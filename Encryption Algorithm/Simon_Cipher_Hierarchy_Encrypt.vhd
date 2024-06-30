library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.array_signal_pkg.all;

entity simon_cipher_hierarchy_encrypt is
    port 
        (
        CLK: in std_logic; --Clock signal
        RST: in std_logic; --Reset signal
        PLNTXT: in std_logic_vector(31 downto 0); --Plaintext
        LOAD_PLNTXT: in std_logic; --Flag to load plaintext into cipher
        KEY: in std_logic_vector(63 downto 0); --Key
        LOAD_KEY: in std_logic; --Flag to load key into cipher
        START_CIPHER: in std_logic; --Flag to start encryption
        CPHRTXT_RDY: out std_logic; --Flag to transmit ciphertext
        CPHRTXT: out std_logic_vector(31 downto 0) --Ciphertext
        );
end simon_cipher_hierarchy_encrypt;

architecture simon_cipher_hierarchy_encrypt_arc of simon_cipher_hierarchy_encrypt is
    --Arrays to store data from each round of the cipher
    signal key_schedule : array_signal(0 to 31);
    signal upper_plaintext : array_signal(0 to 30);
    signal lower_plaintext : array_signal(0 to 30);
    signal upper_ciphertext : array_signal(0 to 31);
    signal lower_ciphertext : array_signal(0 to 31);

    signal counter : std_logic_vector(6 downto 0); --Counts up until ciphertext is ready to be sent
    signal counter_start_reg : std_logic; --Starts the counter when ciphertext is ready to be calculated and sent

    --Signals to store new and current plaintexts and keys in the event that new data is inputed before current encryption is done
    signal current_plaintext : std_logic_vector(31 downto 0);
    signal new_plaintext : std_logic_vector(31 downto 0);
    signal current_key : std_logic_vector(63 downto 0);
    signal new_key : std_logic_vector(63 downto 0);

    component key_schedule_generator
        port 
            (
            C_CLK: in std_logic; 
            C_RST: in std_logic;
            C_KEY: in std_logic_vector(63 downto 0);
            KEY_SCHDL: out array_signal
            );
    end component;

    component round
        port 
            (
            R_CLK: in std_logic; 
            R_RST: in std_logic;
            SUB_KEY: in std_logic_vector(15 downto 0);
            U_PLNTXT: in std_logic_vector(15 downto 0);
            L_PLNTXT: in std_logic_vector(15 downto 0);
            U_CPHRTXT: out std_logic_vector(15 downto 0);
            L_CPHRTXT: out std_logic_vector(15 downto 0)
            );
    end component;
    begin

        --Syncs inputs of rounds x+1 with outputs of rounds x
        synch_round_signals : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then
                upper_plaintext <= (others => (others => '0'));
                lower_plaintext <= (others => (others => '0'));
            else
                upper_plaintext <= upper_ciphertext(0 to 30);
                lower_plaintext <= lower_ciphertext(0 to 30);
            end if; 
        end process;
        
        --Gets current plaintext that is being input into the Basys3
        new_plntxt_in : process
        begin
            wait until rising_edge(CLK);
            if RST = '1' then
                new_plaintext <= (others => '0');
            else
                new_plaintext <= PLNTXT;
            end if;     
        end process; 

        --Gets current key that is being input into the Basys3
        new_key_in : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then
                new_key <= (others => '0');
            else
                new_key <= KEY;
            end if;     
        end process;

        --Loads next plaintext into register that is used in the algorithm
        load_plaintext_p : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then
                current_plaintext <= (others => '0'); 
            elsif LOAD_PLNTXT = '1' then
                current_plaintext <= new_plaintext;
            end if;
        end process;

        --Loads next key into register that is used in the algorithm
        load_key_p : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then
                current_key <= (others => '0'); 
            elsif LOAD_KEY = '1' then
                current_key <= new_key; 
            end if;
        end process;

        --Raises flag which tells the counter to start running
        counter_start_control : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then 
                counter_start_reg <= '0';
            elsif START_CIPHER = '1' then
                counter_start_reg <= '1';
            end if;
        end process;

        --Counts up to 96 clock cycles
        counter_control : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then 
                counter <= "0000000";
            elsif counter < "1100000" and counter_start_reg = '1' then --96
                counter <= counter + 1;
            end if;  
            if (((LOAD_PLNTXT = '1') and (current_plaintext /= new_plaintext)) or ((current_key /= new_key) and (LOAD_KEY = '1'))) then
                counter <= "0000000";
            end if; 
        end process;
        
        --Outputs the ciphertext
        output : process 
        begin
            wait until rising_edge(CLK);
            if RST = '1' then
                CPHRTXT <= (others => '0');
                CPHRTXT_RDY <= '0';  
            elsif counter /= "1100000" then
                CPHRTXT <= (others => '0'); 
                CPHRTXT_RDY <= '0'; 
            else
                CPHRTXT <= (upper_ciphertext(31) & lower_ciphertext(31));
                CPHRTXT_RDY <= '1'; 
            end if;  
        end process; 

        key_schedule_create : key_schedule_generator port map (
            C_CLK => CLK,
            C_RST => RST,
            C_KEY => current_key, 
            KEY_SCHDL => key_schedule 
        );

        round_1 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(0), 
            U_PLNTXT => current_plaintext(31 downto 16),
            L_PLNTXT => current_plaintext(15 downto 0),
            U_CPHRTXT => upper_ciphertext(0), 
            L_CPHRTXT => lower_ciphertext(0) 
        );
        round_2 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(1),
            U_PLNTXT => upper_plaintext(0),
            L_PLNTXT => lower_plaintext(0),
            U_CPHRTXT => upper_ciphertext(1),
            L_CPHRTXT => lower_ciphertext(1)
            );
        round_3 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(2),
            U_PLNTXT => upper_plaintext(1),
            L_PLNTXT => lower_plaintext(1),
            U_CPHRTXT => upper_ciphertext(2),
            L_CPHRTXT => lower_ciphertext(2)
        );
        round_4 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(3),
            U_PLNTXT => upper_plaintext(2),
            L_PLNTXT => lower_plaintext(2),
            U_CPHRTXT => upper_ciphertext(3),
            L_CPHRTXT => lower_ciphertext(3)
        );
        round_5 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(4),
            U_PLNTXT => upper_plaintext(3),
            L_PLNTXT => lower_plaintext(3),
            U_CPHRTXT => upper_ciphertext(4),
            L_CPHRTXT => lower_ciphertext(4)
        );
        round_6 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(5),
            U_PLNTXT => upper_plaintext(4),
            L_PLNTXT => lower_plaintext(4),
            U_CPHRTXT => upper_ciphertext(5),
            L_CPHRTXT => lower_ciphertext(5)
        );
        round_7 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(6),
            U_PLNTXT => upper_plaintext(5),
            L_PLNTXT => lower_plaintext(5),
            U_CPHRTXT => upper_ciphertext(6),
            L_CPHRTXT => lower_ciphertext(6)
        );
        round_8 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(7),
            U_PLNTXT => upper_plaintext(6),
            L_PLNTXT => lower_plaintext(6),
            U_CPHRTXT => upper_ciphertext(7),
            L_CPHRTXT => lower_ciphertext(7)
        );
        round_9 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(8),
            U_PLNTXT => upper_plaintext(7),
            L_PLNTXT => lower_plaintext(7),
            U_CPHRTXT => upper_ciphertext(8),
            L_CPHRTXT => lower_ciphertext(8)
        );
        round_10 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(9),
            U_PLNTXT => upper_plaintext(8),
            L_PLNTXT => lower_plaintext(8),
            U_CPHRTXT => upper_ciphertext(9),
            L_CPHRTXT => lower_ciphertext(9)
        );
        round_11 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(10),
            U_PLNTXT => upper_plaintext(9),
            L_PLNTXT => lower_plaintext(9),
            U_CPHRTXT => upper_ciphertext(10),
            L_CPHRTXT => lower_ciphertext(10)
        );
        round_12 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(11),
            U_PLNTXT => upper_plaintext(10),
            L_PLNTXT => lower_plaintext(10),
            U_CPHRTXT => upper_ciphertext(11),
            L_CPHRTXT => lower_ciphertext(11)
        );
        round_13 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(12),
            U_PLNTXT => upper_plaintext(11),
            L_PLNTXT => lower_plaintext(11),
            U_CPHRTXT => upper_ciphertext(12),
            L_CPHRTXT => lower_ciphertext(12)
        );
        round_14 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(13),
            U_PLNTXT => upper_plaintext(12),
            L_PLNTXT => lower_plaintext(12),
            U_CPHRTXT => upper_ciphertext(13),
            L_CPHRTXT => lower_ciphertext(13)
        );
        round_15 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(14),
            U_PLNTXT => upper_plaintext(13),
            L_PLNTXT => lower_plaintext(13),
            U_CPHRTXT => upper_ciphertext(14),
            L_CPHRTXT => lower_ciphertext(14)
        );
        round_16 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(15),
            U_PLNTXT => upper_plaintext(14),
            L_PLNTXT => lower_plaintext(14),
            U_CPHRTXT => upper_ciphertext(15),
            L_CPHRTXT => lower_ciphertext(15)
        );
        round_17 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(16),
            U_PLNTXT => upper_plaintext(15),
            L_PLNTXT => lower_plaintext(15),
            U_CPHRTXT => upper_ciphertext(16),
            L_CPHRTXT => lower_ciphertext(16)
        );
        round_18 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(17),
            U_PLNTXT => upper_plaintext(16),
            L_PLNTXT => lower_plaintext(16),
            U_CPHRTXT => upper_ciphertext(17),
            L_CPHRTXT => lower_ciphertext(17)
        );
        round_19 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(18),
            U_PLNTXT => upper_plaintext(17),
            L_PLNTXT => lower_plaintext(17),
            U_CPHRTXT => upper_ciphertext(18),
            L_CPHRTXT => lower_ciphertext(18)
        );
        round_20 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(19),
            U_PLNTXT => upper_plaintext(18),
            L_PLNTXT => lower_plaintext(18),
            U_CPHRTXT => upper_ciphertext(19),
            L_CPHRTXT => lower_ciphertext(19)
        );
        round_21 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(20),
            U_PLNTXT => upper_plaintext(19),
            L_PLNTXT => lower_plaintext(19),
            U_CPHRTXT => upper_ciphertext(20),
            L_CPHRTXT => lower_ciphertext(20)
        );
        round_22 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(21),
            U_PLNTXT => upper_plaintext(20),
            L_PLNTXT => lower_plaintext(20),
            U_CPHRTXT => upper_ciphertext(21),
            L_CPHRTXT => lower_ciphertext(21)
        );
        round_23 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(22),
            U_PLNTXT => upper_plaintext(21),
            L_PLNTXT => lower_plaintext(21),
            U_CPHRTXT => upper_ciphertext(22),
            L_CPHRTXT => lower_ciphertext(22)
        );
        round_24 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(23),
            U_PLNTXT => upper_plaintext(22),
            L_PLNTXT => lower_plaintext(22),
            U_CPHRTXT => upper_ciphertext(23),
            L_CPHRTXT => lower_ciphertext(23)
        );
        round_25 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(24),
            U_PLNTXT => upper_plaintext(23),
            L_PLNTXT => lower_plaintext(23),
            U_CPHRTXT => upper_ciphertext(24),
            L_CPHRTXT => lower_ciphertext(24)
        );
        round_26 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(25),
            U_PLNTXT => upper_plaintext(24),
            L_PLNTXT => lower_plaintext(24),
            U_CPHRTXT => upper_ciphertext(25),
            L_CPHRTXT => lower_ciphertext(25)
        );
        round_27 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(26),
            U_PLNTXT => upper_plaintext(25),
            L_PLNTXT => lower_plaintext(25),
            U_CPHRTXT => upper_ciphertext(26),
            L_CPHRTXT => lower_ciphertext(26)
        );
        round_28 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(27),
            U_PLNTXT => upper_plaintext(26),
            L_PLNTXT => lower_plaintext(26),
            U_CPHRTXT => upper_ciphertext(27),
            L_CPHRTXT => lower_ciphertext(27)
        );
        round_29 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(28),
            U_PLNTXT => upper_plaintext(27),
            L_PLNTXT => lower_plaintext(27),
            U_CPHRTXT => upper_ciphertext(28),
            L_CPHRTXT => lower_ciphertext(28)
        );
        round_30 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(29),
            U_PLNTXT => upper_plaintext(28),
            L_PLNTXT => lower_plaintext(28),
            U_CPHRTXT => upper_ciphertext(29),
            L_CPHRTXT => lower_ciphertext(29)
        );
        round_31 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(30),
            U_PLNTXT => upper_plaintext(29),
            L_PLNTXT => lower_plaintext(29),
            U_CPHRTXT => upper_ciphertext(30),
            L_CPHRTXT => lower_ciphertext(30)
        );
        round_32 : round port map (
            R_CLK => CLK,
            R_RST => RST,
            SUB_KEY => key_schedule(31),
            U_PLNTXT => upper_plaintext(30), 
            L_PLNTXT => lower_plaintext(30),
            U_CPHRTXT => upper_ciphertext(31),
            L_CPHRTXT => lower_ciphertext(31)
        );
        

end simon_cipher_hierarchy_encrypt_arc;