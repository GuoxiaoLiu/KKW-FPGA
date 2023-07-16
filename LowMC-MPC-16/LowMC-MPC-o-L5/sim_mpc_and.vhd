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
    signal b : in std_logic;
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
      signal and_helper_0 : in std_logic;
      signal and_helper_1 : in std_logic;
      signal and_helper_2 : in std_logic;
      signal and_helper_3 : in std_logic;
      signal and_helper_4 : in std_logic;
      signal and_helper_5 : in std_logic;
      signal and_helper_6 : in std_logic;
      signal and_helper_7 : in std_logic;
      signal and_helper_8 : in std_logic;
      signal and_helper_9 : in std_logic;
      signal and_helper_10 : in std_logic;
      signal and_helper_11 : in std_logic;
      signal and_helper_12 : in std_logic;
      signal and_helper_13 : in std_logic;
      signal and_helper_14 : in std_logic;
      signal and_helper_15 : in std_logic;
    -- Output signals
    signal msgs_0 : out std_logic;
    signal msgs_1 : out std_logic;
    signal msgs_2 : out std_logic;
    signal msgs_3 : out std_logic;
    signal msgs_4 : out std_logic;
    signal msgs_5 : out std_logic;
    signal msgs_6 : out std_logic;
    signal msgs_7 : out std_logic;
    signal msgs_8 : out std_logic;
    signal msgs_9 : out std_logic;
    signal msgs_10 : out std_logic;
    signal msgs_11 : out std_logic;
    signal msgs_12 : out std_logic;
    signal msgs_13 : out std_logic;
    signal msgs_14 : out std_logic;
    signal msgs_15 : out std_logic
  );
end entity;

architecture behavorial of sim_mpc_and is
begin
  msgs_0 <= (a and b_i_0) xor (b and a_i_0) xor and_helper_0;
  msgs_1 <= (a and b_i_1) xor (b and a_i_1) xor and_helper_1;
  msgs_2 <= (a and b_i_2) xor (b and a_i_2) xor and_helper_2;
  msgs_3 <= (a and b_i_3) xor (b and a_i_3) xor and_helper_3;
  msgs_4 <= (a and b_i_4) xor (b and a_i_4) xor and_helper_4;
  msgs_5 <= (a and b_i_5) xor (b and a_i_5) xor and_helper_5;
  msgs_6 <= (a and b_i_6) xor (b and a_i_6) xor and_helper_6;
  msgs_7 <= (a and b_i_7) xor (b and a_i_7) xor and_helper_7;
  msgs_8 <= (a and b_i_8) xor (b and a_i_8) xor and_helper_8;
  msgs_9 <= (a and b_i_9) xor (b and a_i_9) xor and_helper_9;
  msgs_10 <= (a and b_i_10) xor (b and a_i_10) xor and_helper_10;
  msgs_11 <= (a and b_i_11) xor (b and a_i_11) xor and_helper_11;
  msgs_12 <= (a and b_i_12) xor (b and a_i_12) xor and_helper_12;
  msgs_13 <= (a and b_i_13) xor (b and a_i_13) xor and_helper_13;
  msgs_14 <= (a and b_i_14) xor (b and a_i_14) xor and_helper_14;
  msgs_15 <= (a and b_i_15) xor (b and a_i_15) xor and_helper_15;
end behavorial;