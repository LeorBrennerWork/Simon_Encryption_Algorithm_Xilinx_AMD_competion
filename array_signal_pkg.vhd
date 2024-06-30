library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

--Package in order to use arrays in the cipher
package array_signal_pkg is
    type array_signal is array (natural range <>) of std_logic_vector(15 downto 0);
end package;