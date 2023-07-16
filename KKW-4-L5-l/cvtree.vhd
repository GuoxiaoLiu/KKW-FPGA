library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;
use work.bram_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cvtree is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Next_SI     : in std_logic;
    signal Salt_DI     : in std_logic_vector(SALT_LEN - 1 downto 0);
    signal Cv_Ad_DI    : in integer range 0 to 4 * T + 10;
    
    signal Dig0_DI     : in std_logic_vector(DIGEST_L - 1 downto 0);
    signal Dig1_DI     : in std_logic_vector(DIGEST_L - 1 downto 0);
    -- Output signals
    signal Ready_SO    : out std_logic;
    signal Dig_DO      : out std_logic_vector(DIGEST_L - 1 downto 0)
  );
end entity;

architecture behavorial of cvtree is

  signal cv_addra, cv_addrb : std_logic_vector(CV_ADDR_WIDTH - 1 downto 0);
  signal cv_wea, cv_web : std_logic;
  signal cv_dina, cv_dinb : std_logic_vector(CV_DATA_WIDTH - 1 downto 0);
  signal cv_douta, cv_doutb : std_logic_vector(CV_DATA_WIDTH - 1 downto 0);

  type states is (
    init, absorb_start, absorb, dig_out,
    cv_init, cv_read0, cv_read1, cv_absorb0, cv_absorb1, cv_out
  );
  signal State_DN, State_DP : states;
  signal Init0_in, Start0_in, Finish0_out : std_logic;
  signal K0_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash0_out : std_logic_vector(PICNIC_S * 2 - 1 downto 0);
  signal Count_DN, Count_DP : integer range 0 to 1023;
  signal Count_i_DN, Count_i_DP : integer range 0 to T;
  signal Count_t_DN, Count_t_DP : integer range 0 to 511 + T;
  signal Dig_DN, Dig_DP : std_logic_vector(DIGEST_L - 1 downto 0);

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
    signal Squeeze_SI : in std_logic;
    signal Init_SI    : in std_logic;
    -- Output signals
    signal Hash_DO  : out std_logic_vector(OUT_BIT - 1 downto 0);
    signal Valid_SO : out std_logic
  );
  end component;
  
  component xilinx_TDP_RAM is
    generic(
      ADDR_WIDTH : integer := 32;
      DATA_WIDTH : integer := 64;
      ENTRIES    : integer := 32  -- number of entries  (should be a power of 2)
      );
    port(
      clk : in std_logic;  -- clock

      addra : in std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Port A Address bus, width determined from RAM_DEPTH
      addrb : in std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Port B Address bus, width determined from RAM_DEPTH
      dina  : in std_logic_vector(DATA_WIDTH-1 downto 0);  -- Port A RAM input data
      dinb  : in std_logic_vector(DATA_WIDTH-1 downto 0);  -- Port B RAM input data

      wea : in std_logic;  -- Port A Write enable
      web : in std_logic;  -- Port B Write enable
      ena : in std_logic;  -- Port A RAM Enable, for additional power savings, disable port when not in use
      enb : in std_logic;  -- Port B RAM Enable, for additional power savings, disable port when not in use

      douta : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- Port A RAM output data
      doutb : out std_logic_vector(DATA_WIDTH-1 downto 0)   -- Port B RAM output data
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
    Absorb_SI  => Start0_in,
    Squeeze_SI => '0',
    Init_SI    => Init0_in,
    Hash_DO    => Hash0_out,
    Valid_SO   => Finish0_out
  );


  CV_RAM : xilinx_TDP_RAM
  generic map(
    ADDR_WIDTH => CV_ADDR_WIDTH,
    DATA_WIDTH => CV_DATA_WIDTH,
    ENTRIES => CV_ENTRIES
  )
  port map(
    clk => Clk_CI,
    addra => cv_addra,
    addrb => cv_addrb,
    dina => cv_dina,
    dinb => cv_dinb,
    wea => cv_wea,
    web => cv_web,
    ena => '1',
    enb => '1',
    douta => cv_douta,
    doutb => cv_doutb
  );

  
  -- output logic
  process (State_DP, Start_SI, Next_SI, Finish0_out, Hash0_out, Dig0_DI, Dig1_DI, Salt_DI, Count_DP, Count_i_DP, Count_t_DP, Cv_douta, Cv_doutb, Cv_Ad_DI, Dig_DP)
  begin
    --default
    Start0_in <= '0';
    Init0_in <= '0';
    Ready_SO <= '0';
    K0_in <= (others => '0');
    Dig_DO <= (others => '0');
    Count_DN <= Count_DP;
    Count_i_DN <= Count_i_DP;
    Count_t_DN <= Count_t_DP;
    Dig_DN <= Dig_DP;
    Cv_addra <= (others => '0');
    Cv_addrb <= (others => '0');
    Cv_dina <= (others => '0');
    Cv_dinb <= (others => '0');
    Cv_wea <= '0';
    Cv_web <= '0';
    
    if Start_SI = '1' then
        Init0_in <= '1';
        Count_DN <= 126;
        Count_i_DN <= 127;
        Count_t_DN <= (255 + T - 1 - 1) / 2;
    end if;
    
    case State_DP is
      when init =>
        if Next_SI = '1' then
          Init0_in <= '1';
          Count_DN <= Count_DP + 1;
        end if;
        cv_addra <= std_logic_vector(to_unsigned(2 * Cv_Ad_DI, CV_ADDR_WIDTH));
        cv_addrb <= std_logic_vector(to_unsigned(2 * Cv_Ad_DI + 1, CV_ADDR_WIDTH));
        Dig_DO <= cv_douta & cv_doutb;
        Ready_SO <= '1';
      when absorb_start =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_3;
        K0_in(KECCAK_R - 9 downto 0) <= Salt_DI & std_logic_vector(to_unsigned(Count_DP, 16)) & Dig0_DI & Dig1_DI(DIGEST_L - 1 downto DIGEST_L - (KECCAK_R - 8 - SALT_LEN - 16 - DIGEST_L));
      when absorb =>
        if Finish0_out = '1' then
          K0_in(KECCAK_R - 1 downto KECCAK_R - (DIGEST_L - (KECCAK_R - 8 - SALT_LEN - 16 - DIGEST_L)) - 8) <= Dig1_DI(DIGEST_L - (KECCAK_R - 8 - SALT_LEN - 16 - DIGEST_L) - 1 downto 0) & KECCAK_PAD;
          K0_in(7) <= '1';
          Start0_in <= '1';
        end if;
      when dig_out =>
        if Finish0_out = '1' then 
          cv_addra <= std_logic_vector(to_unsigned(Count_DP + Count_DP, CV_ADDR_WIDTH));
          cv_addrb <= std_logic_vector(to_unsigned(Count_DP + Count_DP + 1, CV_ADDR_WIDTH));
          cv_wea <= '1';
          cv_web <= '1';
          cv_dina <= Hash0_out(DIGEST_L - 1 downto DIGEST_L - CV_DATA_WIDTH);
          cv_dinb <= Hash0_out(DIGEST_L - CV_DATA_WIDTH - 1 downto DIGEST_L - CV_DATA_WIDTH - CV_DATA_WIDTH);
        end if;
      when cv_init =>
        Count_DN <= (Count_t_DP - 1) / 2;
        Count_i_DN <= (Count_i_DP - 1) / 2;
        Count_t_DN <= (Count_t_DP - 1) / 2;
      when cv_read0 =>
        cv_addra <= std_logic_vector(to_unsigned(Count_DP * 2 + 2 + Count_DP * 2 + 2, CV_ADDR_WIDTH));
        cv_addrb <= std_logic_vector(to_unsigned(Count_DP * 2 + 2 + Count_DP * 2 + 2 + 1, CV_ADDR_WIDTH));
      when cv_read1 =>
        Dig_DN <= cv_douta & cv_doutb;
        cv_addra <= std_logic_vector(to_unsigned(Count_DP * 2 + 1 + Count_DP * 2 + 1, CV_ADDR_WIDTH));
        cv_addrb <= std_logic_vector(to_unsigned(Count_DP * 2 + 1 + Count_DP * 2 + 1 + 1, CV_ADDR_WIDTH));
        Init0_in <= '1';
      when cv_absorb0 =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_3;
        K0_in(KECCAK_R - 9 downto 0) <= Salt_DI & std_logic_vector(to_unsigned(Count_DP, 16)) & cv_douta & cv_doutb & Dig_DP(DIGEST_L - 1 downto DIGEST_L - (KECCAK_R - 8 - SALT_LEN - 16 - DIGEST_L));
        Start0_in <= '1';
      when cv_absorb1 =>
        if Finish0_out = '1' then
          K0_in(KECCAK_R - 1 downto KECCAK_R - (DIGEST_L - (KECCAK_R - 8 - SALT_LEN - 16 - DIGEST_L)) - 8) <= Dig_DP(DIGEST_L - (KECCAK_R - 8 - SALT_LEN - 16- DIGEST_L) - 1 downto 0) & KECCAK_PAD;
          K0_in(7) <= '1';
          Start0_in <= '1';
        end if;
      when cv_out =>
        if Finish0_out = '1' then 
          cv_addra <= std_logic_vector(to_unsigned(Count_DP + Count_DP, CV_ADDR_WIDTH));
          cv_addrb <= std_logic_vector(to_unsigned(Count_DP + Count_DP + 1, CV_ADDR_WIDTH));
          cv_wea <= '1';
          cv_web <= '1';
          cv_dina <= Hash0_out(DIGEST_L - 1 downto DIGEST_L - CV_DATA_WIDTH);
          cv_dinb <= Hash0_out(DIGEST_L - CV_DATA_WIDTH - 1 downto DIGEST_L - CV_DATA_WIDTH - CV_DATA_WIDTH);
          Count_DN <= Count_DP - 1;
        end if;
      --when others =>
      
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Next_SI, Finish0_out, Count_i_DP, Count_DP, Count_t_DP)
  begin
    --default
    State_DN <= State_DP;
    if Start_SI = '1' then
      State_DN <= init;
    end if;
    case State_DP is
      when init =>
        if Next_SI = '1' then
          State_DN <= absorb_start;
        end if;
      when absorb_start =>
        State_DN <= absorb;
      when absorb =>
        if Finish0_out = '1' then
          State_DN <= dig_out;
        end if;
      when dig_out =>
        if Finish0_out = '1' then
          State_DN <= init;
          if Count_DP >= Count_t_DP then
            State_DN <= cv_init;
          end if;
        end if;
      when cv_init =>
        State_DN <= cv_read0;
      when cv_read0 =>
        State_DN <= cv_read1;
      when cv_read1 =>
        State_DN <= cv_absorb0;
      when cv_absorb0 =>
        State_DN <= cv_absorb1;
      when cv_absorb1 =>
        if Finish0_out = '1' then
          State_DN <= cv_out;
        end if;
      when cv_out =>
        if Finish0_out = '1' then
          State_DN <= cv_read0;
          if Count_DP = 0 then
            State_DN <= init;
          elsif Count_DP <= Count_i_DP then
            State_DN <= cv_init;
          end if;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        State_DP      <= init;
        Count_DP      <= 0;
        Count_i_DP      <= 0;
        Count_t_DP      <= 0;
        Dig_DP      <= (others => '0');
      else
        State_DP      <= State_DN;
        Count_DP      <= Count_DN;
        Count_i_DP      <= Count_i_DN;
        Count_t_DP      <= Count_t_DN;
        Dig_DP      <= Dig_DN;
      end if;
    end if;
  end process;

end behavorial;
