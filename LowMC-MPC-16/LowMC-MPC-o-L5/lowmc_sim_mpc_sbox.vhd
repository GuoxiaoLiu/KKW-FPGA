library work;
use work.lowmc_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity lowmc_sim_mpc_sbox is
  port(
    -- Input signals
    signal State_in_DI   : in std_logic_vector(N - 1 downto 0);
    signal Aux_DI        : in std_logic_vector(N - 1 downto 0);
    signal Tape_DI       : in N_2_ARR;
    signal Tape_last_DI  : in std_logic_vector(N - 1 downto 0);
    -- Output signals
    signal State_out_DO  : out std_logic_vector(N - 1 downto 0);
    signal Msgs_DO       : out N_ARR
  );
end entity;

architecture behavorial of lowmc_sim_mpc_sbox is
  signal msgs_out : N_ARR;
  signal and_helper : std_logic_vector(N - 1 downto 0);
  
  component sim_mpc_and is
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
  end component;
begin
  SBOX_GEN : for i in 0 to S - 1 generate
    -- and_helper
    AB : sim_mpc_and
    port map(
      a => State_in_DI(3 * i + 0),
      a_i_0 => Tape_DI(0)(N + 3 * i + 0),
      a_i_1 => Tape_DI(1)(N + 3 * i + 0),
      a_i_2 => Tape_DI(2)(N + 3 * i + 0),
      a_i_3 => Tape_DI(3)(N + 3 * i + 0),
      a_i_4 => Tape_DI(4)(N + 3 * i + 0),
      a_i_5 => Tape_DI(5)(N + 3 * i + 0),
      a_i_6 => Tape_DI(6)(N + 3 * i + 0),
      a_i_7 => Tape_DI(7)(N + 3 * i + 0),
      a_i_8 => Tape_DI(8)(N + 3 * i + 0),
      a_i_9 => Tape_DI(9)(N + 3 * i + 0),
      a_i_10 => Tape_DI(10)(N + 3 * i + 0),
      a_i_11 => Tape_DI(11)(N + 3 * i + 0),
      a_i_12 => Tape_DI(12)(N + 3 * i + 0),
      a_i_13 => Tape_DI(13)(N + 3 * i + 0),
      a_i_14 => Tape_DI(14)(N + 3 * i + 0),
      a_i_15 => Tape_last_DI(3 * i + 0),
      b => State_in_DI(3 * i + 1),
      b_i_0 => Tape_DI(0)(N + 3 * i + 1),
      b_i_1 => Tape_DI(1)(N + 3 * i + 1),
      b_i_2 => Tape_DI(2)(N + 3 * i + 1),
      b_i_3 => Tape_DI(3)(N + 3 * i + 1),
      b_i_4 => Tape_DI(4)(N + 3 * i + 1),
      b_i_5 => Tape_DI(5)(N + 3 * i + 1),
      b_i_6 => Tape_DI(6)(N + 3 * i + 1),
      b_i_7 => Tape_DI(7)(N + 3 * i + 1),
      b_i_8 => Tape_DI(8)(N + 3 * i + 1),
      b_i_9 => Tape_DI(9)(N + 3 * i + 1),
      b_i_10 => Tape_DI(10)(N + 3 * i + 1),
      b_i_11 => Tape_DI(11)(N + 3 * i + 1),
      b_i_12 => Tape_DI(12)(N + 3 * i + 1),
      b_i_13 => Tape_DI(13)(N + 3 * i + 1),
      b_i_14 => Tape_DI(14)(N + 3 * i + 1),
      b_i_15 => Tape_last_DI(3 * i + 1),
      and_helper_0 => Tape_DI(0)(3 * i + 2),
      and_helper_1 => Tape_DI(1)(3 * i + 2),
      and_helper_2 => Tape_DI(2)(3 * i + 2),
      and_helper_3 => Tape_DI(3)(3 * i + 2),
      and_helper_4 => Tape_DI(4)(3 * i + 2),
      and_helper_5 => Tape_DI(5)(3 * i + 2),
      and_helper_6 => Tape_DI(6)(3 * i + 2),
      and_helper_7 => Tape_DI(7)(3 * i + 2),
      and_helper_8 => Tape_DI(8)(3 * i + 2),
      and_helper_9 => Tape_DI(9)(3 * i + 2),
      and_helper_10 => Tape_DI(10)(3 * i + 2),
      and_helper_11 => Tape_DI(11)(3 * i + 2),
      and_helper_12 => Tape_DI(12)(3 * i + 2),
      and_helper_13 => Tape_DI(13)(3 * i + 2),
      and_helper_14 => Tape_DI(14)(3 * i + 2),
      and_helper_15 => Aux_DI(3 * i + 2),
      msgs_0 => msgs_out(0)(3 * i + 2),
      msgs_1 => msgs_out(1)(3 * i + 2),
      msgs_2 => msgs_out(2)(3 * i + 2),
      msgs_3 => msgs_out(3)(3 * i + 2),
      msgs_4 => msgs_out(4)(3 * i + 2),
      msgs_5 => msgs_out(5)(3 * i + 2),
      msgs_6 => msgs_out(6)(3 * i + 2),
      msgs_7 => msgs_out(7)(3 * i + 2),
      msgs_8 => msgs_out(8)(3 * i + 2),
      msgs_9 => msgs_out(9)(3 * i + 2),
      msgs_10 => msgs_out(10)(3 * i + 2),
      msgs_11 => msgs_out(11)(3 * i + 2),
      msgs_12 => msgs_out(12)(3 * i + 2),
      msgs_13 => msgs_out(13)(3 * i + 2),
      msgs_14 => msgs_out(14)(3 * i + 2),
      msgs_15 => msgs_out(15)(3 * i + 2)
    );
    BC : sim_mpc_and
    port map(
      a => State_in_DI(3 * i + 1),
      a_i_0 => Tape_DI(0)(N + 3 * i + 1),
      a_i_1 => Tape_DI(1)(N + 3 * i + 1),
      a_i_2 => Tape_DI(2)(N + 3 * i + 1),
      a_i_3 => Tape_DI(3)(N + 3 * i + 1),
      a_i_4 => Tape_DI(4)(N + 3 * i + 1),
      a_i_5 => Tape_DI(5)(N + 3 * i + 1),
      a_i_6 => Tape_DI(6)(N + 3 * i + 1),
      a_i_7 => Tape_DI(7)(N + 3 * i + 1),
      a_i_8 => Tape_DI(8)(N + 3 * i + 1),
      a_i_9 => Tape_DI(9)(N + 3 * i + 1),
      a_i_10 => Tape_DI(10)(N + 3 * i + 1),
      a_i_11 => Tape_DI(11)(N + 3 * i + 1),
      a_i_12 => Tape_DI(12)(N + 3 * i + 1),
      a_i_13 => Tape_DI(13)(N + 3 * i + 1),
      a_i_14 => Tape_DI(14)(N + 3 * i + 1),
      a_i_15 => Tape_last_DI(3 * i + 1),
      b => State_in_DI(3 * i + 2),
      b_i_0 => Tape_DI(0)(N + 3 * i + 2),
      b_i_1 => Tape_DI(1)(N + 3 * i + 2),
      b_i_2 => Tape_DI(2)(N + 3 * i + 2),
      b_i_3 => Tape_DI(3)(N + 3 * i + 2),
      b_i_4 => Tape_DI(4)(N + 3 * i + 2),
      b_i_5 => Tape_DI(5)(N + 3 * i + 2),
      b_i_6 => Tape_DI(6)(N + 3 * i + 2),
      b_i_7 => Tape_DI(7)(N + 3 * i + 2),
      b_i_8 => Tape_DI(8)(N + 3 * i + 2),
      b_i_9 => Tape_DI(9)(N + 3 * i + 2),
      b_i_10 => Tape_DI(10)(N + 3 * i + 2),
      b_i_11 => Tape_DI(11)(N + 3 * i + 2),
      b_i_12 => Tape_DI(12)(N + 3 * i + 2),
      b_i_13 => Tape_DI(13)(N + 3 * i + 2),
      b_i_14 => Tape_DI(14)(N + 3 * i + 2),
      b_i_15 => Tape_last_DI(3 * i + 2),
      and_helper_0 => Tape_DI(0)(3 * i + 1),
      and_helper_1 => Tape_DI(1)(3 * i + 1),
      and_helper_2 => Tape_DI(2)(3 * i + 1),
      and_helper_3 => Tape_DI(3)(3 * i + 1),
      and_helper_4 => Tape_DI(4)(3 * i + 1),
      and_helper_5 => Tape_DI(5)(3 * i + 1),
      and_helper_6 => Tape_DI(6)(3 * i + 1),
      and_helper_7 => Tape_DI(7)(3 * i + 1),
      and_helper_8 => Tape_DI(8)(3 * i + 1),
      and_helper_9 => Tape_DI(9)(3 * i + 1),
      and_helper_10 => Tape_DI(10)(3 * i + 1),
      and_helper_11 => Tape_DI(11)(3 * i + 1),
      and_helper_12 => Tape_DI(12)(3 * i + 1),
      and_helper_13 => Tape_DI(13)(3 * i + 1),
      and_helper_14 => Tape_DI(14)(3 * i + 1),
      and_helper_15 => Aux_DI(3 * i + 1),
      msgs_0 => msgs_out(0)(3 * i + 1),
      msgs_1 => msgs_out(1)(3 * i + 1),
      msgs_2 => msgs_out(2)(3 * i + 1),
      msgs_3 => msgs_out(3)(3 * i + 1),
      msgs_4 => msgs_out(4)(3 * i + 1),
      msgs_5 => msgs_out(5)(3 * i + 1),
      msgs_6 => msgs_out(6)(3 * i + 1),
      msgs_7 => msgs_out(7)(3 * i + 1),
      msgs_8 => msgs_out(8)(3 * i + 1),
      msgs_9 => msgs_out(9)(3 * i + 1),
      msgs_10 => msgs_out(10)(3 * i + 1),
      msgs_11 => msgs_out(11)(3 * i + 1),
      msgs_12 => msgs_out(12)(3 * i + 1),
      msgs_13 => msgs_out(13)(3 * i + 1),
      msgs_14 => msgs_out(14)(3 * i + 1),
      msgs_15 => msgs_out(15)(3 * i + 1)
    );
    CA : sim_mpc_and
    port map(
      a => State_in_DI(3 * i + 2),
      a_i_0 => Tape_DI(0)(N + 3 * i + 2),
      a_i_1 => Tape_DI(1)(N + 3 * i + 2),
      a_i_2 => Tape_DI(2)(N + 3 * i + 2),
      a_i_3 => Tape_DI(3)(N + 3 * i + 2),
      a_i_4 => Tape_DI(4)(N + 3 * i + 2),
      a_i_5 => Tape_DI(5)(N + 3 * i + 2),
      a_i_6 => Tape_DI(6)(N + 3 * i + 2),
      a_i_7 => Tape_DI(7)(N + 3 * i + 2),
      a_i_8 => Tape_DI(8)(N + 3 * i + 2),
      a_i_9 => Tape_DI(9)(N + 3 * i + 2),
      a_i_10 => Tape_DI(10)(N + 3 * i + 2),
      a_i_11 => Tape_DI(11)(N + 3 * i + 2),
      a_i_12 => Tape_DI(12)(N + 3 * i + 2),
      a_i_13 => Tape_DI(13)(N + 3 * i + 2),
      a_i_14 => Tape_DI(14)(N + 3 * i + 2),
      a_i_15 => Tape_last_DI(3 * i + 2),
      b => State_in_DI(3 * i + 0),
      b_i_0 => Tape_DI(0)(N + 3 * i + 0),
      b_i_1 => Tape_DI(1)(N + 3 * i + 0),
      b_i_2 => Tape_DI(2)(N + 3 * i + 0),
      b_i_3 => Tape_DI(3)(N + 3 * i + 0),
      b_i_4 => Tape_DI(4)(N + 3 * i + 0),
      b_i_5 => Tape_DI(5)(N + 3 * i + 0),
      b_i_6 => Tape_DI(6)(N + 3 * i + 0),
      b_i_7 => Tape_DI(7)(N + 3 * i + 0),
      b_i_8 => Tape_DI(8)(N + 3 * i + 0),
      b_i_9 => Tape_DI(9)(N + 3 * i + 0),
      b_i_10 => Tape_DI(10)(N + 3 * i + 0),
      b_i_11 => Tape_DI(11)(N + 3 * i + 0),
      b_i_12 => Tape_DI(12)(N + 3 * i + 0),
      b_i_13 => Tape_DI(13)(N + 3 * i + 0),
      b_i_14 => Tape_DI(14)(N + 3 * i + 0),
      b_i_15 => Tape_last_DI(3 * i + 1),
      and_helper_0 => Tape_DI(0)(3 * i + 0),
      and_helper_1 => Tape_DI(1)(3 * i + 0),
      and_helper_2 => Tape_DI(2)(3 * i + 0),
      and_helper_3 => Tape_DI(3)(3 * i + 0),
      and_helper_4 => Tape_DI(4)(3 * i + 0),
      and_helper_5 => Tape_DI(5)(3 * i + 0),
      and_helper_6 => Tape_DI(6)(3 * i + 0),
      and_helper_7 => Tape_DI(7)(3 * i + 0),
      and_helper_8 => Tape_DI(8)(3 * i + 0),
      and_helper_9 => Tape_DI(9)(3 * i + 0),
      and_helper_10 => Tape_DI(10)(3 * i + 0),
      and_helper_11 => Tape_DI(11)(3 * i + 0),
      and_helper_12 => Tape_DI(12)(3 * i + 0),
      and_helper_13 => Tape_DI(13)(3 * i + 0),
      and_helper_14 => Tape_DI(14)(3 * i + 0),
      and_helper_15 => Aux_DI(3 * i + 0),
      msgs_0 => msgs_out(0)(3 * i + 0),
      msgs_1 => msgs_out(1)(3 * i + 0),
      msgs_2 => msgs_out(2)(3 * i + 0),
      msgs_3 => msgs_out(3)(3 * i + 0),
      msgs_4 => msgs_out(4)(3 * i + 0),
      msgs_5 => msgs_out(5)(3 * i + 0),
      msgs_6 => msgs_out(6)(3 * i + 0),
      msgs_7 => msgs_out(7)(3 * i + 0),
      msgs_8 => msgs_out(8)(3 * i + 0),
      msgs_9 => msgs_out(9)(3 * i + 0),
      msgs_10 => msgs_out(10)(3 * i + 0),
      msgs_11 => msgs_out(11)(3 * i + 0),
      msgs_12 => msgs_out(12)(3 * i + 0),
      msgs_13 => msgs_out(13)(3 * i + 0),
      msgs_14 => msgs_out(14)(3 * i + 0),
      msgs_15 => msgs_out(15)(3 * i + 0)
    );
    Msgs : for j in 0 to (P - 1) generate
      Msgs_DO(j)(3 * i + 0) <= msgs_out(j)(3 * i + 0);
      Msgs_DO(j)(3 * i + 1) <= msgs_out(j)(3 * i + 1);
      Msgs_DO(j)(3 * i + 2) <= msgs_out(j)(3 * i + 2);
    end generate;


    State_out_DO(3 * i + 0) <= State_in_DI(3 * i + 0) xor ((msgs_out(0)(3 * i + 1) xor msgs_out(1)(3 * i + 1) xor msgs_out(2)(3 * i + 1) xor msgs_out(3)(3 * i + 1) xor msgs_out(4)(3 * i + 1) xor msgs_out(5)(3 * i + 1) xor msgs_out(6)(3 * i + 1) xor msgs_out(7)(3 * i + 1) xor msgs_out(8)(3 * i + 1) xor msgs_out(9)(3 * i + 1) xor msgs_out(10)(3 * i + 1) xor msgs_out(11)(3 * i + 1) xor msgs_out(12)(3 * i + 1) xor msgs_out(13)(3 * i + 1) xor msgs_out(14)(3 * i + 1) xor msgs_out(15)(3 * i + 1)) xor (State_in_DI(3 * i + 1) and State_in_DI(3 * i + 2)));
    State_out_DO(3 * i + 1) <= State_in_DI(3 * i + 0) xor State_in_DI(3 * i + 1) xor ((msgs_out(0)(3 * i + 0) xor msgs_out(1)(3 * i + 0) xor msgs_out(2)(3 * i + 0) xor msgs_out(3)(3 * i + 0) xor msgs_out(4)(3 * i + 0) xor msgs_out(5)(3 * i + 0) xor msgs_out(6)(3 * i + 0) xor msgs_out(7)(3 * i + 0) xor msgs_out(8)(3 * i + 0) xor msgs_out(9)(3 * i + 0) xor msgs_out(10)(3 * i + 0) xor msgs_out(11)(3 * i + 0) xor msgs_out(12)(3 * i + 0) xor msgs_out(13)(3 * i + 0) xor msgs_out(14)(3 * i + 0) xor msgs_out(15)(3 * i + 0)) xor (State_in_DI(3 * i + 2) and State_in_DI(3 * i + 0)));
    State_out_DO(3 * i + 2) <= State_in_DI(3 * i + 0) xor State_in_DI(3 * i + 1) xor State_in_DI(3 * i + 2) xor ((msgs_out(0)(3 * i + 2) xor msgs_out(1)(3 * i + 2) xor msgs_out(2)(3 * i + 2) xor msgs_out(3)(3 * i + 2) xor msgs_out(4)(3 * i + 2) xor msgs_out(5)(3 * i + 2) xor msgs_out(6)(3 * i + 2) xor msgs_out(7)(3 * i + 2) xor msgs_out(8)(3 * i + 2) xor msgs_out(9)(3 * i + 2) xor msgs_out(10)(3 * i + 2) xor msgs_out(11)(3 * i + 2) xor msgs_out(12)(3 * i + 2) xor msgs_out(13)(3 * i + 2) xor msgs_out(14)(3 * i + 2) xor msgs_out(15)(3 * i + 2)) xor (State_in_DI(3 * i + 0) and State_in_DI(3 * i + 1)));
  end generate;

end behavorial;
