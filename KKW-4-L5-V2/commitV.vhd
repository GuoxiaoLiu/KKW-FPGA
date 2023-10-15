library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity commitV is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Inputs_DI   : in std_logic_vector(N - 1 downto 0);
    signal Ms_DI       : in R_N_ARR;
    -- Output signals
    signal Finish_SO   : out std_logic;
    signal Commit_DO : out std_logic_vector(DIGEST_L - 1 downto 0)
  );
end entity;

architecture behavorial of commitV is
  type states is (init0_Cv1_absorb2, Cv0_absorb0, Cv0_absorb1_Cv1_absorb3, Cv0_absorb2_init1, Cv1_absorb0, Cv0_absorb3_Cv1_absorb1);
  signal State_DN, State_DP : states;
  signal Init_in, Start_in, Finish_out : std_logic_vector(1 downto 0);
  signal K0_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash0_out : std_logic_vector(DIGEST_L - 1 downto 0);
  signal K1_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash1_out : std_logic_vector(DIGEST_L - 1 downto 0);
  type MSGS_COMMIT_V_ARR is array (0 to 1) of R_N_ARR;
  
  signal Msgs_DN, Msgs_DP : MSGS_COMMIT_V_ARR;

  component keccak2
    generic(
      constant GEN_R : integer := 1344;
      constant OUT_BIT : integer := 256
    );
    port(
      -- Clock and Reset
      signal Clk_CI   : in std_logic;
      signal Rst_RI   : in std_logic;
      -- Input signals
      signal Block_DI   : in std_logic_vector(GEN_R - 1 downto 0);
      signal Absorb_SI  : in std_logic;
      signal Init_SI    : in std_logic;
      -- Output signals
      signal Hash_DO  : out std_logic_vector(OUT_BIT - 1 downto 0);
      signal Valid_SO : out std_logic
    );
  end component;

begin

  K0 : keccak2
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => DIGEST_L
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K0_in,
    Absorb_SI  => Start_in(0),
    Init_SI    => Init_in(0),
    Hash_DO    => Hash0_out,
    Valid_SO   => Finish_out(0)
  );

  K1 : keccak2
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => DIGEST_L
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K1_in,
    Absorb_SI  => Start_in(1),
    Init_SI    => Init_in(1),
    Hash_DO    => Hash1_out,
    Valid_SO   => Finish_out(1)
  );
  

  
  
  -- output logic
  process(State_DP, Inputs_DI, Ms_DI, Start_SI, Finish_out, Hash0_out, Hash1_out, Msgs_DP)
  begin
    --default
    Start_in <= (others => '0');
    Init_in <= (others => '0');
    K0_in <= (others => '0');
    K1_in <= (others => '0');
    Finish_SO <= '0';
    Commit_DO <= (others => '0');

    Msgs_DN <= Msgs_DP;

    case State_DP is
      when init0_Cv1_absorb2 =>
        if Start_SI = '1' then
          Init_in(0) <= '1';
          Msgs_DN(0) <= Ms_DI;
        end if;
        if Finish_out(0) = '1' then
          Finish_SO <= '1';
          Commit_DO <= Hash0_out;
        end if;

        if Finish_out(1) = '1' then
          K1_in(KECCAK_R - 1 downto 0) <= Msgs_DP(1)(1)(R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))) - 1 downto 0) & Msgs_DP(1)(2)(R * N - 1 downto R * N - (KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))))));
          Start_in(1) <= '1';
        end if;
      when Cv0_absorb0 =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K0_in(KECCAK_R - 8 - 1 downto 0) <= Inputs_DI & Msgs_DP(0)(0)(R * N - 1 downto R * N - (KECCAK_R - 8 - N));
        Start_in(0) <= '1';
      when Cv0_absorb1_Cv1_absorb3 =>
        if Finish_out(0) = '1' and Finish_out(1) = '1' then
          K0_in(KECCAK_R - 1 downto 0) <= Msgs_DP(0)(0)(R * N - (KECCAK_R - 8 - N) - 1 downto 0) & Msgs_DP(0)(1)(R * N - 1 downto R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))));
          Start_in(0) <= '1';

          K1_in(KECCAK_R - 1 downto KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N)))))) - R * N - 8) <= Msgs_DP(1)(2)(R * N - (KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))))) - 1 downto 0) & Msgs_DP(1)(3)(R * N - 1 downto 0) & KECCAK_PAD;
          K1_in(7) <= '1';
          Start_in(1) <= '1';
        end if;
      when Cv0_absorb2_init1 =>
        if Finish_out(0) = '1' and Start_SI = '1' then
          K0_in(KECCAK_R - 1 downto 0) <= Msgs_DP(0)(1)(R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))) - 1 downto 0) & Msgs_DP(0)(2)(R * N - 1 downto R * N - (KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))))));
          Start_in(0) <= '1';
          
          Init_in(1) <= '1';
          Msgs_DN(1) <= Ms_DI;
        end if;

        if Finish_out(1) = '1' then
          Finish_SO <= '1';
          Commit_DO <= Hash1_out;
        end if;
      when Cv1_absorb0 =>
        K1_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K1_in(KECCAK_R - 8 - 1 downto 0) <= Inputs_DI & Msgs_DP(1)(0)(R * N - 1 downto R * N - (KECCAK_R - 8 - N));
        Start_in(1) <= '1';
      when Cv0_absorb3_Cv1_absorb1 =>
        if Finish_out(0) = '1' and Finish_out(1) = '1' then
          K0_in(KECCAK_R - 1 downto KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N)))))) - R * N - 8) <= Msgs_DP(0)(2)(R * N - (KECCAK_R - (R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))))) - 1 downto 0) & Msgs_DP(0)(3)(R * N - 1 downto 0) & KECCAK_PAD;
          K0_in(7) <= '1';
          Start_in(0) <= '1';

          K1_in(KECCAK_R - 1 downto 0) <= Msgs_DP(1)(0)(R * N - (KECCAK_R - 8 - N) - 1 downto 0) & Msgs_DP(1)(1)(R * N - 1 downto R * N - (KECCAK_R - (R * N - (KECCAK_R - 8 - N))));
          Start_in(1) <= '1';
        end if;
        
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Finish_out)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when init0_Cv1_absorb2 =>
        if Start_SI = '1' then
          State_DN <= Cv0_absorb0;
        end if;
      when Cv0_absorb0 =>
        State_DN <= Cv0_absorb1_Cv1_absorb3;
      when Cv0_absorb1_Cv1_absorb3 =>
        if Finish_out = "11" then
          State_DN <= Cv0_absorb2_init1;
        end if;
      when Cv0_absorb2_init1 =>
        if Start_SI = '1' then
          State_DN <= Cv1_absorb0;
        end if;
      when Cv1_absorb0 =>
        State_DN <= Cv0_absorb3_Cv1_absorb1;
      when Cv0_absorb3_Cv1_absorb1 =>
        if Finish_out = "11" then
          State_DN <= init0_Cv1_absorb2;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        State_DP   <= init0_Cv1_absorb2;
        Msgs_DP <= (others => (others => (others => '0')));
      else
        State_DP   <= State_DN;
        Msgs_DP <= Msgs_DN;
      end if;
    end if;
  end process;

end behavorial;