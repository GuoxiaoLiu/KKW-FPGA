library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tape is
  port(
    -- Clock and Reset
    signal Clk_CI    : in std_logic;
    signal Rst_RI    : in std_logic;
    -- Input signals
    signal Start_SI  : in std_logic;
    signal Seed_DI : in SEED_ARR;
    signal Salt_DI   : in std_logic_vector(SALT_LEN - 1 downto 0);
    signal Rd_Ad_DI  : in std_logic_vector(16 - 1 downto 0);
    -- Output signals
    signal Finish_SO : out std_logic;
    signal Tape_DO : out R_N_2_ARR;
    signal Tape_last_DO : out std_logic_vector(R * N - 1 downto 0)
  );
end entity;

architecture behavorial of tape is
  type states is (init, absorb);
  signal State_DN, State_DP : states;
  signal Finish_out : std_logic;
  signal Init_in, Start_in : std_logic;
  type K_ARR is array (0 to P - 1) of std_logic_vector(KECCAK_R - 1 downto 0);
  signal K_in : K_ARR;
  signal Hash_out : R_N_2_ARR;
  signal Hash_last_out : std_logic_vector(R * N - 1 downto 0);
  

  component keccak3
    generic(
      constant GEN_R : integer := 1344;
      constant OUT_BIT : integer := 256
    );
    port(
      -- Clock and Reset
      signal Clk_CI   : in std_logic;
      signal Rst_RI  : in std_logic;
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
    Ki : keccak3
    generic map(
      GEN_R => KECCAK_R,
      OUT_BIT => 2 * R * N
    )
    port map (
      Clk_CI     => Clk_CI,
      Rst_RI     => Rst_RI,
      Block_DI   => K_in(i),
      Absorb_SI  => Start_in,
      Init_SI    => Init_in,
      Hash_DO    => Hash_out(i),
      Valid_SO   => open
    );
  end generate;

    

    K2 : keccak3
    generic map(
      GEN_R => KECCAK_R,
      OUT_BIT => R * N
    )
    port map (
      Clk_CI     => Clk_CI,
      Rst_RI     => Rst_RI,
      Block_DI   => K_in(P - 1),
      Absorb_SI  => Start_in,
      Init_SI    => Init_in,
      Hash_DO    => Hash_last_out,
      Valid_SO   => Finish_out
    );

  Tape_DO <= Hash_out;
  Tape_last_DO <= Hash_last_out;
  Finish_So <= Finish_out;
  -- output logic
  process (State_DP, Start_SI, Seed_DI, Finish_out, Hash_out, Hash_last_out, Salt_DI, Rd_Ad_DI)
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
        for i in 0 to P - 1 loop
          K_in(i)(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
          K_in(i)(KECCAK_R - 8 - 1 downto KECCAK_R - PICNIC_S - SALT_LEN - 16 - 16 - 16) <= Seed_DI(i) & Salt_DI & Rd_Ad_DI & std_logic_vector(to_unsigned(i, 16)) & KECCAK_PAD;
          K_in(i)(7) <= '1';
        end loop;
        Start_in <= '1';
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Finish_out)
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
