library work;
use work.lowmc_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity lowmc_sbox is
  port(
    -- Input signals
    signal State_in_DI   : in std_logic_vector(N - 1 downto 0);
    -- Output signals
    signal State_out_DO  : out std_logic_vector(N - 1 downto 0)
  );
end entity;

architecture behavorial of lowmc_sbox is
begin
  SBOX_GEN : for i in 0 to S - 1 generate
    -- d = a ^ bc
    State_out_DO(3 * i + 0) <= State_in_DI(3 * i + 0) xor (State_in_DI(3 * i + 1) and State_in_DI(3 * i + 2));
    -- e = a ^ b ^ ca
    State_out_DO(3 * i + 1) <= State_in_DI(3 * i + 0) xor State_in_DI(3 * i + 1) xor (State_in_DI(3 * i + 2) and State_in_DI(3 * i + 0));
    -- f = a ^ b ^ c ^ ab
    State_out_DO(3 * i + 2) <= State_in_DI(3 * i + 0) xor State_in_DI(3 * i + 1) xor State_in_DI(3 * i + 2) xor (State_in_DI(3 * i + 0) and State_in_DI(3 * i + 1));
  end generate;

end behavorial;
