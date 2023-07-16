library work;
use work.lowmc_pkg.all;
use work.keccak_pkg.all;
use work.picnic_pkg.all;
use work.bram_pkg.all;
use work.protocol_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity picnic3_verify is
  port(
    -- Clock and Reset
    signal clk          : in std_logic;
    signal rst          : in std_logic;
    -- Public Data Inputs
    signal pdi_data     : in std_logic_vector(PDI_WIDTH - 1 downto 0);
    signal pdi_valid    : in std_logic;
    signal pdi_ready    : out std_logic;
    -- Public Data Outputs
    signal pdo_data     : out std_logic_vector(PDO_WIDTH - 1 downto 0);
    signal pdo_valid    : out std_logic;
    signal pdo_ready    : in std_logic;
    signal pdo_last     : out std_logic;
    -- Status
    signal status_ready : out std_logic
  );
end entity;

architecture behavorial of picnic3_verify is
  
  -- seed bram
  signal seed_i_addra, seed_i_addrb : std_logic_vector(SEED_I_ADDR_WIDTH - 1 downto 0);
  signal seed_i_wea, seed_i_web : std_logic;
  --type ISEED_ARR is  array(0 to P - 1) of std_logic_vector(SEED_I_DATA_WIDTH - 1 downto 0);
  signal seed_i_dina, seed_i_dinb : std_logic_vector(SEED_I_DATA_WIDTH - 1 downto 0);
  signal seed_i_douta, seed_i_doutb : std_logic_vector(SEED_I_DATA_WIDTH - 1 downto 0);

  -- aux bram
  signal aux_addra, aux_addrb : std_logic_vector(AUX_ADDR_WIDTH - 1 downto 0);
  signal aux_wea, aux_web : std_logic;
  signal aux_dina, aux_dinb : std_logic_vector(AUX_DATA_WIDTH - 1 downto 0);
  signal aux_douta, aux_doutb : std_logic_vector(AUX_DATA_WIDTH - 1 downto 0);
  
  -- aux bram
  signal input_addra, input_addrb : std_logic_vector(INPUT_ADDR_WIDTH - 1 downto 0);
  signal input_wea, input_web : std_logic;
  signal input_dina, input_dinb : std_logic_vector(INPUT_DATA_WIDTH - 1 downto 0);
  signal input_douta, input_doutb : std_logic_vector(INPUT_DATA_WIDTH - 1 downto 0);

  -- commc bram
  signal commc_addra, commc_addrb : std_logic_vector(COMMC_ADDR_WIDTH - 1 downto 0);
  signal commc_wea, commc_web : std_logic_vector(P - 1 downto 0);
  type COMMC_ARR is array(0 to P - 1) of std_logic_vector(COMMC_DATA_WIDTH - 1 downto 0);
  signal commc_dina, commc_dinb : COMMC_ARR;
  signal commc_douta, commc_doutb : COMMC_ARR;

  -- -- commh bram
  -- signal commh_addra, commh_addrb : std_logic_vector(COMMH_ADDR_WIDTH - 1 downto 0);
  -- signal commh_wea, commh_web : std_logic;
  -- signal commh_dina, commh_dinb : std_logic_vector(COMMH_DATA_WIDTH - 1 downto 0);
  -- signal commh_douta, commh_doutb : std_logic_vector(COMMH_DATA_WIDTH - 1 downto 0);

  -- msgs bram
  signal msgs_addra, msgs_addrb : std_logic_vector(MSGS_ADDR_WIDTH - 1 downto 0);
  signal msgs_wea, msgs_web : std_logic_vector(P - 1 downto 0);
  type MSGS_BRAM_ARR is array(0 to P - 1) of std_logic_vector(MSGS_DATA_WIDTH - 1 downto 0);
  signal msgs_dina, msgs_dinb : MSGS_BRAM_ARR;
  signal msgs_douta, msgs_doutb : MSGS_BRAM_ARR;

  -- commv bram
  signal commv_addra, commv_addrb : std_logic_vector(COMMV_ADDR_WIDTH - 1 downto 0);
  signal commv_wea, commv_web : std_logic;
  signal commv_dina, commv_dinb : std_logic_vector(COMMV_DATA_WIDTH - 1 downto 0);
  signal commv_douta, commv_doutb : std_logic_vector(COMMV_DATA_WIDTH - 1 downto 0);

  -- seed
  signal seed_start, seed_next, seed_ready : std_logic;
  signal seed_addr : std_logic_vector(SEED_ADDR_WIDTH - 1 downto 0);
  signal seed_din : std_logic_vector(SEED_DATA_WIDTH - 1 downto 0);
  signal seed_we : std_logic;
  signal seed_out : SEED_ARR;

  -- tape 
  signal tape_start, tape_finish : std_logic;
  
  signal tape_out : R_N_2_ARR;
  signal tape_last_out : std_logic_vector(R * N - 1 downto 0);
  signal tape_round_in : std_logic_vector(16 - 1 downto 0);

  -- lowmc
  signal aux_start, sim_start : std_logic;
  signal lowmc_finish : std_logic;
  --signal masked_key_in : std_logic_vector(N - 1 downto 0);
  signal input_out : std_logic_vector(N - 1 downto 0);
  signal aux_out : std_logic_vector(R * N - 1 downto 0);
  signal lowmc_cipher : std_logic_vector(N - 1 downto 0);
  signal msgs_out : R_N_ARR;

  -- commit view
  signal commV_start, commV_finish : std_logic;
  --input_outsignal commV_input : std_logic_vector(N - 1 downto 0);

  signal commV_out : std_logic_vector(DIGEST_L - 1 downto 0);
  --type MSGS_IN_ARR is  array(0 to 3 * 4 - 1) of std_logic_vector(R * N - 1 downto 0);

  -- commit C
  signal commC_start, commC_finish : std_logic;
  signal commC_out : DIGE_ARR;

  -- commit H
  signal commH_start, commH_next, commH_finish : std_logic;
  --type COMMH_OUT_ARR is array(0 to 1) of std_logic_vector(DIGEST_L - 1 downto 0);
  signal commH_out : std_logic_vector(DIGEST_L - 1 downto 0);

  -- commit cv tree
  signal CV_start, CV_finish, CV_next, CV_veri : std_logic;
  signal CV_addr_in : integer range 0 to 4 * T + 10;
  signal CV_out : std_logic_vector(DIGEST_L - 1 downto 0);
  signal CV_din : std_logic_vector(CV_DATA_WIDTH - 1 downto 0);
  signal CV_we : std_logic;

  -- challenge
  signal Chal_start, Chal_finish, Chal_verify : std_logic;
  signal Chal_C : std_logic_vector(T - 1 downto 0);
  signal Chal_P  : std_logic_vector(2 * tau - 1 downto 0);
  signal Chal_out : std_logic_vector(DIGEST_L - 1 downto 0);
  signal Tree_out : std_logic_vector(numnodes - 1 downto 0);
  signal Sig_Len_out : integer range 0 to MAX_SIG;

  -- counter
  signal Counter_DN, Counter_DP : integer range 0 to T;
  signal Counter_Trans_DN, Counter_Trans_DP : integer range 0 to T;
  --signal Counter_Com_DN, Counter_Com_DP : integer range 0 to 3;
  signal Counter_tau_DN, Counter_tau_DP : integer range 0 to tau;


  -- state machine
  type states is ( init, read_pub_c0, read_pub_c1, read_pub_p0,
    read_pub_p1, inst_ver, read_msg, picnic_in_header, picnic_in_chal0, picnic_in_chal1, picnic_in_chal2, picnic_in_chal3,
    picnic_in_salt0, picnic_in_salt1, picnic_hcp_verify, picnic_in_seed_0, picnic_in_seed_1, picnic_in_cv0, picnic_in_cv1, picnic_in_cv2, picnic_in_cv3, picnic_in_cv4,
    picnic_in_cv5, picnic_in_cv6, picnic_in_cv7, picnic_in_cv8,
    picnic_in_tau_init, picnic_in_tau, picnic_in_seed0, picnic_in_seed1, picnic_in_seed2, picnic_in_seed3,
    picnic_in_aux, picnic_in_input0, picnic_in_input1, picnic_in_msgs,
    picnic_in_commit0, picnic_in_commit1, picnic_in_commit2, picnic_in_commit3, picnic_in_end,
    picnic_start,
    picnic_bram0, picnic_bram1, 
    picnic_judge0, picnic_seedpre, picnic_judge1,
    picnic_pipe0, picnic_pipe1,
    picnic_cv_tree0,
    picnic_hcp_start, picnic_hcp,
    picnic_reject, picnic_success);
  signal State_DN, State_DP : states;

  -- registers
  signal SK_DN, SK_DP : std_logic_vector(PICNIC_S downto 0);
  signal PC_DN, PC_DP : std_logic_vector(PICNIC_S downto 0);
  signal PP_DN, PP_DP : std_logic_vector(PICNIC_S downto 0);
  signal MSG_DN, MSG_DP : std_logic_vector(MSG_LEN - 1 downto 0);
  signal Seed_DN, Seed_DP : SEED_ARR;
  signal Seed_com_DN, Seed_com_DP : SEED_ARR;
  signal Tape_DN, Tape_DP : R_N_2_ARR;
  signal Tape_last_DN, Tape_last_DP : std_logic_vector(R * N - 1 downto 0);
  --type DIG_C_ARR is  array(0 to 5) of std_logic_vector(DIGEST_L - 1 downto 0);
  --signal Dig_c_DN, Dig_c_DP : DIG_C_ARR;
  type DIG_V_ARR is  array(0 to 1) of std_logic_vector(DIGEST_L - 1 downto 0);
  signal Dig_v_DN, Dig_v_DP : DIG_V_ARR;
  signal Input_DN, Input_DP : std_logic_vector(N - 1 downto 0);
  --signal Msgs_in_DP, Msgs_in_DN : MSGS_IN_ARR;
  signal Tree_DN, Tree_DP : std_logic_vector(numnodes - 1 downto 0);
  signal C_DN, C_DP : std_logic_vector(T - 1 downto 0);
  signal P_DN, P_DP : std_logic_vector(2 * tau - 1 downto 0);
  signal Challenge_DN, Challenge_DP : std_logic_vector(DIGEST_L - 1 downto 0);
  signal ET_DN, ET_DP : integer range 0 to P - 1;
  type MSGS_INT_ARR is array(0 to 1) of integer range 0 to P - 1;
  signal Msgs_ET_DN, Msgs_ET_DP : MSGS_INT_ARR;
  signal Aux_DN, Aux_DP : std_logic_vector(R * N - 1 downto 0);
  signal Msgs_verify_DN, Msgs_verify_DP : std_logic_vector(R * N - 1 downto 0);
  signal Msgs_DN, Msgs_DP : R_N_ARR;
  signal ComC_DN, ComC_DP : DIGE_ARR;
  signal Read_len_DN, Read_len_DP : integer range 0 to MAX_SIG;
  signal Sig_len_DN, Sig_len_DP : integer range 0 to MAX_SIG;
  signal Salt_DN, Salt_DP : std_logic_vector(SALT_LEN - 1 downto 0);
  signal CH_DN, CH_DP : std_logic_vector(DIGEST_L - 1 downto 0);
  signal PDI_DN, PDI_DP : std_logic_vector(PDI_WIDTH - 1 downto 0);
  
  -- components
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

  component seed_verify is
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
      signal Seed_DO     : out SEED_ARR
    );
  end component;

  component tape is
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
  end component;

  component commitV is
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
      signal Commit_DO   : out std_logic_vector(DIGEST_L - 1 downto 0)
    );
  end component;

  component lowmc_mpc_verify is
    port(
      -- Clock and Reset
      signal Clk_CI   : in std_logic;
      signal Rst_RI   : in std_logic;
      -- Input signals
      signal Plain_DI  : in std_logic_vector(N - 1 downto 0);
      signal MK_DI     : in std_logic_vector(N - 1 downto 0);
      signal Tape_DI : in R_N_2_ARR;
      signal Tape_last_DI : in std_logic_vector(R * N- 1 downto 0);
      signal Aux_DI : in std_logic_vector(R * N- 1 downto 0);
      signal Aux_SI    : in std_logic;
      signal Sim_SI    : in std_logic;
      signal Msgs_DI   : in std_logic_vector(R * N - 1 downto 0);
      signal ET_DP     : in integer range 0 to P; -- when ET_DP is P, then this instance is opened
      -- Output signals
      signal Finish_SO : out std_logic;
      signal Input_out : out std_logic_vector(N - 1 downto 0);
      signal Aux_out   : out std_logic_vector(R * N - 1 downto 0);
      signal Cipher_DO : out std_logic_vector(N - 1 downto 0);
      signal Msgs_DO : out R_N_ARR
    );
  end component;

  component commitC is
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
      signal Commit_DO   : out DIGE_ARR
    );
  end component;


  component commitH is
    port(
      -- Clock and Reset
      signal Clk_CI      : in std_logic;
      signal Rst_RI      : in std_logic;
      -- Input signals
      signal Start_SI    : in std_logic;
      signal Next_SI     : in std_logic;
      signal Dig_DI     : in DIGE_ARR;
      -- Output signals
      signal Finish_SO   : out std_logic;
      signal Commit_DO   : out std_logic_vector(DIGEST_L - 1 downto 0)
    );
  end component;

  component cvtree_verify is
    port(
      -- Clock and Reset
      signal Clk_CI      : in std_logic;
      signal Rst_RI      : in std_logic;
      -- Input signals
      signal Start_SI    : in std_logic;
      signal Next_SI     : in std_logic;
      signal Veri_SI     : in std_logic;
      signal Salt_DI     : in std_logic_vector(SALT_LEN - 1 downto 0);
      signal Tree_DI     : in std_logic_vector(numnodes - 1 downto 0);
      signal Cv_Ad_DI  : in integer range 0 to 4 * T + 10;
      signal CV_DI      : in std_logic_vector(CV_DATA_WIDTH - 1 downto 0);
      signal CV_WE      : in std_logic;
      signal Dig0_DI     : in std_logic_vector(DIGEST_L - 1 downto 0);
      signal Dig1_DI     : in std_logic_vector(DIGEST_L - 1 downto 0);
      -- Output signals
      signal Ready_SO    : out std_logic;
      signal Dig_DO      : out std_logic_vector(DIGEST_L - 1 downto 0)
    );
  end component;

  component hcp_verify is
    port(
      -- Clock and Reset
      signal Clk_CI      : in std_logic;
      signal Rst_RI      : in std_logic;
      -- Input signals
      signal Start_SI    : in std_logic;
      signal Verify_SI  : in std_logic;
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
      signal Sig_Len_DO  : out integer range 0 to MAX_SIG
    );
  end component;

begin


  SEED_I_RAM : xilinx_TDP_RAM
  generic map(
    ADDR_WIDTH => SEED_I_ADDR_WIDTH,
    DATA_WIDTH => SEED_I_DATA_WIDTH,
    ENTRIES => SEED_I_ENTRIES
  )
  port map(
    clk => clk,
    addra => seed_i_addra,
    addrb => seed_i_addrb,
    dina => seed_i_dina,
    dinb => seed_i_dinb,
    wea => seed_i_wea,
    web => seed_i_web,
    ena => '1',
    enb => '1',
    douta => seed_i_douta,
    doutb => seed_i_doutb
  );


  iSEED : seed_verify
  port map (
    Clk_CI      => clk,
    Rst_RI      => rst,
    Start_SI    => seed_start,
    Next_SI     => seed_next,
    Salt_DI     => Salt_DP,
    Tree_DI     => Tree_DP,
    Seed_Ad_DI  => seed_addr,
    Seed_DI     => seed_din,
    Seed_WE     => seed_we,
    Ready_SO    => seed_ready,
    Seed_DO   => seed_out
  );

  TAPES : tape
  port map (
    Clk_CI    => clk,
    Rst_RI    => rst,
    Start_SI  => tape_start,
    Seed_DI => Seed_DP,
    Salt_DI   => Salt_DP,
    Rd_Ad_DI  => tape_round_in,
    Finish_SO => tape_finish,
    Tape_DO => tape_out,
    Tape_last_DO => tape_last_out
  );

  AUX_SIM_LOWMC : lowmc_mpc_verify
  port map (
    Clk_CI => clk,
    Rst_RI => rst,
    Plain_DI => PP_DP(PICNIC_S - 2 downto 0),
    MK_DI => Input_DP,
    Tape_DI => Tape_DP,
    Tape_last_DI => tape_last_DP,
    Aux_DI => Aux_DP,
    Aux_SI => aux_start,
    Sim_SI => sim_start,
    Finish_SO => lowmc_finish,
    Input_out => input_out,
    Msgs_DI => Msgs_verify_DP,
    ET_DP => MSGS_ET_DP(1),
    Aux_out => aux_out,
    Cipher_DO => lowmc_cipher,
    Msgs_DO => msgs_out
  );

  CV : commitV
  port map(
    Clk_CI      => clk,
    Rst_RI      => rst,
    Start_SI    => commV_start,
    Inputs_DI   => Input_DP,
    Ms_DI       => Msgs_DP,
    Finish_SO   => commV_finish,
    Commit_DO   => commV_out
  );

  C : commitC
  port map(
    Clk_CI      => clk,
    Rst_RI      => rst,
    Start_SI    => commC_start,
    Salt_DI     => Salt_DP,
    Seed_DI   => Seed_com_DP,
    Aux_DI      => Aux_DP,
    Round_DI    => Counter_DP,
    Finish_SO   => commC_finish,
    Commit_DO => commC_out
  );


  CH : commitH
  port map(
    Clk_CI    => clk,
    Rst_RI    => rst,
    Start_SI  => commH_start,
    Next_SI  => commH_next,
    Dig_DI  => ComC_DP,
    Finish_SO => commH_finish,
    Commit_DO => commH_out
  );


  AUX_BRAM : xilinx_TDP_RAM
  generic map(
    ADDR_WIDTH => AUX_ADDR_WIDTH,
    DATA_WIDTH => AUX_DATA_WIDTH,
    ENTRIES => AUX_ENTRIES
  )
  port map(
    clk => clk,
    addra => aux_addra,
    addrb => aux_addrb,
    dina => aux_dina,
    dinb => aux_dinb,
    wea => aux_wea,
    web => aux_web,
    ena => '1',
    enb => '1',
    douta => aux_douta,
    doutb => aux_doutb
  );

  -- COMMH_BRAM : xilinx_TDP_RAM
  -- generic map(
  --   ADDR_WIDTH => COMMH_ADDR_WIDTH,
  --   DATA_WIDTH => COMMH_DATA_WIDTH,
  --   ENTRIES => COMMH_ENTRIES
  -- )
  -- port map(
  --   clk => clk,
  --   addra => commh_addra,
  --   addrb => commh_addrb,
  --   dina => commh_dina,
  --   dinb => commh_dinb,
  --   wea => commh_wea,
  --   web => commh_web,
  --   ena => '1',
  --   enb => '1',
  --   douta => commh_douta,
  --   doutb => commh_doutb
  -- );

  COMMV_BRAM : xilinx_TDP_RAM
  generic map(
    ADDR_WIDTH => COMMV_ADDR_WIDTH,
    DATA_WIDTH => COMMV_DATA_WIDTH,
    ENTRIES => COMMV_ENTRIES
  )
  port map(
    clk => clk,
    addra => commv_addra,
    addrb => commv_addrb,
    dina => commv_dina,
    dinb => commv_dinb,
    wea => commv_wea,
    web => commv_web,
    ena => '1',
    enb => '1',
    douta => commv_douta,
    doutb => commv_doutb
  );
  
  INPUT_BRAM : xilinx_TDP_RAM
    generic map(
      ADDR_WIDTH => INPUT_ADDR_WIDTH,
      DATA_WIDTH => INPUT_DATA_WIDTH,
      ENTRIES => INPUT_ENTRIES
    )
    port map(
      clk => clk,
      addra => input_addra,
      addrb => input_addrb,
      dina => input_dina,
      dinb => input_dinb,
      wea => input_wea,
      web => input_web,
      ena => '1',
      enb => '1',
      douta => input_douta,
      doutb => input_doutb
    );

  COMMC_BRAM : for i in 0 to P - 1 generate
    CommitC_BRAM : xilinx_TDP_RAM
    generic map(
      ADDR_WIDTH => COMMC_ADDR_WIDTH,
      DATA_WIDTH => COMMC_DATA_WIDTH,
      ENTRIES => COMMC_ENTRIES
    )
    port map(
      clk => clk,
      addra => commc_addra,
      addrb => commc_addrb,
      dina => commc_dina(i),
      dinb => commc_dinb(i),
      wea => commc_wea(i),
      web => commc_web(i),
      ena => '1',
      enb => '1',
      douta => commc_douta(i),
      doutb => commc_doutb(i)
    );
  end generate;

  MSGS_BRAM : for i in 0 to P - 1 generate
    MSGS_i_BRAM : xilinx_TDP_RAM
    generic map(
      ADDR_WIDTH => MSGS_ADDR_WIDTH,
      DATA_WIDTH => MSGS_DATA_WIDTH,
      ENTRIES => MSGS_ENTRIES
    )
    port map(
      clk => clk,
      addra => msgs_addra,
      addrb => msgs_addrb,
      dina => msgs_dina(i),
      dinb => msgs_dinb(i),
      wea => msgs_wea(i),
      web => msgs_web(i),
      ena => '1',
      enb => '1',
      douta => msgs_douta(i),
      doutb => msgs_doutb(i)
    );
  end generate;

  TREE_FOR_CV : cvtree_verify
  port map (
      Clk_CI   => clk,
      Rst_RI   => rst,
      Start_SI => CV_start,
      Next_SI  => CV_next,
      Veri_SI => CV_veri,
      Salt_DI  => Salt_DP,
      Tree_DI  => Tree_DP,
      Cv_Ad_DI => CV_addr_in,
      CV_DI   => CV_din,
      CV_WE   => CV_we,
      Dig0_DI  => Dig_v_DP(0),
      Dig1_DI  => Dig_v_DP(1),
      Ready_SO => CV_finish,
      Dig_DO   => CV_out
  );
  
  Challenge : hcp_verify
  port map (
    Clk_CI      => clk,
    Rst_RI      => rst,
    Start_SI    => Chal_start,
    Verify_SI   => Chal_verify,
    Salt_DI     => Salt_DP,
    Challenge_DI=> Challenge_DP,
    Ch_DI       => commH_out,
    Cv_tree0_DI => CV_out,
    Plain_DI    => PP_DP(PICNIC_S - 2 downto 0),
    Cipher_DI   => PC_DP(PICNIC_S - 2 downto 0),
    Message_DI  => MSG_DP,
    Ready_SO    => Chal_finish,
    ChallengeC  => Chal_C,
    ChallengeP  => Chal_P,
    Dig_DO      => Chal_out,
    Tree_Do     => Tree_out,
    Sig_Len_DO  => Sig_Len_out
  );


  -- output logic
  process (State_DP, pdi_valid, pdi_data, CH_DP, PDI_DP, lowmc_finish, tape_finish, Msgs_verify_DP, Read_len_DP, Sig_len_DP, Salt_DP, commC_finish, Challenge_DP, commH_finish, Sig_Len_out, pdo_ready, Chal_out, Counter_DP, ComC_DP, Msgs_DP, Aux_DP, Counter_Trans_DP, PC_DP, Tape_last_DP, Tape_DP, tape_out, tape_last_out, PP_DP, MSG_DP, SK_DP, seed_i_douta, seed_i_doutb, seed_out, Seed_DP, Seed_com_DP, seed_ready, tape_out, msgs_out, lowmc_cipher, input_out, aux_out, commV_finish, commV_out, Input_DP, commC_out, commc_douta, commc_doutb, aux_douta, aux_doutb, commv_douta, commv_doutb, msgs_douta, msgs_doutb, input_douta, input_doutb, Dig_v_DP, cv_finish, CV_out, Tree_DP, C_DP, P_DP,Msgs_ET_DP, ET_DP, Counter_tau_DP, Tree_out, Chal_C, Chal_P)
    variable ET_VEC : std_logic_vector(1 downto 0);
    variable ET : integer range 0 to P - 1;
  begin
    -- default
     

    pdi_ready <= '0';
    --pdo_last <= '0'; -- not use
    SK_DN <= SK_DP;
    Counter_DN <= Counter_DP;
    --Counter_Com_DN <= Counter_Com_DP;
    Counter_Trans_DN <= Counter_Trans_DP;
    Counter_Tau_DN <= Counter_Tau_DP;
    PC_DN <= PC_DP;
    PP_DN <= PP_DP;
    MSG_DN <= MSG_DP;
    Input_DN <= Input_DP;
    --Input_bram_DN <= Input_bram_DP;
    --Msgs_in_DN <= Msgs_in_DP;
    Seed_DN <= Seed_DP;
    Seed_com_DN <= Seed_com_DP;
    --Dig_c_DN <= Dig_c_DP;
    Dig_v_DN <= Dig_v_DP;
    Tree_DN <= Tree_DP;
    C_DN <= C_DP;
    P_DN <= P_DP;
    ET_DN <= ET_DP;
    Aux_DN <= Aux_DP;
    Tape_DN <= Tape_DP;
    Tape_last_DN <= Tape_last_DP;
    Msgs_DN <= Msgs_DP;
    ComC_DN <= ComC_DP;
    Challenge_DN <= Challenge_DP;
    Read_len_DN <= Read_len_DP;
    Sig_len_DN <= Sig_len_DP;
    Salt_DN <= Salt_DP;
    Msgs_verify_DN <= Msgs_verify_DP;
    Msgs_ET_DN <= Msgs_ET_DP;
    CH_DN <= CH_DP;
    PDI_DN <= PDI_DP;

    pdo_data <= (others => '0');
    pdo_valid <= '0';
    pdo_last <= '0';
    status_ready <= '0';
    
    

    -- seed bram
    seed_i_addra <= (others => '0');
    seed_i_addrb <= (others => '0');
    seed_i_dina <= (others => '0');
    seed_i_dinb <= (others => '0');
    seed_i_wea <= '0';
    seed_i_web <= '0';

    -- aux bram
    aux_addra <= (others => '0');
    aux_addrb <= (others => '0');
    aux_dina <= (others => '0');
    aux_dinb <= (others => '0');
    aux_wea <= '0';
    aux_web <= '0';
    
    -- input bram
    input_addra <= (others => '0');
    input_addrb <= (others => '0');
    input_dina <= (others => '0');
    input_dinb <= (others => '0');
    input_wea <= '0';
    input_web <= '0';

    -- commc bram
    commc_addra <= (others => '0');
    commc_addrb <= (others => '0');
    commc_dina <= (others => (others => '0'));
    commc_dinb <= (others => (others => '0'));
    commc_wea <= (others => '0');
    commc_web <= (others => '0');

    -- -- commh bram
    -- commh_addra <= (others => '0');
    -- commh_addrb <= (others => '0');
    -- commh_dina <= (others => '0');
    -- commh_dinb <= (others => '0');
    -- commh_wea <= '0';
    -- commh_web <= '0';

    -- commv bram
    commv_addra <= (others => '0');
    commv_addrb <= (others => '0');
    commv_dina <= (others => '0');
    commv_dinb <= (others => '0');
    commv_wea <= '0';
    commv_web <= '0';

    -- msgs bram
    msgs_addra <= (others => '0');
    msgs_addrb <= (others => '0');
    msgs_dina <= (others => (others => '0'));
    msgs_dinb <= (others => (others => '0'));
    msgs_wea <= (others => '0');
    msgs_web <= (others => '0');

    -- seed
    seed_start <= '0';
    seed_next <= '0';
    seed_addr <= (others => '0');
    seed_din <= (others => '0');
    seed_we <= '0';

    -- tape
    -- tape_round_in <= (others => '0');
    tape_round_in <= std_logic_vector(to_unsigned(Counter_DP, 16));
    tape_start <= '0';

    -- lowmc
    aux_start <= '0';
    sim_start <= '0';
    --masked_key_in <= (others => '0');

    -- commit view
    commV_start <= '0';
    --commV_input <= (others => '0');
    --msgs_in <= (others => (others => '0'));

    -- commit C
    commC_start <= '0';

    -- commit H
    commH_start <= '0';
    commH_next <= '0';


    -- cv tree
    CV_start <= '0';
    CV_next <= '0';
    CV_veri <= '0';
    CV_addr_in <= 0;
    CV_din <= (others => '0');
    CV_we <= '0';

    --hcp
    Chal_start <= '0';
    Chal_verify <= '0';

    

    case State_DP is
      --when debug =>
      --  SK_DN <= KE;
      --  PC_DN <= CI;
      --  PP_DN <= PL;
      --  MSG_DN <= ME;
      when init =>
        pdi_ready <= '1';
      when read_pub_c0 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          PC_DN(PICNIC_S - 2 downto PICNIC_S - PDI_WIDTH - 1) <= pdi_data;
        end if;
      when read_pub_c1 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          PC_DN(PICNIC_S - PDI_WIDTH - 2 downto 0) <= pdi_data(PDI_WIDTH - 1 downto 1);
        end if;
      when read_pub_p0 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          PP_DN(PICNIC_S - 2 downto PICNIC_S - PDI_WIDTH - 1)  <= pdi_data;
        end if;
      when read_pub_p1 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          PP_DN(PICNIC_S - PDI_WIDTH - 2 downto 0) <= pdi_data(PDI_WIDTH - 1 downto 1);
        end if;
      when inst_ver =>
        pdi_ready <= '1';
        Counter_DN <= 0;
      when read_msg =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          Counter_DN <= Counter_DP + 1;
          MSG_DN(MSG_LEN - 1 downto PDI_WIDTH) <= MSG_DP(MSG_LEN - PDI_WIDTH - 1 downto 0);
          MSG_DN(PDI_WIDTH - 1 downto 0) <= pdi_data;
        end if;
      when picnic_in_header =>
        pdi_ready <= '1';
        Counter_DN <= 0;
        Read_len_DN <= 0;
        Sig_Len_DN <= to_integer(unsigned(pdi_data(111 downto 96)));
      when picnic_in_chal0 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          Challenge_DN(DIGEST_L - 1 downto DIGEST_L - PDI_WIDTH) <= pdi_data;
        end if;
      when picnic_in_chal1 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          Challenge_DN(DIGEST_L - PDI_WIDTH - 1 downto DIGEST_L - PDI_WIDTH - PDI_WIDTH) <= pdi_data;
        end if;
      when picnic_in_chal2 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          Challenge_DN(DIGEST_L - PDI_WIDTH - PDI_WIDTH - 1 downto DIGEST_L - PDI_WIDTH - PDI_WIDTH - PDI_WIDTH) <= pdi_data;
        end if;
      when picnic_in_chal3 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          Challenge_DN(DIGEST_L - PDI_WIDTH - PDI_WIDTH - PDI_WIDTH - 1 downto DIGEST_L - PDI_WIDTH - PDI_WIDTH - PDI_WIDTH -PDI_WIDTH) <= pdi_data;
        end if;
      when picnic_hcp_verify =>
        Chal_verify <= '1';
      when picnic_in_salt0 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          Salt_DN(SALT_LEN - 1 downto SALT_LEN - PDI_WIDTH) <= pdi_data;
        end if;
      when picnic_in_salt1 =>
        if Chal_finish = '1' then
          pdi_ready <= '1';
          if pdi_valid = '1' then
            Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
            Salt_DN(SALT_LEN - PDI_WIDTH - 1 downto SALT_LEN - PDI_WIDTH - PDI_WIDTH) <= pdi_data;
          end if;
          C_DN <= Chal_C;
          P_DN <= Chal_P;
          Tree_DN <= Tree_out;
        end if;
      when picnic_in_seed_0 =>
        if Tree_DP(0) = '1' then
          pdi_ready <= '1';
          if pdi_valid = '1' then
            PDI_DN <= pdi_data;
            Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          end if;
        else
          Counter_DN <= Counter_DP + 1;
          Tree_DN <= Tree_DP(0) & Tree_DP(numnodes - 1 downto 1);
        end if;
      when picnic_in_seed_1 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          seed_addr <= std_logic_vector(to_unsigned(Counter_DP, SEED_ADDR_WIDTH));
          seed_we <= '1';
          seed_din <= PDI_DP & pdi_data;
          Counter_DN <= Counter_DP + 1;
          Tree_DN <= Tree_DP(0) & Tree_DP(numnodes - 1 downto 1);
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_cv0 =>
        Counter_DN <= 0;
      when picnic_in_cv1 =>
        if Tree_DP(0) = '1' then
          pdi_ready <= '1';
          if pdi_valid = '1' then
            PDI_DN <= pdi_data;
            Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          end if;
        else
          Counter_DN <= Counter_DP + 1;
          CV_addr_in <= Counter_DP + 1;
          Tree_DN <= Tree_DP(0) & Tree_DP(numnodes - 1 downto 1);
        end if;
      when picnic_in_cv2 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          CV_addr_in <= 2 * Counter_DP;
          CV_din <= PDI_DP & pdi_data;
          CV_we <= '1';
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_cv3 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          PDI_DN <= pdi_data;
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_cv4 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          CV_addr_in <= 2 * Counter_DP + 1;
          CV_din <= PDI_DP & pdi_data;
          CV_we <= '1';
          Counter_DN <= Counter_DP + 1;
          Tree_DN <= Tree_DP(0) & Tree_DP(numnodes - 1 downto 1);
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_cv5 =>
        if Tree_DP(0) = '1' then
          pdi_ready <= '1';
          commv_addra <= std_logic_vector(to_unsigned(8 * Counter_DP - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
          commv_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 1 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
          commv_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH);
          commv_dinb <= pdi_data(PDI_WIDTH - COMMV_DATA_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH - COMMV_DATA_WIDTH);
          
          if pdi_valid = '1' then
            commv_wea <= '1';
            commv_web <= '1';
            Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
          end if;
        else
          Counter_DN <= Counter_DP + 1;
          Tree_DN <= Tree_DP(0) & Tree_DP(numnodes - 1 downto 1);
        end if;
      when picnic_in_cv6 =>
        pdi_ready <= '1';
        commv_addra <= std_logic_vector(to_unsigned(8 * Counter_DP + 2 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
        commv_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 3 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
        commv_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH);
        commv_dinb <= pdi_data(PDI_WIDTH - COMMV_DATA_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH - COMMV_DATA_WIDTH);
        
        if pdi_valid = '1' then
          commv_wea <= '1';
          commv_web <= '1';
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_cv7 =>
        pdi_ready <= '1';
        commv_addra <= std_logic_vector(to_unsigned(8 * Counter_DP + 4 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
        commv_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 5 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
        commv_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH);
        commv_dinb <= pdi_data(PDI_WIDTH - COMMV_DATA_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH - COMMV_DATA_WIDTH);
        
        if pdi_valid = '1' then
          commv_wea <= '1';
          commv_web <= '1';
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_cv8 =>
        pdi_ready <= '1';
        commv_addra <= std_logic_vector(to_unsigned(8 * Counter_DP + 6 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
        commv_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 7 - 8 * FIRST_LEAF, commv_ADDR_WIDTH));
        commv_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH);
        commv_dinb <= pdi_data(PDI_WIDTH - COMMV_DATA_WIDTH - 1 downto PDI_WIDTH - COMMV_DATA_WIDTH - COMMV_DATA_WIDTH);
        
        if pdi_valid = '1' then
          commv_wea <= '1';
          commv_web <= '1';
          Counter_DN <= Counter_DP + 1;
          Tree_DN <= Tree_DP(0) & Tree_DP(numnodes - 1 downto 1);
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_tau_init =>
        Counter_DN <= 0;
        Counter_tau_DN <= 0;
      when picnic_in_tau =>
        if C_DP(0) = '1' then
        else
          Counter_DN <= Counter_DP + 1;
          C_DN <= C_DP(0) & C_DP(T - 1 downto 1);
        end if;
      when picnic_in_seed0 =>
        seed_i_addra <= std_logic_vector(to_unsigned(4 * Counter_DP, SEED_I_ADDR_WIDTH));
        seed_i_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 1, SEED_I_ADDR_WIDTH));
        -- ET
        ET_VEC := P_DP(2 * tau - 1 downto 2 * tau - 2);
        ET := to_integer(unsigned(ET_VEC));
        ET_DN <= ET;
        
        pdi_ready <= '1';
        for i in 0 to P - 1 loop
          seed_i_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH);
          seed_i_dinb <= pdi_data(PDI_WIDTH - SEED_I_DATA_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH - SEED_I_DATA_WIDTH);
        end loop;
        if pdi_valid = '1' then
          seed_i_wea <= '1';
          seed_i_web <= '1';
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_seed1 =>
        seed_i_addra <= std_logic_vector(to_unsigned(4 * Counter_DP + 2, SEED_I_ADDR_WIDTH));
        seed_i_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 3, SEED_I_ADDR_WIDTH));
        
        pdi_ready <= '1';
        for i in 0 to P - 1 loop
          seed_i_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH);
          seed_i_dinb <= pdi_data(PDI_WIDTH - SEED_I_DATA_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH - SEED_I_DATA_WIDTH);
        end loop;
        if pdi_valid = '1' then
          seed_i_wea <= '1';
          seed_i_web <= '1';
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_seed2 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          PDI_DN <= pdi_data;
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
      when picnic_in_seed3 =>
        pdi_ready <= '1';
        case ET_DP is
          when 0 =>
            seed_addr <= std_logic_vector(to_unsigned(2 * (FIRST_LEAF + Counter_DP) + 2, SEED_ADDR_WIDTH));
          when 1 =>
            seed_addr <= std_logic_vector(to_unsigned(2 * (FIRST_LEAF + Counter_DP) + 2, SEED_ADDR_WIDTH));
          when 2 =>
            seed_addr <= std_logic_vector(to_unsigned(2 * (FIRST_LEAF + Counter_DP) + 1, SEED_ADDR_WIDTH));
          when others =>
            seed_addr <= std_logic_vector(to_unsigned(2 * (FIRST_LEAF + Counter_DP) + 1, SEED_ADDR_WIDTH));
        end case;
        if pdi_valid = '1' then
          seed_we <= '1';
          seed_din <= PDI_DP & pdi_data;
          Read_len_DN <= Read_len_DP + PDI_WIDTH / 8;
        end if;
        -- next
        Counter_Trans_DN <= 0;
      when picnic_in_aux =>
        pdi_ready <= '1';
        -- next
        if pdi_valid = '1' then
          aux_addra <= std_logic_vector(to_unsigned(ENTRIE_PER_AM * Counter_DP + Counter_Trans_DP + 0, AUX_ADDR_WIDTH));
          aux_addrb <= std_logic_vector(to_unsigned(ENTRIE_PER_AM * Counter_DP + Counter_Trans_DP + 1, AUX_ADDR_WIDTH));
          aux_wea <= '1';
          aux_web <= '1';
          aux_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - AUX_DATA_WIDTH);
          aux_dinb <= pdi_data(PDI_WIDTH - AUX_DATA_WIDTH - 1 downto PDI_WIDTH - AUX_DATA_WIDTH - AUX_DATA_WIDTH);
          Counter_Trans_DN <= Counter_Trans_DP + 2;
        end if;
      when picnic_in_input0 =>
        pdi_ready <= '1';

        if pdi_valid = '1' then
          input_addra <= std_logic_vector(to_unsigned(4 * Counter_DP, INPUT_ADDR_WIDTH));
          input_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 1, INPUT_ADDR_WIDTH));
          input_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH);
          input_dinb <= pdi_data(PDI_WIDTH - SEED_I_DATA_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH - SEED_I_DATA_WIDTH);
          input_wea <= '1';
          input_web <= '1';
        end if;
      when picnic_in_input1 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          input_addra <= std_logic_vector(to_unsigned(4 * Counter_DP + 2, INPUT_ADDR_WIDTH));
          input_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 3, INPUT_ADDR_WIDTH));
          input_dina <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH);
          input_dinb <= pdi_data(PDI_WIDTH - SEED_I_DATA_WIDTH - 1 downto PDI_WIDTH - SEED_I_DATA_WIDTH - SEED_I_DATA_WIDTH);
          input_wea <= '1';
          input_web <= '1';
          Counter_Trans_DN <= 0;
        end if;
      when picnic_in_msgs =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          msgs_addra <= std_logic_vector(to_unsigned(ENTRIE_PER_AM * Counter_DP + Counter_Trans_DP, MSGS_ADDR_WIDTH));
          msgs_addrb <= std_logic_vector(to_unsigned(ENTRIE_PER_AM * Counter_DP + Counter_Trans_DP + 1, MSGS_ADDR_WIDTH));  
          Counter_Trans_DN <= Counter_Trans_DP + 2;
          msgs_wea(ET_DP) <= '1';
          msgs_web(ET_DP) <= '1';
          msgs_dina(ET_DP) <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - MSGS_DATA_WIDTH);
          msgs_dinb(ET_DP) <= pdi_data(PDI_WIDTH - MSGS_DATA_WIDTH - 1 downto PDI_WIDTH - MSGS_DATA_WIDTH - MSGS_DATA_WIDTH);
        end if;
      when picnic_in_commit0 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          commc_addra <= std_logic_vector(to_unsigned(8 * Counter_DP, COMMC_ADDR_WIDTH));
          commc_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 1, COMMC_ADDR_WIDTH));
          commc_dina(ET_DP) <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH);
          commc_dinb(ET_DP) <= pdi_data(PDI_WIDTH - COMMC_DATA_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH - COMMC_DATA_WIDTH);
          commc_wea(ET_DP) <= '1';
          commc_web(ET_DP) <= '1';
        end if;
      when picnic_in_commit1 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          commc_addra <= std_logic_vector(to_unsigned(8 * Counter_DP + 2, COMMC_ADDR_WIDTH));
          commc_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 3, COMMC_ADDR_WIDTH));
          commc_dina(ET_DP) <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH);
          commc_dinb(ET_DP) <= pdi_data(PDI_WIDTH - COMMC_DATA_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH - COMMC_DATA_WIDTH);
          commc_wea(ET_DP) <= '1';
          commc_web(ET_DP) <= '1';
        end if;
      when picnic_in_commit2 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          commc_addra <= std_logic_vector(to_unsigned(8 * Counter_DP + 4, COMMC_ADDR_WIDTH));
          commc_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 5, COMMC_ADDR_WIDTH));
          commc_dina(ET_DP) <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH);
          commc_dinb(ET_DP) <= pdi_data(PDI_WIDTH - COMMC_DATA_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH - COMMC_DATA_WIDTH);
          commc_wea(ET_DP) <= '1';
          commc_web(ET_DP) <= '1';
        end if;
      when picnic_in_commit3 =>
        pdi_ready <= '1';
        if pdi_valid = '1' then
          commc_addra <= std_logic_vector(to_unsigned(8 * Counter_DP + 6, COMMC_ADDR_WIDTH));
          commc_addrb <= std_logic_vector(to_unsigned(8 * Counter_DP + 7, COMMC_ADDR_WIDTH));
          commc_dina(ET_DP) <= pdi_data(PDI_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH);
          commc_dinb(ET_DP) <= pdi_data(PDI_WIDTH - COMMC_DATA_WIDTH - 1 downto PDI_WIDTH - COMMC_DATA_WIDTH - COMMC_DATA_WIDTH);
          commc_wea(ET_DP) <= '1';
          commc_web(ET_DP) <= '1';
          if Counter_tau_DP < Tau - 1 then
            C_DN <= C_DP(0) & C_DP(T - 1 downto 1);
            P_DN <= P_DP(2 * tau - 3 downto 0) & P_DP(2 * tau - 1 downto 2 * tau - 2);
          end if;
          Counter_DN <= Counter_DP + 1;
          Counter_tau_DN <= Counter_tau_DP + 1;
        end if;
      when picnic_in_end =>
        C_DN <= C_DP(0) & C_DP(T - 1 downto 1);
        Counter_DN <= Counter_DP + 1;
      when picnic_start =>
        P_DN <= P_DP(2 * tau - 3 downto 0) & P_DP(2 * tau - 1 downto 2 * tau - 2);
        seed_start <= '1';
        Counter_DN <= 0;
        Counter_tau_DN <= 0;
        --Counter_Com_DN <= 1;
        CV_start <= '1';
        seed_i_addra <= std_logic_vector(to_unsigned(0, SEED_I_ADDR_WIDTH));
        seed_i_addrb <= std_logic_vector(to_unsigned(1, SEED_I_ADDR_WIDTH));
      when picnic_seedpre =>
        ET_VEC := P_DP(2 * tau - 1 downto 2 * tau - 2);
        ET := to_integer(unsigned(ET_VEC));
        ET_DN <= ET;
        if C_DP(0) = '1' then
          case ET is
            when 0 =>
              Seed_DN(1)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= seed_i_douta & seed_i_doutb;
              Seed_DN(0)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= (others => '0');
            when 1 =>
              Seed_DN(0)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= seed_i_douta & seed_i_doutb;
              Seed_DN(1)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= (others => '0');
            when 2 =>
              Seed_DN(3)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= seed_i_douta & seed_i_doutb;
              Seed_DN(2)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= (others => '0');
            when others =>
              Seed_DN(2)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= seed_i_douta & seed_i_doutb;
              Seed_DN(3)(PICNIC_S - 1 downto PICNIC_S - SEED_I_DATA_WIDTH * 2) <= (others => '0');
          end case;
        end if;
        seed_i_addra <= std_logic_vector(to_unsigned(4 * Counter_DP + 2, SEED_I_ADDR_WIDTH));
        seed_i_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 3, SEED_I_ADDR_WIDTH));
      when picnic_judge0 =>
        seed_i_addra <= std_logic_vector(to_unsigned(4 * Counter_DP + 2, SEED_I_ADDR_WIDTH));
        seed_i_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 3, SEED_I_ADDR_WIDTH));
        
        if seed_ready = '1' and lowmc_finish = '1' and commV_finish = '1' and tape_finish = '1' and cv_finish = '1' then
          
          Dig_v_DN(0) <= Dig_v_DP(1);
          if Counter_DP = T + 3 then
            Dig_v_DN(1) <= (others => '0');
          else
            if C_DP(T - 3) = '1' then
              Dig_v_DN(1) <= commV_out;
            else
              Dig_v_DN(1) <= CH_DP;
            end if;
          end if;
          
          for i in 0 to P - 1 loop
            Seed_com_DN(i) <= Seed_DP(i);
            Seed_DN(i) <= seed_out(i);
          end loop;

          if C_DP(0) = '1' then
            case ET_DP is
              when 0 =>
                Seed_DN(1)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= seed_i_douta & seed_i_doutb;
                Seed_DN(0)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= (others => '0');
              when 1 =>
                Seed_DN(0)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= seed_i_douta & seed_i_doutb;
                Seed_DN(1)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= (others => '0');
              when 2 =>
                Seed_DN(3)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= seed_i_douta & seed_i_doutb;
                Seed_DN(2)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= (others => '0');
              when others =>
                Seed_DN(2)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= seed_i_douta & seed_i_doutb;
                Seed_DN(3)(PICNIC_S - SEED_I_DATA_WIDTH * 2 - 1 downto 0) <= (others => '0');
            end case;
          end if;
          

          Msgs_DN <= Msgs_out;
          Tape_DN <= Tape_out;
          Tape_last_DN <= Tape_last_out;
          if C_DP(T-1) = '1' then
            if MSGS_ET_DP(1) = P - 1 then
              Tape_last_DN <= (others => '0');
            else
              Tape_DN(MSGS_ET_DP(1)) <= (others => '0');
            end if;
          end if;
          
          if C_DP(T-2) = '1' then
            Msgs_DN(MSGS_ET_DP(0)) <= Msgs_verify_DP;
          end if;
        end if;
        Counter_Trans_DN <= 0;
        
      when picnic_pipe0 =>
        tape_start <= '1';
        if Counter_DP > 0 and C_DP(T-1)='0' then
          aux_start <= '1';
        end if;
        if Counter_DP >= 4 and ((Counter_DP mod 2) = 0) and (Counter_DP <= T + 3) then
          CV_next <= '1';
          if C_DP(T-4) = '1' or C_DP(T-3) = '1' then
            CV_veri <= '1';
          end if;
        end if;
        if Counter_DP > 1 then
          commV_start <= '1';
        end if;
        seed_next <= '1';
        if Counter_DP >= 1 then
          aux_addra <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1), AUX_ADDR_WIDTH));
          aux_addrb <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 1, AUX_ADDR_WIDTH));
          msgs_addra <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1), MSGS_ADDR_WIDTH));
          msgs_addrb <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 1, MSGS_ADDR_WIDTH));
        end if;
        if  Counter_DP >= 2 then
          commc_addra <= std_logic_vector(to_unsigned(4 * (Counter_DP - 2), COMMC_ADDR_WIDTH));
          commc_addrb <= std_logic_vector(to_unsigned(4 * (Counter_DP - 2) + 1, COMMC_ADDR_WIDTH));
        end if;
        
      when picnic_bram0 =>
        Counter_Trans_DN <= Counter_Trans_DP + 1;
        if Counter_DP >= 1 then
          aux_addra <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * Counter_Trans_DP + 2, AUX_ADDR_WIDTH));
          aux_addrb <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * Counter_Trans_DP + 2 + 1, AUX_ADDR_WIDTH));
          Aux_DN(2 * AUX_DATA_WIDTH - 1 downto 0) <= aux_douta & aux_doutb;
          Aux_DN(R * N - 1 downto 2 * AUX_DATA_WIDTH) <= AUX_DP(R * N - 2 * AUX_DATA_WIDTH - 1 downto 0);
          input_addra <= std_logic_vector(to_unsigned(4 * (Counter_DP - 1) + 2, INPUT_ADDR_WIDTH));
          input_addrb <= std_logic_vector(to_unsigned(4 * (Counter_DP - 1) + 3, INPUT_ADDR_WIDTH));
          if Counter_Trans_DP = 0 then
            Input_DN(N - 1 downto N - INPUT_DATA_WIDTH - INPUT_DATA_WIDTH) <= input_douta & input_doutb;
          else
            Input_DN(N - INPUT_DATA_WIDTH - INPUT_DATA_WIDTH - 1 downto 0) <= input_douta & input_doutb(INPUT_DATA_WIDTH - 1 downto 1);
          end if;
          
        end if;
        if  Counter_DP >= 2 then
          commc_addra <= std_logic_vector(to_unsigned(8 * (Counter_DP - 2) + 2 * Counter_Trans_DP + 2, COMMC_ADDR_WIDTH));
          commc_addrb <= std_logic_vector(to_unsigned(8 * (Counter_DP - 2) + 2 * Counter_Trans_DP + 2 + 1, COMMC_ADDR_WIDTH));
          if Counter_Trans_DP < 4 then
            ComC_DN(MSGS_ET_DP(0))(2 * COMMC_DATA_WIDTH - 1 downto 0) <= commc_douta(MSGS_ET_DP(0)) & commc_doutb(MSGS_ET_DP(0));
            ComC_DN(MSGS_ET_DP(0))(DIGEST_L - 1 downto 2 * COMMC_DATA_WIDTH) <= ComC_DP(MSGS_ET_DP(0))(DIGEST_L - 2 * COMMC_DATA_WIDTH - 1 downto 0);
          end if;
        end if;
        if Counter_DP >= 1 then
          msgs_addra <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * Counter_Trans_DP + 2, MSGS_ADDR_WIDTH));
          msgs_addrb <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * Counter_Trans_DP + 2 + 1, MSGS_ADDR_WIDTH));
          Msgs_verify_DN(2 * MSGS_DATA_WIDTH - 1 downto 0) <= msgs_douta(Msgs_ET_DN(1)) & msgs_doutb(Msgs_ET_DN(1));
          Msgs_verify_DN(R * N - 1 downto 2 * MSGS_DATA_WIDTH) <= Msgs_Verify_DP(R * N - 2 * MSGS_DATA_WIDTH - 1 downto 0);
        end if;
      when picnic_judge1 =>
        if Counter_DP >= 1 then
          aux_addra <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * 7, AUX_ADDR_WIDTH));
          aux_addrb <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * 7 + 1, AUX_ADDR_WIDTH));
          msgs_addra <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * 7, MSGS_ADDR_WIDTH));
          msgs_addrb <= std_logic_vector(to_unsigned(16 *(Counter_DP - 1) + 2 * 7 + 1, MSGS_ADDR_WIDTH));
        end if;
        if commC_finish = '1' and lowmc_finish = '1' and commH_finish = '1' then
          if Counter_DP >= 2 then
            ComC_DN <= commC_out;
            if C_DP(T-2) = '1' then
              ComC_DN(MSGS_ET_DP(0)) <= ComC_DP(MSGS_ET_DP(0));
            end if;
          end if;
          if Counter_DP >= 1 then
            if C_DP(T-1)='1' then
              Aux_DN(R * N - 2 * 7 * AUX_DATA_WIDTH - 1 downto 0) <= aux_douta(AUX_DATA_WIDTH - 1 downto 0) & aux_doutb(AUX_DATA_WIDTH - 1 downto AUX_DATA_WIDTH-(R * N - 15 * AUX_DATA_WIDTH));
              Aux_DN(R * N - 1 downto R * N - 2 * 7 * AUX_DATA_WIDTH) <= AUX_DP(2 * 7 * AUX_DATA_WIDTH - 1 downto 0);
              Msgs_verify_DN(R * N - 1 downto R * N - 2 * 7 * MSGS_DATA_WIDTH) <= Msgs_verify_DP(2 * 7 * MSGS_DATA_WIDTH - 1 downto 0);
              Msgs_verify_DN(R * N - 2 * 7 * MSGS_DATA_WIDTH - 1 downto 0) <= msgs_douta(MSGS_ET_DP(1))(MSGS_DATA_WIDTH - 1 downto 0) & msgs_doutb(MSGS_ET_DP(1))(MSGS_DATA_WIDTH - 1 downto MSGS_DATA_WIDTH-(R * N - 15 * MSGS_DATA_WIDTH));
            else
              Aux_DN <= aux_out;
            end if;
          end if;

        end if;
      when picnic_pipe1 =>
        Counter_Trans_DN <= 0;
        if (Counter_DP >= 1) and (Counter_DP < T + 1) and C_DP(T-1)='1' then
          sim_start <= '1';  
        end if;

        if Counter_DP = 2 then
          commH_start <= '1';
        elsif Counter_DP > 2 and Counter_DP <= T + 1 then
          commH_next <= '1';
        end if;
        if (Counter_DP >= 1) and (Counter_DP < T + 1) then
          commC_start <= '1';
        end if;
        Counter_DN <= Counter_DP + 1;
        C_DN <= C_DP(0) & C_DP(T - 1 downto 1);
        if C_DP(0) = '1' then
          P_DN <= P_DP(2 * tau - 3 downto 0) & P_DP(2 * tau - 1 downto 2 * tau - 2);
        end if;
        Msgs_ET_DN(1) <= ET_DP;
        Msgs_ET_DN(0) <= Msgs_ET_DP(1);
        if Counter_DP >= 2 then
          commv_addra <= std_logic_vector(to_unsigned(4 * (Counter_DP - 2), COMMH_ADDR_WIDTH));
          commv_addrb <= std_logic_vector(to_unsigned(4 * (Counter_DP - 2) + 1, COMMH_ADDR_WIDTH));
        end if;
      when picnic_bram1 =>
        Counter_Trans_DN <= Counter_Trans_DP + 1;

        -- next 
        seed_i_addra <= std_logic_vector(to_unsigned(4 * Counter_DP, SEED_I_ADDR_WIDTH));
        seed_i_addrb <= std_logic_vector(to_unsigned(4 * Counter_DP + 1, SEED_I_ADDR_WIDTH));
        if Counter_DP >= 3 then
          commv_addra <= std_logic_vector(to_unsigned(4 * (Counter_DP - 3) + 2 * Counter_Trans_DP + 2, COMMH_ADDR_WIDTH));
          commv_addrb <= std_logic_vector(to_unsigned(4 * (Counter_DP - 3) + 2 * Counter_Trans_DP + 2 + 1, COMMH_ADDR_WIDTH));
          if Counter_Trans_DP < 4 then
            CH_DN(2 * COMMH_DATA_WIDTH - 1 downto 0) <= commv_douta & commv_doutb;
            CH_DN(DIGEST_L - 1 downto 2 * COMMH_DATA_WIDTH) <= CH_DP(DIGEST_L - 2 * COMMH_DATA_WIDTH - 1 downto 0);
          end if;
        end if;
        
      when picnic_cv_tree0 =>
        Chal_start <= '1';
      when picnic_hcp_start =>
        null;
      when picnic_hcp =>
      
      when picnic_success =>
        pdo_valid <='1';
        pdo_last <= '1';
        pdo_data <= S_SUCCESS & pad_112;
        status_ready <= '1';
      when others =>
        null;
    end case;
  end process;

  -- next state logic
  process (State_DP, pdi_valid, pdi_data, seed_ready, tape_finish, Chal_out, Sig_len_DP, Challenge_DP, commC_finish, lowmc_finish, commH_finish, commV_finish, Counter_Trans_DP, Counter_DP, cv_finish, Counter_tau_DP, pdo_ready, C_DP, Chal_finish, Tree_DP,ET_DP)
  begin
    -- default
    State_DN <= State_DP;

    case State_DP is
      --when debug =>
      --  State_DN <= picnic_start;
      when init =>
        if pdi_valid = '1' and pdi_data = I_VER & pad_112 then
          State_DN <= inst_ver;
        elsif pdi_valid = '1' and pdi_data = L1_H_PUB & pad_96 then
          State_DN <= read_pub_c0;
        end if;
      when read_pub_c0 =>
        if pdi_valid = '1' then
          State_DN <= read_pub_c1;
        end if;
      when read_pub_c1 =>
        if pdi_valid = '1' then
          State_DN <= read_pub_p0;
        end if;
      when read_pub_p0 =>
        if pdi_valid = '1' then
          State_DN <= read_pub_p1;
        end if;
      when read_pub_p1 =>
        if pdi_valid = '1' then
          State_DN <= init;
        end if;
      when inst_ver =>
        -- only support 512 bit msg for now
        if pdi_valid = '1' and pdi_data = L1_H_MSG_VER & pad_96 then
          State_DN <= read_msg;
        elsif pdi_valid = '1' then
          State_DN <= init;
        end if;
      when read_msg =>
        if pdi_valid = '1' and Counter_DP >= 3 then
          State_DN <= picnic_in_header;
        end if;
      
        when picnic_in_header =>
        if pdi_valid = '1' and to_integer(unsigned(pdi_data(111 downto 96))) < 000000000000000000000 then
          null;
        elsif pdi_valid = '1' and pdi_data(PDO_WIDTH - 1 downto PDO_WIDTH - 8) = H_SIG & "11" then
          State_DN <= picnic_in_chal0;
        elsif pdi_valid = '1' then
          null;
        end if;
      when picnic_in_chal0 =>
        if pdi_valid = '1' then
          State_DN <= picnic_in_chal1;
        end if;
      when picnic_in_chal1 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_chal2;
        end if;
      when picnic_in_chal2 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_chal3;
        end if;
      when picnic_in_chal3 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_hcp_verify;
        end if;
      when picnic_hcp_verify =>
        State_DN <= picnic_in_salt0;
      when picnic_in_salt0 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_salt1;
        end if;
      when picnic_in_salt1 =>
        if Chal_finish = '1' then
          if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
            State_DN <= picnic_reject;
          elsif pdi_valid = '1' then
            State_DN <= picnic_in_seed_0;
          end if;
        end if;
      when picnic_in_seed_0 =>
        if Tree_DP(0) = '1' and pdi_valid = '1' then
          State_DN <= picnic_in_seed_1;
        end if;
        if Counter_DP >= numnodes - 1 then
          State_DN <= picnic_in_cv0;
        end if;
      when picnic_in_seed_1 =>
        if pdi_valid = '1' then
          State_DN <= picnic_in_seed_0;
        end if;
      when picnic_in_cv0 =>
        State_DN <= picnic_in_cv1;
      when picnic_in_cv1 =>
        if Tree_DP(0) = '1' then
          if pdi_valid = '1' then
            State_DN <= picnic_in_cv2;
          end if;
        elsif Counter_DP >= FIRST_LEAF - 1 then
            State_DN <= picnic_in_cv3;
        end if;
      when picnic_in_cv2 =>
        if pdi_valid = '1' then
          State_DN <= picnic_in_cv3;
        end if;
      when picnic_in_cv3 =>
        if pdi_valid = '1' then
          State_DN <= picnic_in_cv4;
        end if;
      when picnic_in_cv4 =>
        if pdi_valid = '1' then
          if Counter_DP >= FIRST_LEAF - 1 then
            State_DN <= picnic_in_cv5;
          end if;
          State_DN <= picnic_in_cv1;
        end if;
      when picnic_in_cv5 =>
        if Tree_DP(0) = '1' then
          if pdi_valid = '1' then
            State_DN <= picnic_in_cv4;
          end if;
        elsif Counter_DP >= numnodes - 1 then
            State_DN <= picnic_in_tau_init;
        end if;
      when picnic_in_cv6 =>
        if pdi_valid = '1' then
          State_DN <= picnic_in_cv7;
        end if;
      when picnic_in_cv7 =>
        if pdi_valid = '1' then
          State_DN <= picnic_in_cv8;
        end if;
      when picnic_in_cv8 =>
        if pdi_valid = '1' then
          if Counter_DP >= numnodes - 1 then
            State_DN <= picnic_in_tau_init;
          else
            State_DN <= picnic_in_cv5;
          end if;
        end if;
      when picnic_in_tau_init =>
        State_DN <= picnic_in_tau;
      when picnic_in_tau =>
        if C_DP(0) = '1' then
          State_DN <= picnic_in_seed0;
        end if;
      when picnic_in_seed0 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_seed1;
        end if;
      when picnic_in_seed1 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_seed2;
        end if;
      when picnic_in_seed2 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_seed3;
        end if;
      when picnic_in_seed3 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          if ET_DP = P - 1 then
            State_DN <= picnic_in_input0;
          else
            State_DN <= picnic_in_aux;
          end if;
        end if;
      when picnic_in_aux =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          if Counter_Trans_DP >= ENTRIE_PER_AM - 2 then
            State_DN <= picnic_in_input0;
          end if;
        end if;
      when picnic_in_input0 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_input1;
        end if;
      when picnic_in_input1 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_msgs;
        end if;
      when picnic_in_msgs =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          if Counter_Trans_DP >= ENTRIE_PER_AM - 2 then
            State_DN <= picnic_in_commit0;
          end if;
        end if;
      when picnic_in_commit0 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_commit1;
        end if;
      when picnic_in_commit1 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_commit2;
        end if;
      when picnic_in_commit2 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          State_DN <= picnic_in_commit3;
        end if;
      when picnic_in_commit3 =>
        if pdi_valid = '1' and Read_len_DP >= Sig_Len_DP - PDI_WIDTH / 8 then
          State_DN <= picnic_reject;
        elsif pdi_valid = '1' then
          if Counter_tau_DP >= Tau - 1 then
            State_DN <= picnic_in_end;
          else
            State_DN <= picnic_in_tau;
          end if;
        end if;
      when picnic_in_end =>
        if Counter_DP >= T then 
          State_DN <= picnic_start;
        end if;
      when picnic_start =>
        --State_DN <= picnic_seeds;
      --when picnic_seeds =>
        State_DN <= picnic_seedpre;
      when picnic_seedpre =>
        State_DN <= picnic_judge0;
      when picnic_judge0 =>
        if seed_ready = '1' and lowmc_finish = '1' and commV_finish = '1' and tape_finish = '1' and cv_finish = '1' then
          State_DN <= picnic_pipe0;
        end if;
      when picnic_pipe0 =>
        State_DN <= picnic_bram0;
      when picnic_bram0 =>
        if Counter_Trans_DP = 6 then
          if Counter_DP > T + 6 then
            State_DN <= picnic_cv_tree0;
          else 
            State_DN <= picnic_judge1;
          end if;
        end if;
      when picnic_judge1 =>
        if commC_finish = '1' and lowmc_finish = '1' and commH_finish = '1' then
          State_DN <= picnic_pipe1;
        end if;
      when picnic_pipe1 =>
        State_DN <= picnic_bram1;
      when picnic_bram1 =>
        if Counter_Trans_DP = 3 then
          State_DN <= picnic_seedpre;
        end if;
      when picnic_cv_tree0 =>
        State_DN <= picnic_hcp_start;
      when picnic_hcp_start =>
        State_DN <= picnic_hcp;
      when picnic_hcp =>
        if Chal_finish = '1' then
          if Chal_out = Challenge_DP then
            State_DN <= picnic_success;
          else
            State_DN <= picnic_reject;
          end if;
          
        end if;
      
      when picnic_success =>
        State_DN <= init;
      when others =>
        null;
    end case;
  end process;

  process (clk, rst)
  begin  -- process register_p
    if clk'event and clk = '1' then
      if rst = '1' then               -- synchronous reset (active high)
        State_DP           <= init;
        SK_DP              <= (others => '0');
        PC_DP              <= (others => '0');
        PP_DP              <= (others => '0');
        MSG_DP             <= (others => '0');
        Counter_DP         <= 0;
        Counter_tau_DP         <= 0;
        --Counter_Com_DP         <= 0;
        Counter_Trans_DP   <= 0;
        Seed_DP            <= (others => (others => '0'));
        Seed_com_DP        <= (others => (others => '0'));
        --Dig_c_DP            <= (others => (others => '0'));
        Dig_v_DP            <= (others => (others => '0'));
        Input_DP            <= (others => '0');
        --Input_bram_DP       <= (others => '0');
        --Msgs_in_DP            <= (others => (others => '0'));
        Tree_DP <= (others => '0');
        C_DP <= (others => '0');
        P_DP <= (others => '0');
        ET_DP <= 0;
        Msgs_ET_DP <= (others => 0);
        Aux_DP <= (others => '0');
        Tape_DP   <= (others => (others => '0'));
        Tape_last_DP <= (others => '0');
        Msgs_DP <= (others => (others => '0'));
        ComC_DP <= (others => (others => '0'));
        Challenge_DP <= (others => '0');
        Read_len_DP <= 0;
        Sig_len_DP <= 0;
        Salt_DP <= (others => '0');
        Msgs_verify_DP <= (others => '0');
        CH_DP <= (others => '0');
        PDI_DP <= (others => '0');
      else
        State_DP           <= State_DN;
        SK_DP              <= SK_DN;
        Counter_DP         <= Counter_DN;
        Counter_tau_DP         <= Counter_tau_DN;
        PC_DP              <= PC_DN;
        PP_DP              <= PP_DN;
        MSG_DP             <= MSG_DN;
        Counter_Trans_DP   <= Counter_Trans_DN;
        Seed_DP            <= Seed_DN;
        Seed_com_DP <= Seed_com_DN;
        --Dig_c_DP            <= Dig_c_DN;
        Dig_v_DP           <= Dig_v_DN;
        Input_DP           <= Input_DN;
        --Input_bram_DP      <= Input_bram_DN;
        --Msgs_in_DP            <= Msgs_in_DN;
        --Counter_Com_DP         <= Counter_Com_DN;
        Tree_DP <= Tree_DN;
        C_DP <= C_DN;
        P_DP <= P_DN;
        ET_DP <= ET_DN;
        Msgs_ET_DP <= Msgs_ET_DN;
        Aux_DP <= Aux_DN;
        Tape_DP   <= Tape_DN;
        Tape_last_DP <= Tape_last_DN;
        Msgs_DP <= Msgs_DN;
        ComC_DP <= ComC_DN;
        Challenge_DP <= Challenge_DN;
        Read_len_DP <= Read_len_DN;
        Sig_len_DP <= Sig_len_DN;
        Salt_DP <= Salt_DN;
        Msgs_verify_DP <= Msgs_verify_DN;
        CH_DP <= CH_DN;
        PDI_DP <= PDI_DN;
      end if;
    end if;
  end process;
end behavorial;

