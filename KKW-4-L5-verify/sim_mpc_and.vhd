library work;
use work.lowmc_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity sim_mpc_and is
  port(
    -- Input signals
    signal a : in std_logic;
    signal a_i_0 : in std_logic;
    signal a_i_1 : in std_logic;
    signal a_i_2 : in std_logic;
    signal a_i_3 : in std_logic;
    signal b : in std_logic;
    signal b_i_0 : in std_logic;
    signal b_i_1 : in std_logic;
    signal b_i_2 : in std_logic;
    signal b_i_3 : in std_logic;
    signal and_helper_0 : in std_logic;
    signal and_helper_1 : in std_logic;
    signal and_helper_2 : in std_logic;
    signal and_helper_3 : in std_logic;
    -- Output signals
    signal msgs_0 : out std_logic;
    signal msgs_1 : out std_logic;
    signal msgs_2 : out std_logic;
    signal msgs_3 : out std_logic
  );
end entity;

architecture behavorial of sim_mpc_and is
begin
  msgs_0 <= (a and b_i_0) xor (b and a_i_0) xor and_helper_0;
  msgs_1 <= (a and b_i_1) xor (b and a_i_1) xor and_helper_1;
  msgs_2 <= (a and b_i_2) xor (b and a_i_2) xor and_helper_2;
  msgs_3 <= (a and b_i_3) xor (b and a_i_3) xor and_helper_3;
end behavorial;