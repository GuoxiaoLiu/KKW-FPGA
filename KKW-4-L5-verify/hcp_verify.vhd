library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;
use work.bram_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hcp_verify is
  port(
    -- Clock and Reset
    signal Clk_CI      : in std_logic;
    signal Rst_RI      : in std_logic;
    -- Input signals
    signal Start_SI    : in std_logic;
    signal Verify_SI    : in std_logic;
    signal Salt_DI     : in std_logic_vector(SALT_LEN - 1 downto 0);
    signal Challenge_DI: in std_logic_vector(DIGEST_L - 1 downto 0);
    signal Ch_DI       : in std_logic_vector(DIGEST_L - 1 downto 0);
    signal Cv_tree0_DI : in std_logic_vector(DIGEST_L - 1 downto 0);
    signal Plain_DI    : in std_logic_vector(N - 1 downto 0);
    signal Cipher_DI   : in std_logic_vector(N - 1 downto 0);
    signal Message_DI  : in std_logic_vector(MSG_LEN - 1 downto 0);
    -- Output signals
    signal Ready_SO    : out std_logic;
    signal ChallengeC  : out std_logic_vector(T - 1 downto 0);
    signal ChallengeP  : out std_logic_vector(2 * tau - 1 downto 0);
    signal Dig_DO      : out std_logic_vector(DIGEST_L - 1 downto 0);
    signal Tree_DO     : out std_logic_vector(numNodes - 1 downto 0);
    signal Sig_Len_DO   : out integer range 0 to MAX_SIG
  );
end entity;

architecture behavorial of hcp_verify is
  type states is (
    init, absorb0, absorb1, absorb2, absorb4, absorb5, absorb6, challenge0, challenge1, challenge2, challenge3,
    tree_init, tree_create, tree_next, tree_len
  );
  signal State_DN, State_DP : states;
  signal Init0_in, Start0_in, Finish0_out : std_logic;
  signal K0_in : std_logic_vector(KECCAK_R - 1 downto 0);
  signal Hash0_out : std_logic_vector(PICNIC_S * 2 - 1 downto 0);
  signal Count_i_DN, Count_i_DP : integer range 0 to 1023;
  signal Count_j_DN, Count_j_DP : integer range 0 to 1023;
  signal Count_t_DN, Count_t_DP : integer range 0 to 1023;
  signal ChallengeP_DN, ChallengeP_DP : std_logic_vector(2 * tau - 1 downto 0);
  signal ChallengeC_DN, ChallengeC_DP : std_logic_vector(T - 1 downto 0);
  signal Dig_DN, Dig_DP : std_logic_vector(DIGEST_L - 1 downto 0);
  signal Chal_DN, Chal_DP : std_logic_vector(DIGEST_L - 1 downto 0);
  signal Sig_Len_DP, Sig_Len_DN : integer range 0 to MAX_SIG;
  signal Tree_DN, Tree_DP : std_logic_vector(numNodes - 1 downto 0);


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
    Absorb_SI  => Start0_in,
    Init_SI    => Init0_in,
    Hash_DO    => Hash0_out,
    Valid_SO   => Finish0_out
  );

  
  -- output logic
  process (State_DP, Start_SI, Verify_SI, Challenge_DI, Count_i_DP, Count_j_DP, Count_t_DP, ChallengeP_DP, ChallengeC_DP, Dig_DP, Chal_DP, Finish0_out, Hash0_out, Ch_DI, Tree_DP, Sig_Len_DP, Cv_tree0_DI, Salt_DI, Plain_DI, Cipher_DI, Message_DI)
    variable tmp_num_vec : std_logic_vector(8 downto 0);
    variable tmp_num : integer range 0 to 511;
  begin
    --default
    Start0_in <= '0';
    Init0_in <= '0';
    Ready_SO <= '0';
    K0_in <= (others => '0');
    Dig_DO <= Chal_DP;
    Count_i_DN <= Count_i_DP;
    Count_j_DN <= Count_j_DP;
    Count_t_DN <= Count_t_DP;
    ChallengeP_DN <= ChallengeP_DP;
    ChallengeC_DN <= ChallengeC_DP;
    Dig_DN <= Dig_DP;
    Chal_DN <= Chal_DP;
    Sig_Len_DN <= Sig_Len_DP;
    Sig_Len_DO <= Sig_Len_DP;
    Tree_DN <= Tree_DP;
    Tree_DO <= Tree_DP;
    ChallengeC <= ChallengeC_DP;
    ChallengeP <= ChallengeP_DP;

    
    
    case State_DP is
      when init =>

        if Verify_SI = '1' then
          ChallengeC_DN <= (others => '0');
          ChallengeP_DN <= (others => '0');
          Count_i_DN <= 0;
          Count_j_DN <= 0;
          Dig_DN <= Challenge_DI;
          Init0_in <= '1';
        elsif Start_SI = '1' then
          Init0_in <= '1';  
          Sig_Len_DN <= 0;
        end if;
        Ready_SO <= '1';
      when absorb0 =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - 8) <= HASH_PREFIX_N;
        K0_in(KECCAK_R - 9 downto 0) <= Ch_DI & Cv_tree0_DI & Salt_DI(SALT_LEN - 1 downto SALT_LEN - (KECCAK_R - 8 - 2 * DIGEST_L));
        Start0_in <= '1';
      when absorb1 =>
        if Finish0_out = '1' then
          K0_in(KECCAK_R - 1 downto 0) <= Salt_DI(SALT_LEN - (KECCAK_R - 8 - 2 * DIGEST_L) - 1 downto 0) & Plain_DI & Cipher_DI & Message_DI(MSG_LEN - 1 downto MSG_LEN - (KECCAK_R - (SALT_LEN - (KECCAK_R - 8 - 2 * DIGEST_L)) - N - N));
          Start0_in <= '1';
        end if;
      when absorb2 =>
        if Finish0_out = '1' then
          K0_in(KECCAK_R - 1 downto KECCAK_R - (MSG_LEN - (KECCAK_R - (SALT_LEN - (KECCAK_R - 8 - 2 * DIGEST_L)) - N - N)) - 8) <= Message_DI(MSG_LEN - (KECCAK_R - (SALT_LEN - (KECCAK_R - 8 - 2 * DIGEST_L)) - N - N) - 1 downto 0) & KECCAK_PAD;
          K0_in(7) <= '1';
          Start0_in <= '1';
        end if;
      when absorb4 =>
        if Finish0_out = '1' then
          Chal_DN <= Hash0_out;
        end if;
      when absorb5 =>
        if Finish0_out = '1' then
          Dig_DN <= Hash0_out;
          Init0_in <= '1';
          Count_j_DN <= 0;
        end if;
      when challenge0 =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - DIGEST_L - 16) <= HASH_PREFIX_1 & Dig_DP & KECCAK_PAD;
        K0_in(7) <= '1';
        Start0_in <= '1';
        tmp_num_vec := Dig_DP(DIGEST_L - 1 downto DIGEST_L - 9);
        tmp_num := to_integer(unsigned(tmp_num_vec));
        if tmp_num < T and challengeC_DP(tmp_num) /= '1' then
          -- Add to challenge
          challengeC_DN(tmp_num) <= '1';
          Count_i_DN <= Count_i_DP + 1;
        end if;
        Dig_DN <= Dig_DP(DIGEST_L - 10 downto 0) & "000000000";
        Count_j_DN <= Count_j_DP + 1;
      when challenge1 =>
        tmp_num_vec := Dig_DP(DIGEST_L - 1 downto DIGEST_L - 9);
        tmp_num := to_integer(unsigned(tmp_num_vec));
        if tmp_num < T and challengeC_DP(tmp_num) /= '1' then
          -- Add to challenge
          challengeC_DN(tmp_num) <= '1';
          Count_i_DN <= Count_i_DP + 1;
        end if;
        Dig_DN <= Dig_DP(DIGEST_L - 10 downto 0) & "000000000";
        Count_j_DN <= Count_j_DP + 1;
      when absorb6 =>
        if Finish0_out = '1' then
          Dig_DN <= Hash0_out;
          Init0_in <= '1';
          Count_j_DN <= 0;
        end if; 
        if Count_i_DP = tau then
          Count_i_DN <= 0;
        end if;
      when challenge2 =>
        K0_in(KECCAK_R - 1 downto KECCAK_R - DIGEST_L - 16) <= HASH_PREFIX_1 & Dig_DP & KECCAK_PAD;
        K0_in(7) <= '1';
        Start0_in <= '1';
        -- Add to challenge
        ChallengeP_DN <= ChallengeP_DP(2 * tau - 3 downto 0) & Dig_DP(DIGEST_L - 1) & Dig_DP(DIGEST_L - 2);
        Count_i_DN <= Count_i_DP + 1;
        -- length:
        if Dig_DP(DIGEST_L - 1 downto DIGEST_L - 2) = "11" then
          Sig_Len_DN <= Sig_Len_DP + PICNIC_S / 4 + N_PAD_BYTE + RN_PAD_BYTE + DIGEST_L / 8;
        else
          Sig_Len_DN <= Sig_Len_DP + PICNIC_S / 4 + RN_PAD_BYTE + N_PAD_BYTE + RN_PAD_BYTE + DIGEST_L / 8;
        end if;
        Dig_DN <= Dig_DP(DIGEST_L - 3 downto 0) & "00";
        Count_j_DN <= Count_j_DP + 1;
      when challenge3 =>
        -- Add to challenge
        ChallengeP_DN <= ChallengeP_DP(2 * Tau - 3 downto 0) & Dig_DP(DIGEST_L - 1) & Dig_DP(DIGEST_L - 2);
        Count_i_DN <= Count_i_DP + 1;
        -- length:
        if Dig_DP(DIGEST_L - 1 downto DIGEST_L - 2) = "11" then
          Sig_Len_DN <= Sig_Len_DP + PICNIC_S / 4 + N_PAD_BYTE + RN_PAD_BYTE + DIGEST_L / 8;
        else
          Sig_Len_DN <= Sig_Len_DP + PICNIC_S / 4 + RN_PAD_BYTE + N_PAD_BYTE + RN_PAD_BYTE + DIGEST_L / 8;
        end if;
        Dig_DN <= Dig_DP(DIGEST_L - 3 downto 0) & "00";
        Count_j_DN <= Count_j_DP + 1;
       when tree_init =>
        Count_t_DN <= FIRST_LEAF;
        Count_i_DN <= FIRST_LEAF;
        Count_j_DN <= FIRST_LEAF + T - 1;

        Tree_DN(numNodes - 1 downto FIRST_LEAF) <= (not challengeC_DP);
        Tree_DN(FIRST_LEAF - 1 downto 0) <= (others => '0');
      when tree_create =>
        if Tree_DP(Count_t_DP) = '1' then
          if Count_t_DP = Count_j_DP then
            Tree_DN((Count_t_DP - 1) / 2) <= '1';
            Tree_DN(Count_t_DP) <= '0';
          elsif  Tree_DP(Count_t_DP + 1) = '1' then
            Tree_DN((Count_t_DP - 1) / 2) <= '1';
            Tree_DN(Count_t_DP + 1 downto Count_t_DP) <= "00";
          end if;
        end if;
        Count_t_DN <= Count_t_DP + 2;
      when tree_next =>
        Count_t_DN <= (Count_i_DP - 1) / 2;
        Count_i_DN <= (Count_i_DP - 1) / 2;
        Count_j_DN <= (Count_j_DP - 1) / 2;
      when tree_len =>
        if Tree_DP(numnodes - 1) = '1' then
          Sig_Len_DN <= Sig_Len_DP + PICNIC_S / 8 + DIGEST_L / 8;
        end if;
        Tree_DN <= Tree_DP(numnodes - 2 downto 0) & Tree_DP(numnodes - 1);
        Count_t_DN <= Count_t_DP + 1;
      --when others =>
      
    end case;
  end process;

  -- next state logic
  process (State_DP, Start_SI, Finish0_out, Verify_SI, Count_i_DP, Count_j_DP, Count_t_DP, Dig_DP, ChallengeC_DP)
    variable tmp_num_vec : std_logic_vector(8 downto 0);
    variable tmp_num : integer range 0 to 511;
  begin
    --default
    State_DN <= State_DP;
    case State_DP is
      when init =>
        if Verify_SI = '1' then
          State_DN <= challenge0;
        end if;
        if Start_SI = '1' then
          State_DN <= absorb0;
        end if;
      when absorb0 =>
        State_DN <= absorb1;
      when absorb1 =>
        if Finish0_out = '1' then
          State_DN <= absorb2;
        end if;
      when absorb2 =>
        if Finish0_out = '1' then
          State_DN <= absorb4;
        end if;
      when absorb4 =>
        if Finish0_out = '1' then
          State_DN <= init;
        end if;
      when absorb5 =>
        if Finish0_out = '1' then
          State_DN <= challenge0;
        end if;
      when challenge0 =>
        tmp_num_vec := Dig_DP(DIGEST_L - 1 downto DIGEST_L - 9);
        tmp_num := to_integer(unsigned(tmp_num_vec));
        if Count_i_DP >= tau - 1 and tmp_num < T and ChallengeC_DP(tmp_num) /= '1' then
          State_DN <= absorb6;
        else
          State_DN <= challenge1;
        end if;
      when challenge1 =>
        tmp_num_vec := Dig_DP(DIGEST_L - 1 downto DIGEST_L - 9);
        tmp_num := to_integer(unsigned(tmp_num_vec));
        if Count_i_DP >= tau - 1 and tmp_num < T and ChallengeC_DP(tmp_num) /= '1' then
          State_DN <= absorb6;
        elsif Count_j_DP >= DIGEST_L / 9 - 1 then
          State_DN <= absorb5;
      end if;
      when absorb6 =>
         if Finish0_out = '1' then
          State_DN <= challenge2;
        end if;
      when challenge2 =>
        if Count_i_DP >= tau - 1 then
          State_DN <= tree_init;
        else
          State_DN <= challenge3;
        end if;
      when challenge3 =>
        if Count_i_DP >= tau - 1 then
          State_DN <= tree_init;
        elsif Count_j_DP >= DIGEST_L / 2 - 1 then
          State_DN <= absorb6;
        end if;
      when tree_init =>
        State_DN <= tree_create;
      when tree_create =>
        if Count_t_DP + 1 >= Count_j_DP then
          State_DN <= tree_next;
        end if;
      when tree_next =>
        if Count_j_DP = 2 then
          State_DN <= tree_len;
        else
          State_DN <= tree_create;
        end if;
      when tree_len =>
        if Count_t_DP >= numNodes - 1 then
          State_DN <= init;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        State_DP      <= init;
        Count_i_DP      <= 0;
        Count_j_DP      <= 0;
        Count_t_DP      <= 0;
        ChallengeP_DP      <= (others => '0');
        ChallengeC_DP      <=  (others => '0');
        Dig_DP      <= (others => '0');
        Chal_DP      <= (others => '0');
        Sig_Len_DP <= 0;
        Tree_DP <= (others => '0');

      else
        State_DP      <= State_DN;
        Count_i_DP      <= Count_i_DN;
        Count_j_DP      <= Count_j_DN;
        Count_t_DP      <= Count_t_DN;
        ChallengeP_DP      <= ChallengeP_DN;
        ChallengeC_DP      <= ChallengeC_DN;
        Dig_DP      <= Dig_DN;
        Chal_DP      <= Chal_DN;
        Sig_Len_DP <= Sig_Len_DN;
        Tree_DP <= Tree_DN;

      end if;
    end if;
  end process;

end behavorial;
