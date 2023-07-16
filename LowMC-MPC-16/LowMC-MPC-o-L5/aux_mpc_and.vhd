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
      signal a_i_3 : in std_logic;
      signal a_i_4 : in std_logic;
      signal a_i_5 : in std_logic;
      signal a_i_6 : in std_logic;
      signal a_i_7 : in std_logic;
      signal a_i_8 : in std_logic;
      signal a_i_9 : in std_logic;
      signal a_i_10 : in std_logic;
      signal a_i_11 : in std_logic;
      signal a_i_12 : in std_logic;
      signal a_i_13 : in std_logic;
      signal a_i_14 : in std_logic;
      signal a_i_15 : in std_logic;
      signal b_i_0 : in std_logic;
      signal b_i_1 : in std_logic;
      signal b_i_2 : in std_logic;
      signal b_i_3 : in std_logic;
      signal b_i_4 : in std_logic;
      signal b_i_5 : in std_logic;
      signal b_i_6 : in std_logic;
      signal b_i_7 : in std_logic;
      signal b_i_8 : in std_logic;
      signal b_i_9 : in std_logic;
      signal b_i_10 : in std_logic;
      signal b_i_11 : in std_logic;
      signal b_i_12 : in std_logic;
      signal b_i_13 : in std_logic;
      signal b_i_14 : in std_logic;
      signal b_i_15 : in std_logic;
      signal and_helper : in std_logic;
    -- Output signals
    signal aux : out std_logic
  );
end entity;

architecture behavorial of aux_mpc_and is
begin
  aux <= ((a_i_0 xor a_i_1 xor a_i_2 xor a_i_3 xor a_i_4 xor a_i_5 xor a_i_6 xor a_i_7 xor a_i_8 xor a_i_9 xor a_i_10 xor a_i_11 xor a_i_12 xor a_i_13 xor a_i_14 xor a_i_15) and (b_i_0 xor b_i_1 xor b_i_2 xor b_i_3 xor b_i_4 xor b_i_5 xor b_i_6 xor b_i_7 xor b_i_8 xor b_i_9 xor b_i_10 xor b_i_11 xor b_i_12 xor b_i_13 xor b_i_14 xor b_i_15)) xor and_helper xor fresh_output_mask;
end behavorial;