library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity simon_cipher_top_encrypt_decrypt is
    port 
        ( 
        Clk : in STD_LOGIC; --Clock signal
        Rst : in STD_LOGIC; --Reset signal
        seven_segment_top : out STD_LOGIC_VECTOR(10 downto 0); --4 bits for anode activate, 7 bits for output
        rxd_data_in_highest : in STD_LOGIC; --Input data
        txd_data_out_highest : out STD_LOGIC --Output data
        );
end simon_cipher_top_encrypt_decrypt;

architecture Behavioral of simon_cipher_top_encrypt_decrypt is

    component get_data
        port 
            ( 
            Clk : in STD_LOGIC;
            Rst : in STD_LOGIC;    
            rxd_data_in_top : in STD_LOGIC;    
            start_cipher : out STD_LOGIC;
            data : out STD_LOGIC_VECTOR (103 downto 0)
            );
    end component;

    component send_data 
        port 
            ( 
            Clk : in STD_LOGIC;
            Rst : in STD_LOGIC;
            ciphertext_send : in STD_LOGIC; 
            data : in STD_LOGIC_VECTOR (31 downto 0);         
            txd_data_out_top : out STD_LOGIC
            );
    end component;

    component simon_cipher_hierarchy_encrypt 
        port 
            (
            CLK: in std_logic; 
            RST: in std_logic;
            PLNTXT: in std_logic_vector(31 downto 0);
            LOAD_PLNTXT: in std_logic;
            KEY: in std_logic_vector(63 downto 0);
            LOAD_KEY: in std_logic;
            START_CIPHER: in std_logic;
            CPHRTXT_RDY: out std_logic;
            CPHRTXT: out std_logic_vector(31 downto 0)
            );
    end component;

    component simon_cipher_hierarchy_decrypt 
        port 
            (
            CLK: in std_logic; 
            RST: in std_logic;
            PLNTXT: in std_logic_vector(31 downto 0);
            LOAD_PLNTXT: in std_logic;
            KEY: in std_logic_vector(63 downto 0);
            LOAD_KEY: in std_logic;
            START_CIPHER: in std_logic;
            CPHRTXT_RDY: out std_logic;
            CPHRTXT: out std_logic_vector(31 downto 0)
            );
    end component;

    component seven_segment 
        port 
            (
            Clk : in STD_LOGIC;
            Rst : in STD_LOGIC;
            Trigger : in STD_LOGIC;
            seven_segment_data : out STD_LOGIC_VECTOR(10 downto 0)
            );
    end component;

    --These signals sync the end of the rxd process and the beginning of the encryption process
    signal rxd_done_internal : std_logic;
    signal rxd_done_current : std_logic;
    signal rxd_done_prev : std_logic;
    signal load_key_internal : std_logic;
    signal load_plntxt_internal : std_logic;

    --All 13 bytes of input data
    signal all_data : std_logic_vector(103 downto 0); 

    --Ciphertext signals: Final ciphertext to be sent and ciphertexts calculated by encrypt and decrypt modules
    signal final_ciphertext : std_logic_vector(31 downto 0);
    signal final_ciphertext_encrypt : std_logic_vector(31 downto 0);
    signal final_ciphertext_decrypt : std_logic_vector(31 downto 0);

    --Flags to check when Basys3 is ready to transmit data (based on if we are encryting or decrypting)
    signal ciphertext_done_current : std_logic;
    signal ciphertext_done_internal_encrypt : std_logic;
    signal ciphertext_done_current_encrypt : std_logic;
    signal ciphertext_done_prev_encrypt : std_logic;
    signal ciphertext_done_internal_decrypt : std_logic;
    signal ciphertext_done_current_decrypt : std_logic;
    signal ciphertext_done_prev_decrypt : std_logic;

    --0 or 1 depending on encrypt or decrypt (respectively)
    signal ed_mux : std_logic; 

    --seven segment counter to refresh each display after 2.6 ms
    signal seven_seg_counter : std_logic_vector(17 downto 0);

    --Trigger seven segment outputs
    signal seven_seg_trigger : std_logic;

    begin
        
        --Transforms rxd_done_internal (long '1' pulse) into 1 clock cycle pulse to check if all data has been received
        sync_rxd_end : process 
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

        --Raises flags called "load_key_internal" and "load_plantxt_internal" to signal when to load new data into the cipher
        --These flags also reset the cipher when they are '1' (meaning new data has been received)
        sync_cipher_start : process 
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                load_key_internal <= '0';
                load_plntxt_internal <= '0';
            else
                if rxd_done_current = '1' then
                    load_key_internal <= '1';
                    load_plntxt_internal <= '1';
                else
                    load_key_internal <= '0';
                    load_plntxt_internal <= '0';
                end if;
            end if;
        end process;

        --Raises flag called "ciphertext_done_current_encrypt" to signal when data has been encrypted and is ready to send
        sync_cipher_send_encrypt : process 
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                ciphertext_done_current_encrypt <= '0';
                ciphertext_done_prev_encrypt <= '0';
            else
                if ciphertext_done_internal_encrypt = '1' and ciphertext_done_prev_encrypt = '0' then
                    ciphertext_done_current_encrypt <= '1';
                    ciphertext_done_prev_encrypt <= '1';
                elsif ciphertext_done_internal_encrypt = '0' then
                    ciphertext_done_current_encrypt <= '0';
                    ciphertext_done_prev_encrypt <= '0';
                else
                    ciphertext_done_current_encrypt <= '0';
                end if;
            end if;
        end process;

        --Raises flag called "ciphertext_done_current_decrypt" to signal when data has been decrypted and is ready to send
        sync_cipher_send_decrypt : process 
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                ciphertext_done_current_decrypt <= '0';
                ciphertext_done_prev_decrypt <= '0';
            else
                if ciphertext_done_internal_decrypt = '1' and ciphertext_done_prev_decrypt = '0' then
                    ciphertext_done_current_decrypt <= '1';
                    ciphertext_done_prev_decrypt <= '1';
                elsif ciphertext_done_internal_decrypt = '0' then
                    ciphertext_done_current_decrypt <= '0';
                    ciphertext_done_prev_decrypt <= '0';
                else
                    ciphertext_done_current_decrypt <= '0';
                end if;
            end if;
        end process;

        --Sends encrypted or decrypted data depending on value of ed_mux
        encrypt_decrypt_mux : process 
        begin
            wait until rising_edge(Clk);
            if Rst = '1' then
                ciphertext_done_current <= '0';
                final_ciphertext <= (others => '0');
            else
                if ed_mux = '0' then
                    ciphertext_done_current <= ciphertext_done_current_encrypt;
                    final_ciphertext <= final_ciphertext_encrypt;
                else
                    ciphertext_done_current <= ciphertext_done_current_decrypt;
                    final_ciphertext <= final_ciphertext_decrypt;
                end if;
            end if;
        end process;
        
        --Gives a value of '0' or '1' to ed_mux
        load_ed_mux : ed_mux <= all_data(96);

        show_seven_seg_message : seven_seg_trigger <= '1' when ((ciphertext_done_internal_encrypt = '1' and ed_mux = '0') or (ciphertext_done_internal_decrypt = '1' and ed_mux = '1')) else '0';
        
        full_rxd_do : get_data port map (
            Clk => Clk,
            Rst => Rst,
            rxd_data_in_top => rxd_data_in_highest,
            start_cipher => rxd_done_internal, 
            data => all_data
        );
        full_txd_do : send_data port map (
            Clk => Clk,
            Rst => Rst,
            ciphertext_send => ciphertext_done_current,
            data => final_ciphertext,
            txd_data_out_top => txd_data_out_highest
        ); 
        encrypt : simon_cipher_hierarchy_encrypt port map ( 
            CLK => Clk,
            RST => Rst,
            PLNTXT => all_data(31 downto 0),
            LOAD_PLNTXT => load_plntxt_internal, 
            KEY => all_data(95 downto 32),
            LOAD_KEY => load_key_internal,
            START_CIPHER => rxd_done_current,
            CPHRTXT_RDY => ciphertext_done_internal_encrypt,
            CPHRTXT => final_ciphertext_encrypt
        );
        decrypt : simon_cipher_hierarchy_decrypt port map ( 
            CLK => Clk,
            RST => Rst,
            PLNTXT => all_data(31 downto 0),
            LOAD_PLNTXT => load_plntxt_internal, 
            KEY => all_data(95 downto 32),
            LOAD_KEY => load_key_internal,
            START_CIPHER => rxd_done_current,
            CPHRTXT_RDY => ciphertext_done_internal_decrypt,
            CPHRTXT => final_ciphertext_decrypt
        );
        seven_seg_output : seven_segment port map (
            Clk => Clk,
            Rst => Rst,
            Trigger => seven_seg_trigger,
            seven_segment_data => seven_segment_top
        );

    
end Behavioral;