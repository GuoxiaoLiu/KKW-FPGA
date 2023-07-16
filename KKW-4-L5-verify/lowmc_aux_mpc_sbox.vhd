library work;
use work.lowmc_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
entity lowmc_aux_mpc_sbox is
  port(
    -- Input signals
    signal State_out_DI  : in std_logic_vector(N - 1 downto 0);
    signal Tape_DI       : in N_2_ARR;
    signal Tape_last_DI  : in std_logic_vector(N - 1 downto 0);
    -- Output signals
    signal Aux_DO        : out std_logic_vector(N - 1 downto 0)
  );
end entity;

architecture behavorial of lowmc_aux_mpc_sbox is
  signal aux_out : std_logic_vector(N - 1 downto 0);
  signal fresh_output_mask_in : std_logic_vector(N - 1 downto 0);

  signal and_helper : std_logic_vector(N - 1 downto 0);
  component aux_mpc_and is
    port(
      -- Input signals
      signal fresh_output_mask : in std_logic;
      signal and_helper : std_logic;
      signal a_i_0 : in std_logic;
      signal a_i_1 : in std_logic;
      signal a_i_2 : in std_logic;
      signal b_i_0 : in std_logic;
      signal b_i_1 : in std_logic;
      signal b_i_2 : in std_logic;
      -- Output signals
      signal aux : out std_logic
    );
  end component;
begin

  SBOX_GEN : for i in 0 to S - 1 generate
    and_helper(3 * i + 0) <= Tape_DI(P - 2 - (0))(3 * i + 0) xor Tape_DI(P - 2 - (1))(3 * i + 0);
    and_helper(3 * i + 1) <= Tape_DI(P - 2 - (0))(3 * i + 1) xor Tape_DI(P - 2 - (1))(3 * i + 1);
    and_helper(3 * i + 2) <= Tape_DI(P - 2 - (0))(3 * i + 2) xor Tape_DI(P - 2 - (1))(3 * i + 2);
    -- ab
    fresh_output_mask_in(3 * i + 2) <= State_out_DI(3 * i + 2) xor Tape_DI(0)(N + 3 * i + 2) xor Tape_DI(1)(N + 3 * i + 2) xor Tape_last_DI(3 * i + 2) xor Tape_DI(0)(N + 3 * i + 1) xor Tape_DI(1)(N + 3 * i + 1) xor Tape_last_DI(3 * i + 1) xor Tape_DI(0)(N + 3 * i + 0) xor Tape_DI(1)(N + 3 * i + 0) xor Tape_last_DI(3 * i + 0);
    -- bc
    fresh_output_mask_in(3 * i + 1) <= State_out_DI(3 * i + 0) xor Tape_DI(0)(N + 3 * i + 0) xor Tape_DI(1)(N + 3 * i + 0) xor Tape_last_DI(3 * i + 0);
    -- ca
    fresh_output_mask_in(3 * i + 0) <= State_out_DI(3 * i + 1) xor Tape_DI(0)(N + 3 * i + 1) xor Tape_DI(1)(N + 3 * i + 1) xor Tape_last_DI(3 * i + 1) xor Tape_DI(0)(N + 3 * i + 0) xor Tape_DI(1)(N + 3 * i + 0) xor Tape_last_DI(3 * i + 0);
    AB : aux_mpc_and
    port map(
      fresh_output_mask => fresh_output_mask_in(3 * i + 2),
      a_i_0 => Tape_DI(0)(N + 3 * i + 0),
      a_i_1 => Tape_DI(1)(N + 3 * i + 0),
      a_i_2 => Tape_last_DI(3 * i + 0),
      b_i_0 => Tape_DI(0)(N + 3 * i + 1),
      b_i_1 => Tape_DI(1)(N + 3 * i + 1),
      b_i_2 => Tape_last_DI(3 * i + 1),
      and_helper => and_helper(3 * i + 0),
      aux => aux_out(3 * i + 2)
    );
    BC : aux_mpc_and
    port map(
      fresh_output_mask => fresh_output_mask_in(3 * i + 1),
      a_i_0 => Tape_DI(0)(N + 3 * i + 1),
      a_i_1 => Tape_DI(1)(N + 3 * i + 1),
      a_i_2 => Tape_last_DI(3 * i + 1),
      b_i_0 => Tape_DI(0)(N + 3 * i + 2),
      b_i_1 => Tape_DI(1)(N + 3 * i + 2),
      b_i_2 => Tape_last_DI(3 * i + 2),
      and_helper => and_helper(3 * i + 1),
      aux => aux_out(3 * i + 1)
    );
    CA : aux_mpc_and
    port map(
      fresh_output_mask => fresh_output_mask_in(3 * i + 0),
      a_i_0 => Tape_DI(0)(N + 3 * i + 2),
      a_i_1 => Tape_DI(1)(N + 3 * i + 2),
      a_i_2 => Tape_last_DI(3 * i + 2),
      b_i_0 => Tape_DI(0)(N + 3 * i + 0),
      b_i_1 => Tape_DI(1)(N + 3 * i + 0),
      b_i_2 => Tape_last_DI(3 * i + 0),
      and_helper => and_helper(3 * i + 2),
      aux => aux_out(3 * i + 0)
    );

    Aux_DO(3 * i + 0) <= aux_out(3 * i + 0);
    Aux_DO(3 * i + 1) <= aux_out(3 * i + 1);
    Aux_DO(3 * i + 2) <= aux_out(3 * i + 2);
  end generate;

end behavorial;
