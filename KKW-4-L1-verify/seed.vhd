library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;
use work.bram_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seed is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Next_SI     : in std_logic;
    
    signal Plain_DI    : in std_logic_vector(N - 1 downto 0);
    signal Key_DI      : in std_logic_vector(N - 1 downto 0);
    signal Cipher_DI   : in std_logic_vector(N - 1 downto 0);
    signal Message_DI  : in std_logic_vector(MSG_LEN - 1 downto 0);
    signal Seed_Ad_DI  : in std_logic_vector(SEED_ADDR_WIDTH - 1 downto 0);
    -- Output signals
    signal Ready_SO    : out std_logic;
    signal Salt_DO     : out std_logic_vector(SALT_LEN - 1 downto 0);
    signal Seed_DO   : out SEED_ARR
  );
end entity;

architecture behavorial of seed is

  signal seed_addra, seed_addrb : std_logic_vector(SEED_ADDR_WIDTH - 1 downto 0);
  signal seed_wea, seed_web : std_logic;
  signal seed_dina, seed_dinb : std_logic_vector(SEED_DATA_WIDTH - 1 downto 0);
  signal seed_douta, seed_doutb : std_logic_vector(SEED_DATA_WIDTH - 1 downto 0);

  type states is (
    init, absorb_start, absorb1, root_seed_salt_out,
    read_seed, seed_absorb, seed_out0, seed_out1, iseed_out
  );
  signal State_DN, State_DP : states;
  signal Init0_in, Start0_in, Finish1_out, Init1_in, Start1_in : std_logic;
  signal K0_in, K1_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash0_out : std_logic_vector(PICNIC_S * 2 - 1 downto 0);
  signal Hash1_out : std_logic_vector(PICNIC_S * 3 - 1 downto 0);
  signal Count_DN, Count_DP : integer range 0 to 1023;
  signal Count_i_DN, Count_i_DP : integer range 0 to T;
  --signal Count_t_DN, Count_t_DP : integer range 0 to T;
  signal Salt_DN, Salt_DP : std_logic_vector(SALT_LEN - 1 downto 0);

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

  K0 : keccak
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => PICNIC_S * 2
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K0_in,
    Absorb_SI  => Start0_in,
    Init_SI    => Init0_in,
    Hash_DO    => Hash0_out,
    Valid_SO   => open
  );

  K1 : keccak
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => PICNIC_S * 3
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K1_in,
    Absorb_SI  => Start1_in,
    Init_SI    => Init1_in,
    Hash_DO    => Hash1_out,
    Valid_SO   => Finish1_out
  );

  SEED_RAM : xilinx_TDP_RAM
  generic map(
    ADDR_WIDTH => SEED_ADDR_WIDTH,
    DATA_WIDTH => SEED_DATA_WIDTH,
    ENTRIES => SEED_ENTRIES
  )
  port map(
    clk => Clk_CI,
    addra => seed_addra,
    addrb => seed_addrb,
    dina => seed_dina,
    dinb => seed_dinb,
    wea => seed_wea,
    web => seed_web,
    ena => '1',
    enb => '1',
    douta => seed_douta,
    doutb => seed_doutb
  );

  
  -- output logic
  process (State_DP, Start_SI, Next_SI, Finish1_out, Hash0_out, Hash1_out, Plain_DI, Key_DI, Cipher_DI, Message_DI, Salt_DP, Count_DP, Count_i_DP, seed_douta, seed_doutb, Seed_Ad_DI)
  begin
    --default
    Start0_in <= '0';
    Start1_in <= '0';
    Init0_in <= '0';
    Init1_in <= '0';
    Ready_SO <= '0';
    K0_in <= (others => '0');
    K1_in <= (others => '0');
    Seed_DO <= (others => (others => '0'));
    Salt_DN <= Salt_DP;
    Salt_DO <= Salt_DP;
    Count_DN <= Count_DP;
    Count_i_DN <= Count_i_DP;
    --Count_t_DN <= Count_t_DP;
    seed_addra <= (others => '0');
    seed_addrb <= (others => '0');
    seed_dina <= (others => '0');
    seed_dinb <= (others => '0');
    seed_wea <= '0';
    seed_web <= '0';
    

    case State_DP is
      when init =>
        if Start_SI = '1' then
          Init1_in <= '1';
        end if;
        Ready_SO <= '1';
        seed_addra <= Seed_Ad_DI;
        Seed_DO(0) <= seed_douta;
      when absorb_start =>
        K1_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K1_in(KECCAK_R - 9 downto KECCAK_R - 8 - 129 - 512 - 129 -129 - 24) <= Key_DI & Message_DI & Cipher_DI & Plain_DI & STATE_SIZE_BIT & KECCAK_PAD;
        K1_in(7) <= '1';
        Start1_in <= '1';
      when absorb1 =>
        Count_DN <= 0;
        Count_i_DN <= 0;
        --Count_t_DN <= 0;
      when root_seed_salt_out =>
        Salt_DN <= Hash1_out(3 * PICNIC_S - 1 downto PICNIC_S);
        seed_addra <= std_logic_vector(to_unsigned(Count_DP, SEED_ADDR_WIDTH));
        seed_dina <= Hash1_out(PICNIC_S - 1 downto 0);
        seed_wea <= '1';
      when read_seed =>
        seed_addra <= std_logic_vector(to_unsigned(Count_DP, SEED_ADDR_WIDTH));
        Init0_in <= '1';

        seed_addrb <= std_logic_vector(to_unsigned(Count_DP + 1, SEED_ADDR_WIDTH));
        Init1_in <= '1';
      when seed_absorb =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_1;
        K0_in(KECCAK_R - 9 downto KECCAK_R - 8 - PICNIC_S - SALT_LEN - 16 - 16 - 8) <= seed_douta & Salt_DP & std_logic_vector(to_unsigned(0, 16)) & std_logic_vector(to_unsigned(Count_DP, 16)) & KECCAK_PAD;
        K0_in(7) <= '1';
        Start0_in <= '1';
        K1_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_1;
        K1_in(KECCAK_R - 9 downto KECCAK_R - 8 - PICNIC_S - SALT_LEN - 16 - 16 - 8) <= seed_doutb & Salt_DP & std_logic_vector(to_unsigned(0, 16)) & std_logic_vector(to_unsigned(Count_DP + 1, 16)) & KECCAK_PAD;
        K1_in(7) <= '1';
        Start1_in <= '1';
      when seed_out0 =>
        if Finish1_out = '1' then
          seed_dina <= Hash0_out(2 * PICNIC_S - 1 downto PICNIC_S);
          seed_dinb <= Hash0_out(PICNIC_S - 1 downto 0);
          seed_addra <= std_logic_vector(to_unsigned(2 * Count_DP + 1, SEED_ADDR_WIDTH));
          seed_addrb <= std_logic_vector(to_unsigned(2 * Count_DP + 2, SEED_ADDR_WIDTH));
          seed_wea <= '1';
          seed_web <= '1';
        end if;
      when seed_out1 =>
        seed_dina <= Hash1_out(3 * PICNIC_S - 1 downto 2 * PICNIC_S);
        seed_dinb <= Hash1_out(2 * PICNIC_S - 1 downto PICNIC_S);
        seed_addra <= std_logic_vector(to_unsigned(2 * Count_DP + 3, SEED_ADDR_WIDTH));
        seed_addrb <= std_logic_vector(to_unsigned(2 * Count_DP + 4, SEED_ADDR_WIDTH));
        seed_wea <= '1';
        seed_web <= '1';
        if Count_DP = 0 then
          Count_DN <= 1;
        elsif Count_DP >= numnodes then
          Count_DN <= 2 * FIRST_LEAF + 1;
        else
          Count_DN <= Count_DP + 2;
        end if;
      when iseed_out =>
        if Finish1_out = '1' then
          Seed_DO(0) <= Hash0_out(2 * PICNIC_S - 1 downto 1 * PICNIC_S);
          Seed_DO(1) <= Hash0_out(1 * PICNIC_S - 1 downto 0 * PICNIC_S);
          Seed_DO(2) <= Hash1_out(3 * PICNIC_S - 1 downto 2 * PICNIC_S);
          Seed_DO(3) <= Hash1_out(2 * PICNIC_S - 1 downto 1 * PICNIC_S);
          Ready_SO <= '1';
          if Next_SI = '1' then
            Count_DN <= Count_DP + 2;
            Count_i_DN <= Count_i_DP + 1;
          end if;
        end if;
        
      --when others =>
      
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Next_SI, Finish1_out, Count_i_DP, Count_DP)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when init =>
        if Start_SI = '1' then
          State_DN <= absorb_start;
        end if;
      when absorb_start =>
        State_DN <= absorb1;
      when absorb1 =>
        if Finish1_out = '1' then
          State_DN <= root_seed_salt_out;
        end if;
      when root_seed_salt_out =>
        State_DN <= read_seed;
      when read_seed =>
        State_DN <= seed_absorb;
      when seed_absorb =>
        if Count_DP >= 2 * FIRST_LEAF + 1 then
          State_DN <= iseed_out;
        else
          State_DN <= seed_out0;
        end if;
      when seed_out0 =>
        if Finish1_out = '1' then
          State_DN <= seed_out1;
        end if;
      when seed_out1 =>
        State_DN <= read_seed;
      when iseed_out =>
        if Next_SI = '1' and Finish1_out = '1' then
          State_DN <= read_seed;
          if Count_i_DP >= T - 1 then
            State_DN <= init;
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
        --Count_t_DP      <= 0;
        Salt_DP <= (others => '0');
      else
        State_DP      <= State_DN;
        Count_DP      <= Count_DN;
        Count_i_DP      <= Count_i_DN;
        --Count_t_DP      <= Count_t_DN;
        Salt_DP <= Salt_DN;
      end if;
    end if;
  end process;

end behavorial;
