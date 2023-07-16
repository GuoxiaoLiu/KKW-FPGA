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
      signal b : in std_logic;
      signal b_i_0 : in std_logic;
      signal b_i_1 : in std_logic;
      signal b_i_2 : in std_logic;
      signal b_i_3 : in std_logic;
      signal and_helper : in std_logic;
      -- Output signals
      signal msgs_0 : out std_logic;
      signal msgs_1 : out std_logic;
      signal msgs_2 : out std_logic;
      signal msgs_3 : out std_logic
    );
  end component;
begin
  SBOX_GEN : for i in 0 to S - 1 generate
    and_helper(3 * i + 0) <= Tape_DI(P - 2 - (0))(3 * i + 0) xor Tape_DI(P - 2 - (1))(3 * i + 0) xor Tape_DI(P - 2 - (2))(3 * i + 0) xor Aux_DI(3 * i + 0);
    and_helper(3 * i + 1) <= Tape_DI(P - 2 - (0))(3 * i + 1) xor Tape_DI(P - 2 - (1))(3 * i + 1) xor Tape_DI(P - 2 - (2))(3 * i + 1) xor Aux_DI(3 * i + 1);
    and_helper(3 * i + 2) <= Tape_DI(P - 2 - (0))(3 * i + 2) xor Tape_DI(P - 2 - (1))(3 * i + 2) xor Tape_DI(P - 2 - (2))(3 * i + 2) xor Aux_DI(3 * i + 2);
    AB : sim_mpc_and
    port map(
      a => State_in_DI(3 * i + 0),
      a_i_0 => Tape_DI(0)(N + 3 * i + 0),
      a_i_1 => Tape_DI(1)(N + 3 * i + 0),
      a_i_2 => Tape_DI(2)(N + 3 * i + 0),
      a_i_3 => Tape_last_DI(3 * i + 0),
      b => State_in_DI(3 * i + 1),
      b_i_0 => Tape_DI(0)(N + 3 * i + 1),
      b_i_1 => Tape_DI(1)(N + 3 * i + 1),
      b_i_2 => Tape_DI(2)(N + 3 * i + 1),
      b_i_3 => Tape_last_DI(3 * i + 1),
      and_helper => and_helper(3 * i + 2),
      msgs_0 => msgs_out(0)(3 * i + 2),
      msgs_1 => msgs_out(1)(3 * i + 2),
      msgs_2 => msgs_out(2)(3 * i + 2),
      msgs_3 => msgs_out(3)(3 * i + 2)
    );
    BC : sim_mpc_and
    port map(
      a => State_in_DI(3 * i + 1),
      a_i_0 => Tape_DI(0)(N + 3 * i + 1),
      a_i_1 => Tape_DI(1)(N + 3 * i + 1),
      a_i_2 => Tape_DI(2)(N + 3 * i + 1),
      a_i_3 => Tape_last_DI(3 * i + 1),
      b => State_in_DI(3 * i + 2),
      b_i_0 => Tape_DI(0)(N + 3 * i + 2),
      b_i_1 => Tape_DI(1)(N + 3 * i + 2),
      b_i_2 => Tape_DI(2)(N + 3 * i + 2),
      b_i_3 => Tape_last_DI(3 * i + 2),
      and_helper => and_helper(3 * i + 1),
      msgs_0 => msgs_out(0)(3 * i + 1),
      msgs_1 => msgs_out(1)(3 * i + 1),
      msgs_2 => msgs_out(2)(3 * i + 1),
      msgs_3 => msgs_out(3)(3 * i + 1)
    );
    CA : sim_mpc_and
    port map(
      a => State_in_DI(3 * i + 2),
      a_i_0 => Tape_DI(0)(N + 3 * i + 2),
      a_i_1 => Tape_DI(1)(N + 3 * i + 2),
      a_i_2 => Tape_DI(2)(N + 3 * i + 2),
      a_i_3 => Tape_last_DI(3 * i + 2),
      b => State_in_DI(3 * i + 0),
      b_i_0 => Tape_DI(0)(N + 3 * i + 0),
      b_i_1 => Tape_DI(1)(N + 3 * i + 0),
      b_i_2 => Tape_DI(2)(N + 3 * i + 0),
      b_i_3 => Tape_last_DI(3 * i + 1),
      and_helper => and_helper(3 * i + 0),
      msgs_0 => msgs_out(0)(3 * i + 0),
      msgs_1 => msgs_out(1)(3 * i + 0),
      msgs_2 => msgs_out(2)(3 * i + 0),
      msgs_3 => msgs_out(3)(3 * i + 0)
    );
    Msgs : for j in 0 to (P - 1) generate
      Msgs_DO(j)(3 * i + 0) <= msgs_out(j)(3 * i + 0);
      Msgs_DO(j)(3 * i + 1) <= msgs_out(j)(3 * i + 1);
      Msgs_DO(j)(3 * i + 2) <= msgs_out(j)(3 * i + 2);
    end generate;


    State_out_DO(3 * i + 0) <= State_in_DI(3 * i + 0) xor ((msgs_out(0)(3 * i + 1) xor msgs_out(1)(3 * i + 1) xor msgs_out(2)(3 * i + 1) xor msgs_out(3)(3 * i + 1)) xor (State_in_DI(3 * i + 1) and State_in_DI(3 * i + 2)));
    State_out_DO(3 * i + 1) <= State_in_DI(3 * i + 0) xor State_in_DI(3 * i + 1) xor ((msgs_out(0)(3 * i + 0) xor msgs_out(1)(3 * i + 0) xor msgs_out(2)(3 * i + 0) xor msgs_out(3)(3 * i + 0)) xor (State_in_DI(3 * i + 2) and State_in_DI(3 * i + 0)));
    State_out_DO(3 * i + 2) <= State_in_DI(3 * i + 0) xor State_in_DI(3 * i + 1) xor State_in_DI(3 * i + 2) xor ((msgs_out(0)(3 * i + 2) xor msgs_out(1)(3 * i + 2) xor msgs_out(2)(3 * i + 2) xor msgs_out(3)(3 * i + 2)) xor (State_in_DI(3 * i + 0) and State_in_DI(3 * i + 1)));
  end generate;

end behavorial;
