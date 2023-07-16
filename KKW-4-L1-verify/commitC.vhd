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
  type states is (init, absorb);
  signal State_DN, State_DP : states;
  signal Init_in, Start_in, Finish_out : std_logic;
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
      signal Squeeze_SI : in std_logic;
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
      Absorb_SI  => Start_in,
      Squeeze_SI => '0',
      Init_SI    => Init_in,
      Hash_DO    => Hash_out(i),
      Valid_SO   => open
    );
  end generate;

  K_last : keccak
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => DIGEST_L
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K_in(P - 1),
    Absorb_SI  => Start_in,
    Squeeze_SI => '0',
    Init_SI    => Init_in,
    Hash_DO    => Hash_out(P - 1),
    Valid_SO   => Finish_out
  );


  
  Commit_DO <= Hash_out;
  Finish_SO <= Finish_out;
  -- output logic
  process(State_DP, Start_SI, Salt_DI, Round_DI, Seed_DI, Aux_DI)
  begin
    --default
    Start_in <= '0';
    Init_in <= '0';
    K_in <= (others => (others => '0'));

    case State_DP is
      when init =>
        if Start_SI = '1' then
          Init_in <= '1';
        end if;
      when absorb =>
        for i in 0 to P - 2 loop
          K_in(i)(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
          K_in(i)(KECCAK_R - 8 - 1 downto KECCAK_R - 8 - PICNIC_S - SALT_LEN - 32 - 8) <= Seed_DI(i) & Salt_DI & std_logic_vector(to_unsigned(Round_DI - 2, 16)) & std_logic_vector(to_unsigned(i, 16)) & KECCAK_PAD;
          K_in(i)(7) <= '1';
        end loop;
        K_in(P - 1)(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K_in(P - 1)(KECCAK_R - 8 - 1 downto KECCAK_R - 8 - PICNIC_S - R * N - SALT_LEN - 32 - 8) <= Seed_DI(P - 1) & Aux_DI & Salt_DI & std_logic_vector(to_unsigned(Round_DI - 2, 16)) & std_logic_vector(to_unsigned(2, 16)) & KECCAK_PAD;
        K_in(P - 1)(7) <= '1';
        Start_in <= '1';
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when init =>
        if Start_SI = '1' then
          State_DN <= absorb;
        end if;
      when absorb =>
        State_DN <= init;
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