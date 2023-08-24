library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity commitH is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Next_SI     : in std_logic;
    signal Dig_DI      : in DIGE_ARR;
    -- Output signals
    signal Finish_SO   : out std_logic;
    signal Commit_DO   : out std_logic_vector(DIGEST_L - 1 downto 0)
  );
end entity;

architecture behavorial of commitH is
  type states is (init, Ch_absorb0);
  signal State_DN, State_DP : states;
  signal Init_in, Start_in, Finish_out : std_logic;
  signal K0_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash0_out : std_logic_vector(DIGEST_L - 1 downto 0);

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

begin

  K0 : keccak
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => DIGEST_L
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K0_in,
    Absorb_SI  => Start_in,
    Init_SI    => Init_in,
    Hash_DO    => Hash0_out,
    Valid_SO   => Finish_out
  );

  Commit_DO <= Hash0_out;
  Finish_SO <= Finish_out;
  
  -- output logic
  process(State_DP, Dig_DI, Start_SI)
  begin
    --default
    Start_in <= '0';
    Init_in <= '0';
    K0_in <= (others => '0');
    

    case State_DP is
      when init =>
        if Start_SI = '1' then
          Init_in <= '1';
        end if;
      when Ch_absorb0 =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K0_in(KECCAK_R - 8 - 1 downto KECCAK_R - 8 - P * DIGEST_L) <= Dig_DI(0) & Dig_DI(1) & Dig_DI(2) & Dig_DI(3);
        K0_in(7) <= '1';
        Start_in <= '1';
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Next_SI)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when init =>
        if Start_SI = '1' or Next_SI = '1' then
          State_DN <= Ch_absorb0;
        end if;
      when Ch_absorb0 =>
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