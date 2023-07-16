library work;
use work.lowmc_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity aux_mpc_and is
  port(
    -- Input signals
    signal fresh_output_mask : in std_logic;
      signal a_i_0 : in std_logic;
      signal a_i_1 : in std_logic;
      signal a_i_2 : in std_logic;
      signal b_i_0 : in std_logic;
      signal b_i_1 : in std_logic;
      signal b_i_2 : in std_logic;
      signal and_helper : in std_logic;
    -- Output signals
    signal aux : out std_logic
  );
end entity;

architecture behavorial of aux_mpc_and is
begin
  aux <= ((a_i_0 xor a_i_1 xor a_i_2) and (b_i_0 xor b_i_1 xor b_i_2)) xor and_helper xor fresh_output_mask;
end behavorial;