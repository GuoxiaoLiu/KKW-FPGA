library work;
use work.lowmc_pkg.all;
library ieee;
use ieee.std_logic_1164.all;

entity lowmc_mpc is
  port(
    -- Clock and Reset
    signal Clk_CI   : in std_logic;
    signal Rst_RI   : in std_logic;
    -- Input signals
    signal Plain_DI  : in std_logic_vector(N - 1 downto 0);
    signal MK_DI     : in std_logic_vector(N - 1 downto 0);
    -- signal Aux_DI    : in std_logic_vector(R * N - 1 downto 0);
    signal Tape_DI   : in R_N_2_ARR;
    signal Tape_last_DI   : in std_logic_vector(R * N - 1 downto 0);
    signal Aux_DI   : in std_logic_vector(R * N - 1 downto 0);
    signal Aux_SI    : in std_logic;
    signal Sim_SI    : in std_logic;
    -- Output signals
    signal Finish_SO : out std_logic;
    signal Input_out : out std_logic_vector(N - 1 downto 0);
    signal Aux_out   : out std_logic_vector(R * N - 1 downto 0);
    signal Cipher_DO : out std_logic_vector(N - 1 downto 0);
    signal Msgs_DO   : out R_N_ARR
  );
end entity;

architecture behavorial of lowmc_mpc is

  type states is (init, aux_round, sim_round);

  signal State_DN, State_DP : states;
  signal Data_sim_DN, Data_sim_DP : std_logic_vector(N - 1 downto 0);
  signal Data_aux_DN, Data_aux_DP : std_logic_vector(N - 1 downto 0);
  signal Data_Round_sim_out, Data_Round_aux_out : std_logic_vector(N - 1 downto 0);

  signal K0_sim_out, K0_aux_out : std_logic_vector(N - 1 downto 0);
  signal Key_in, Key_out, Aux_key_in, Aux_key_out : std_logic_vector(N - 1 downto 0);
  signal Input_DN, Input_DP : std_logic_vector(N - 1 downto 0);
  signal Round_DN, Round_DP : integer range 0 to R - 1;
  signal Round_in : integer range 0 to R - 1;


  signal Aux_DN, Aux_DP : std_logic_vector(R * N - 1 downto 0);
  signal Key_0_aux_in : std_logic_vector(N - 1 downto 0);
  signal Tape_in : N_2_ARR;
  signal Tape_last_in : std_logic_vector(N - 1 downto 0);
  signal aux : std_logic_vector(N - 1 downto 0);
  signal aux_in : std_logic_vector(N - 1 downto 0);
  signal msgs_out : N_ARR;
  signal Sim_sbox_out, Aux_sbox_out : std_logic_vector(N - 1 downto 0);
  signal Msgs_DN, Msgs_DP : R_N_ARR;
  signal Sbox_aux_in : std_logic_vector(N - 1 downto 0);

  

  component lowmc_matrix_k0_i
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_matrix_k0
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_matrix_k
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      signal Round_DI : in integer range 0 to R - 1;
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;


  component lowmc_matrix_lik
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      signal Round_DI : in integer range 0 to R - 1;
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_matrix_li
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      signal Round_DI : in integer range 0 to R - 1;
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_aux_mpc_sbox is
    port(
      -- Input signals
      signal State_out_DI  : in std_logic_vector(N - 1 downto 0);
      signal Tape_DI       : in N_2_ARR;
      signal Tape_last_DI  : in std_logic_vector(N - 1 downto 0);
      -- Output signals
      signal Aux_DO        : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_sim_mpc_sbox is
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
  end component;

  component lowmc_matrix_l
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      signal Round_DI : in integer range 0 to R - 1;
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

begin

  key0_i : lowmc_matrix_k0_i
  port map(
    Data_DI => Key_0_aux_in,
    Data_DO => K0_aux_out
  );

  rdk : lowmc_matrix_k
  port map(
    Data_DI => Key_in,
    Round_DI => Round_DP,
    Data_DO => Key_out
  );

  lik : lowmc_matrix_lik
  port map(
    Data_DI => Aux_key_in,
    Round_DI => Round_DP,
    Data_DO => Aux_key_out
  );


  Li : lowmc_matrix_li
  port map(
    Data_DI => Data_aux_DP,
    Round_DI => Round_in,
    Data_DO => Data_Round_aux_out
  );
  
  AUX_MPC_SBOX : lowmc_aux_mpc_sbox
  port map (
    State_out_DI => Sbox_aux_in,
    Tape_DI => Tape_in,
    Tape_last_DI => Tape_last_in,
    Aux_DO => aux
  );

  rdk0 : lowmc_matrix_k0
  port map(
    Data_DI => MK_DI,
    Data_DO => K0_sim_out
  );

  SIM_MPC_SBOX : lowmc_sim_mpc_sbox
  port map (
    State_in_DI => Data_sim_DP,
    Aux_DI => aux_in,
    Tape_DI => Tape_in,
    Tape_last_DI => Tape_last_in,
    State_out_DO => Sim_sbox_out,
    Msgs_DO => Msgs_out
  );

  L : lowmc_matrix_l
  port map(
    Data_DI => Sim_sbox_out,
    Round_DI => Round_in,
    Data_DO => Data_Round_sim_out
  );

  
  -- output logic
  process (State_DP, Aux_SI, Aux_key_out, Sim_SI, Aux_DI, Plain_DI, MK_DI, Round_DP, Data_aux_DP, Tape_last_DI, Tape_DI, K0_sim_out, aux, Sim_sbox_out, Msgs_out, Aux_DP, Msgs_DP, Data_Round_sim_out, Data_Round_aux_out, Data_sim_DP, Key_out, K0_aux_out, Input_DP)
    variable tmp0 : std_logic_vector(N - 1 downto 0);
    variable tmp1 : std_logic_vector(N - 1 downto 0);
  begin
    -- default
    Round_DN <= Round_DP;
    Data_sim_DN <= Data_sim_DP;
    Data_aux_DN <= Data_aux_DP;
    Aux_DN <= Aux_DP;
    Msgs_DN <= Msgs_DP;
    Input_DN <= Input_DP;

    Finish_SO <= '0';
    Round_in <= 0;
    Key_in <= (others => '0');
    Aux_key_in <= (others => '0');
    Tape_in <= (others => (others => '0'));
    Sbox_aux_in <= (others => '0');
    Tape_last_in <= (others => '0');
    aux_in <= (others => '0');
    
    tmp0 := (others => '0');
    for i in 0 to P - 2 loop
      tmp0 := tmp0 xor Tape_DI(i)(2 * R * N - 1 downto 2 * R * N - N);
    end loop;
    Key_0_aux_in <= tmp0 xor Tape_last_DI(R * N - 1 downto R * N - N);

    for i in 0 to (P - 1) loop
      Msgs_DO(i) <= Msgs_DP(i);
    end loop;    
    Cipher_DO <= Data_sim_DP;
    Aux_out <= Aux_DP;
    Input_out <= Input_DP;
    
    -- output
    case State_DP is
      when init =>
        if Aux_SI = '1' then
          Round_DN <= R - 1;
          Input_DN <= K0_aux_out;
          Aux_DN <= (others => '0');
          Data_aux_DN <= (others => '0');
        elsif Sim_SI = '1' then
          Round_DN <= 0;
          Data_sim_DN <= K0_sim_out xor Plain_DI;
          Msgs_DN <= (others => (others => '0'));
        end if;
        Finish_SO <= '1';
        Cipher_DO <= Data_sim_DP;
      when sim_round =>
        if Round_DP < R - 1 then
          Round_DN <= Round_DP + 1;
        end if;
        for i in 0 to (P - 2) loop
          Tape_in(i) <= Tape_DI(i)(2 * R * N - 2 * (Round_DP) * N - 1 downto 2 * R * N - 2 * (Round_DP + 1) * N);
        end loop;
        Tape_last_in <= Tape_last_DI(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N);
        aux_in <= Aux_DI(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N);
        for i in 0 to (P - 1) loop
          Msgs_DN(i)(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N) <= Msgs_out(i);
        end loop;
        Round_in <= Round_DP;
        Key_in <= MK_DI;
        Data_sim_DN <= Data_Round_sim_out xor RCMATRIX(Round_DP) xor Key_out;
      when aux_round =>
        if Round_DP > 0 then
          Round_DN <= Round_DP - 1;
        end if;
        Round_in <= Round_DP;
        Aux_key_in <= Input_DP;
        Sbox_aux_in <= Aux_key_out xor Data_Round_aux_out;
        tmp1 := (others => '0');
        for i in 0 to P - 2 loop
          tmp1 := tmp1 xor Tape_DI(i)(2 * R * N - 2 * (Round_DP) * N - 1 downto 2 * R * N - 2 * (Round_DP + 1) * N + N);
        end loop;
        Data_aux_DN <= tmp1 xor Tape_last_DI(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N);    
        -- Data_aux_DN <= Tape_DI(0)(2 * R * N - 2 * (Round_DP) * N - 1 downto 2 * R * N - 2 * (Round_DP + 1) * N + N) xor Tape_DI(1)(2 * R * N - 2 * (Round_DP) * N - 1 downto 2 * R * N - 2 * (Round_DP + 1) * N + N) xor Tape_DI(2)(2 * R * N - 2 * (Round_DP) * N - 1 downto 2 * R * N - 2 * (Round_DP + 1) * N + N) xor Tape_last_DI(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N);
        for i in 0 to (P - 2) loop
          Tape_in(i) <= Tape_DI(i)(2 * R * N - 2 * (Round_DP) * N - 1 downto 2 * R * N - 2 * (Round_DP + 1) * N);
        end loop;
        Tape_last_in <= Tape_last_DI(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N);
        Aux_DN(R * N - (Round_DP) * N - 1 downto R * N - (Round_DP + 1) * N) <= aux;
    end case;
  end process;

  -- next state logic
  process (State_DP, Aux_SI, Sim_SI, Round_DP)
  begin
    --default
    State_DN <= State_DP;
    case State_DP is
      when init =>
        if Aux_SI = '1' then
          State_DN <= aux_round;
        end if;
        if Sim_SI = '1' then
          State_DN <= sim_round;
        end if;
      when aux_round =>
        if Round_DP = 0 then
          State_DN <= init;
        end if;
      when sim_round =>
        if Round_DP = R - 1 then
          State_DN <= init;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        Round_DP   <= 0;
        Data_sim_DP <= (others => '0');
        Data_aux_DP <= (others => '0');
        Input_DP <= (others => '0');
        Aux_DP <= (others => '0');
        Msgs_DP <= (others => (others => '0'));
        State_DP   <= init;
      else
        Round_DP   <= Round_DN;
        State_DP   <= State_DN;
        Data_sim_DP <= Data_sim_DN;
        Data_aux_DP <= Data_aux_DN;
        Input_DP <= Input_DN;
        Aux_DP    <= Aux_DN;
        Msgs_DP    <= Msgs_DN;
      end if;
    end if;
  end process;

end behavorial;