library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;
use work.bram_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seed_verify is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Next_SI     : in std_logic;
    signal Salt_DI     : in std_logic_vector(SALT_LEN - 1 downto 0);
    signal Tree_DI     : in std_logic_vector(numnodes - 1 downto 0);
    signal Seed_Ad_DI  : in std_logic_vector(SEED_ADDR_WIDTH - 1 downto 0);
    signal Seed_DI     : in std_logic_vector(PICNIC_S - 1 downto 0);
    signal Seed_WE     : in std_logic;
    
    -- Output signals
    signal Ready_SO    : out std_logic;
    signal Seed_DO   : out SEED_ARR
  );
end entity;

architecture behavorial of seed_verify is

  signal seed_addra, seed_addrb : std_logic_vector(SEED_ADDR_WIDTH - 1 downto 0);
  signal seed_wea, seed_web : std_logic;
  signal seed_dina, seed_dinb : std_logic_vector(SEED_DATA_WIDTH - 1 downto 0);
  signal seed_douta, seed_doutb : std_logic_vector(SEED_DATA_WIDTH - 1 downto 0);

  type states is (
    init, tree_create, read_seedi, read_seedj, seed_absorb, seed_out0, seed_out1, read_seed, iseed_out
  );
  signal State_DN, State_DP : states;
  signal Init_in, Start_in, Finish_out : std_logic;
  signal K0_in, K1_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash0_out : std_logic_vector(PICNIC_S * 2 - 1 downto 0);
  signal Hash1_out : std_logic_vector(PICNIC_S * 2 - 1 downto 0);
  signal Count_DN, Count_DP : integer range 0 to 1023;
  signal Count_i_DN, Count_i_DP : integer range 0 to numnodes;
  signal Count_j_DN, Count_j_DP : integer range 0 to numnodes;
  signal Count_t_DN, Count_t_DP : integer range 0 to numnodes;
  signal Salt_DN, Salt_DP : std_logic_vector(SALT_LEN - 1 downto 0);
  signal Tree_DN, Tree_DP : std_logic_vector(numnodes - 1 downto 0);

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
    Absorb_SI  => Start_in,
    Init_SI    => Init_in,
    Hash_DO    => Hash0_out,
    Valid_SO   => open
  );

  K1 : keccak
  generic map(
    GEN_R => KECCAK_R,
    OUT_BIT => PICNIC_S * 2
  )
  port map (
    Clk_CI     => Clk_CI,
    Rst_RI     => Rst_RI,
    Block_DI   => K1_in,
    Absorb_SI  => Start_in,
    Init_SI    => Init_in,
    Hash_DO    => Hash1_out,
    Valid_SO   => Finish_out
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
  process (State_DP, Start_SI, Next_SI, Seed_DI, Tree_DP, Tree_DI, Count_t_DP, Count_j_DP, Salt_DI, Seed_WE, Finish_out, Hash0_out, Hash1_out, Salt_DP, Count_DP, Count_i_DP, seed_douta, seed_doutb, Seed_Ad_DI)
  begin
    --default
    Start_in <= '0';
    Init_in <= '0';
    Ready_SO <= '0';
    K0_in <= (others => '0');
    K1_in <= (others => '0');
    Seed_DO <= (others => (others => '0'));
    Salt_DN <= Salt_DP;
    Tree_DN <= Tree_DP;
    Count_DN <= Count_DP;
    Count_i_DN <= Count_i_DP;
    Count_j_DN <= Count_j_DP;
    Count_t_DN <= Count_t_DP;
    seed_addra <= (others => '0');
    seed_addrb <= (others => '0');
    seed_dina <= (others => '0');
    seed_dinb <= (others => '0');
    seed_wea <= '0';
    seed_web <= '0';
    

    case State_DP is
      when init =>
        if Start_SI = '1' then
          Salt_DN <= Salt_DI;
          Tree_DN <= Tree_DI;
          Count_DN <= 0;
          Count_i_DN <= 0;
          Count_j_DN <= 0;
          Count_t_DN <= 0;
        end if;
        Ready_SO <= '1';
        seed_addra <= Seed_Ad_DI;
        seed_wea <= Seed_WE;
        seed_dina <= Seed_DI;
      when tree_create =>
        if Tree_DP(Count_DP) = '1' then
          if 2 * Count_DP + 1 <= numnodes - 1 then
            Tree_DN(2 * Count_DP + 1) <= '1';
          end if;
          if 2 * Count_DP + 2 <= numnodes - 1 then
            Tree_DN(2 * Count_DP + 2) <= '1';
          end if;
        end if;
        Count_DN <= Count_DP + 1;
      when read_seedi =>
        if Tree_DP(Count_t_DP) = '1' then
          Count_i_DN <= Count_t_DP;
          seed_addra <= std_logic_vector(to_unsigned(Count_t_DP, SEED_ADDR_WIDTH));
          Init_in <= '1';
        end if;
        Count_t_DN <= Count_t_DP + 1;
      when read_seedj =>  
        seed_addra <= std_logic_vector(to_unsigned(Count_i_DP, SEED_ADDR_WIDTH));
        if Tree_DP(Count_t_DP) = '1' then
          Count_j_DN <= Count_t_DP;
          seed_addrb <= std_logic_vector(to_unsigned(Count_t_DP, SEED_ADDR_WIDTH));
        end if;
        Count_t_DN <= Count_t_DP + 1;
      when seed_absorb =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_1;
        K0_in(KECCAK_R - 9 downto KECCAK_R - 8 - PICNIC_S - SALT_LEN - 16 - 16 - 8) <= seed_douta & Salt_DP & std_logic_vector(to_unsigned(0, 16)) & std_logic_vector(to_unsigned(Count_i_DP, 16)) & KECCAK_PAD;
        K0_in(7) <= '1';
        K1_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_1;
        K1_in(KECCAK_R - 9 downto KECCAK_R - 8 - PICNIC_S - SALT_LEN - 16 - 16 - 8) <= seed_doutb & Salt_DP & std_logic_vector(to_unsigned(0, 16)) & std_logic_vector(to_unsigned(Count_j_DP, 16)) & KECCAK_PAD;
        K1_in(7) <= '1';
        Start_in <= '1';
      when seed_out0 =>
        if Finish_out = '1' then
          seed_dina <= Hash0_out(2 * PICNIC_S - 1 downto PICNIC_S);
          seed_dinb <= Hash0_out(PICNIC_S - 1 downto 0);
          seed_addra <= std_logic_vector(to_unsigned(2 * Count_i_DP + 1, SEED_ADDR_WIDTH));
          seed_addrb <= std_logic_vector(to_unsigned(2 * Count_i_DP + 2, SEED_ADDR_WIDTH));
          seed_wea <= '1';
          seed_web <= '1';
        end if;
      when seed_out1 =>
        seed_dina <= Hash1_out(2 * PICNIC_S - 1 downto PICNIC_S);
        seed_dinb <= Hash1_out(PICNIC_S - 1 downto 0);
        seed_addra <= std_logic_vector(to_unsigned(2 * Count_j_DP + 1, SEED_ADDR_WIDTH));
        seed_addrb <= std_logic_vector(to_unsigned(2 * Count_j_DP + 2, SEED_ADDR_WIDTH));
        if Count_j_DP > 0 then
          seed_wea <= '1';
          seed_web <= '1';
        end if;
        if (Count_t_DP = numnodes - 1 and Tree_DP(numnodes - 1) = '0') or (Count_t_DP > numnodes - 1) then
          Count_DN <= 2 * FIRST_LEAF + 1;
          Count_t_DN <= 0;
        end if;
        Count_j_DN <= 0;
        Count_i_DN <= 0;
      when read_seed =>
        seed_addra <= std_logic_vector(to_unsigned(Count_DP, SEED_ADDR_WIDTH));
        seed_addrb <= std_logic_vector(to_unsigned(Count_DP + 1, SEED_ADDR_WIDTH));
        Count_i_DN <= Count_DP;
        Count_j_DN <= Count_DP + 1;
        Init_in <= '1';
      when iseed_out =>
        if Finish_out = '1' then
          Seed_DO(0) <= Hash0_out(2 * PICNIC_S - 1 downto 1 * PICNIC_S);
          Seed_DO(1) <= Hash0_out(1 * PICNIC_S - 1 downto 0 * PICNIC_S);
          Seed_DO(2) <= Hash1_out(2 * PICNIC_S - 1 downto 1 * PICNIC_S);
          Seed_DO(3) <= Hash1_out(1 * PICNIC_S - 1 downto 0 * PICNIC_S);
          Ready_SO <= '1';
          if Next_SI = '1' then
            Count_DN <= Count_DP + 2;
            Count_t_DN <= Count_t_DP + 1;
          end if;
        end if;
        
      --when others =>
      
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Next_SI, Finish_out, Count_i_DP, Count_DP, Count_t_DP, Tree_DP, Count_j_DP)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when init =>
        if Start_SI = '1' then
          State_DN <= tree_create;
        end if;
      when tree_create =>
        if 2 * Count_DP + 1 >= numnodes - 1 then
          State_DN <= read_seedi;
        end if;
      when read_seedi =>
        if Tree_DP(Count_t_DP) = '1' then
          State_DN <= read_seedj;
          if Count_t_DP >= numNodes - 1 then
            State_DN <= seed_absorb;
          end if;
        else
          if Count_t_DP >= numNodes - 1 then
            State_DN <= read_seed;
          end if;
        end if;
      when read_seedj =>
        if Tree_DP(Count_t_DP) = '1' or Count_t_DP >= numNodes - 1 then
          State_DN <= seed_absorb;
        end if;
      when read_seed =>
        State_DN <= seed_absorb;
      when seed_absorb =>
        if Count_DP >= 2 * FIRST_LEAF + 1 then
          State_DN <= iseed_out;
        else
          State_DN <= seed_out0;
        end if;
      when seed_out0 =>
        if Finish_out = '1' then
          State_DN <= seed_out1;
        end if;
      when seed_out1 =>
        State_DN <= read_seed;
        if (Count_t_DP = numnodes - 1 and Tree_DP(numnodes - 1) = '0') or (Count_t_DP > numnodes - 1) then
          State_DN <= read_seed;
        else
          State_DN <= read_seedi;
        end if;
      when iseed_out =>
        if Next_SI = '1' and Finish_out = '1' then
          State_DN <= read_seed;
          if Count_t_DP >= T - 1 then
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
        Count_j_DP      <= 0;
        Count_t_DP    <= 0;
        Salt_DP <= (others => '0');
        Tree_DP <= (others => '0');
      else
        State_DP      <= State_DN;
        Count_DP      <= Count_DN;
        Count_i_DP      <= Count_i_DN;
        Count_j_DP      <= Count_j_DN;
        Salt_DP <= Salt_DN;
        Tree_DP <= Tree_DN;
        Count_t_DP <= Count_t_DN;
      end if;
    end if;
  end process;

end behavorial;
