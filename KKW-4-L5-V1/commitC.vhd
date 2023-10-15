library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity commitC is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Salt_DI     : in std_logic_vector(SALT_LEN - 1 downto 0);
    signal Seed_DI     : in SEED_ARR;
    signal Aux_DI      : in std_logic_vector(R * N - 1 downto 0);
    signal Round_DI    : in integer range 0 to 4 * T + 10;
    
    -- Output signals
    signal Finish_SO   : out std_logic;
    signal Commit_DO : out DIGE_ARR
  );
end entity;

architecture behavorial of commitC is
  type states is (init, absorb0, absorb1);
  signal State_DN, State_DP : states;
  signal Init_in, Start0_in, Start1_in, Finish0_out, Finish1_out : std_logic;
  type K_ARR is array (0 to P - 1) of std_logic_vector(KECCAK_R - 1 downto 0);
  signal K_in : K_ARR;
  signal Hash_out : DIGE_ARR;

  component keccak
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

  KECCAK_GEN : for i in 0 to P - 2 generate
    K0 : keccak
    generic map(
      GEN_R => KECCAK_R,
      OUT_BIT => DIGEST_L
    )
    port map (
      Clk_CI     => Clk_CI,
      Rst_RI     => Rst_RI,
      Block_DI   => K_in(i),
      Absorb_SI  => Start0_in,
      Init_SI    => Init_in,
      Hash_DO    => Hash_out(i),
      Valid_SO   => Finish0_out
    );
  end generate;

  K_last : keccak2
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => DIGEST_L
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K_in(P - 1),
    Absorb_SI  => Start1_in,
    Init_SI    => Init_in,
    Hash_DO    => Hash_out(P - 1),
    Valid_SO   => Finish1_out
  );


  

  -- output logic
  process(State_DP, Start_SI, Salt_DI, Round_DI, Seed_DI, Aux_DI, Finish1_out, Finish0_out, Hash_out)
  begin
    --default
    Start0_in <= '0';
    Start1_in <= '0';
    Init_in <= '0';
    K_in <= (others => (others => '0'));
    Finish_SO <= '0';
    Commit_DO <= (others => (others => '0'));

    case State_DP is
      when init =>
        if Start_SI = '1' then
          Init_in <= '1';
        end if;
        if Finish1_out = '1' and Finish0_out = '1' then
          Finish_SO <= '1';
          Commit_DO <= Hash_out;
        end if;
      when absorb0 =>
        for i in 0 to P - 2 loop
          K_in(i)(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
          K_in(i)(KECCAK_R - 8 - 1 downto KECCAK_R - 8 - PICNIC_S - SALT_LEN - 32 - 8) <= Seed_DI(i) & Salt_DI & std_logic_vector(to_unsigned(Round_DI - 2, 16)) & std_logic_vector(to_unsigned(i, 16)) & KECCAK_PAD;
          K_in(i)(7) <= '1';
        end loop;
        K_in(P - 1)(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K_in(P - 1)(KECCAK_R - 8 - 1 downto 0) <= Seed_DI(P - 1) & Aux_DI(R * N - 1 downto R * N - (KECCAK_R - 8 - PICNIC_S));
        Start0_in <= '1';
        Start1_in <= '1';
      when absorb1 =>
        if Finish1_out = '1' then
          K_in(P - 1)(KECCAK_R - 1 downto KECCAK_R - (R * N - (KECCAK_R - 8 - PICNIC_S) + SALT_LEN + 40)) <= Aux_DI(R * N - (KECCAK_R - 8 - PICNIC_S) - 1 downto 0) & Salt_DI & std_logic_vector(to_unsigned(Round_DI - 2, 16)) & std_logic_vector(to_unsigned(2, 16)) & KECCAK_PAD;
          K_in(P - 1)(7) <= '1';
          Start1_in <= '1';
        end if;
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Finish1_out)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when init =>
        if Start_SI = '1' then
          State_DN <= absorb0;
        end if;
      when absorb0 =>
        State_DN <= absorb1;
      when absorb1 =>
        if Finish1_out = '1' then
          State_DN <= init;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        State_DP   <= init;
      else
        State_DP   <= State_DN;
      end if;
    end if;
  end process;

end behavorial;