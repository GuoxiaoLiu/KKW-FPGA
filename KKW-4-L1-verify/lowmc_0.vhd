library work;
use work.lowmc_pkg.all;
library ieee;
use ieee.std_logic_1164.all;

entity lowmc is
  port(
    -- Clock and Reset
    signal Clk_CI   : in std_logic;
    signal Rst_RI   : in std_logic;
    -- Input signals
    signal Plain_DI  : in std_logic_vector(N - 1 downto 0);
    signal Key_DI     : in std_logic_vector(N - 1 downto 0);
    signal Init_SI   : in std_logic;
    -- Output signals
    signal Finish_SO : out std_logic;
    signal Cipher_DO : out std_logic_vector(N - 1 downto 0)
  );
end entity;

architecture behavorial of lowmc is

  type states is (init, enc_round);

  signal State_DN, State_DP : states;
  signal Data_DN, Data_DP : std_logic_vector(N - 1 downto 0);

  signal Data_Round_out : std_logic_vector(N - 1 downto 0);

  signal K0_out : std_logic_vector(N - 1 downto 0);
  signal Key_in, Key_out : std_logic_vector(N - 1 downto 0);
  signal Round_DN, Round_DP : integer range 0 to R - 1;
  signal Round_in : integer range 0 to R - 1;
  signal Sbox_out : std_logic_vector(N - 1 downto 0);

  component lowmc_matrix_k0
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_matrix_k
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      signal Round_DI : in integer range 0 to R - 1;
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_sbox is
    port(
      -- Input signals
      signal State_in_DI   : in std_logic_vector(N - 1 downto 0);
      -- Output signals
      signal State_out_DO  : out std_logic_vector(N - 1 downto 0)
    );
  end component;

  component lowmc_matrix_l
    port(
      -- Input signals
      signal Data_DI   : in std_logic_vector(N - 1 downto 0);
      signal Round_DI : in integer range 0 to R - 1;
      -- Output signals
      signal Data_DO : out std_logic_vector(N - 1 downto 0)
    );
  end component;

begin

  rdk : lowmc_matrix_k
  port map(
    Data_DI => Key_in,
    Round_DI => Round_DP,
    Data_DO => Key_out
  );



  rdk0 : lowmc_matrix_k0
  port map(
    Data_DI => Key_DI,
    Data_DO => K0_out
  );

  SIM_MPC_SBOX : lowmc_sbox
  port map (
    State_in_DI => Data_DP,
    State_out_DO => Sbox_out
  );

  L : lowmc_matrix_l
  port map(
    Data_DI => Sbox_out,
    Round_DI => Round_in,
    Data_DO => Data_Round_out
  );

  
  -- output logic
  process (State_DP, Init_SI, Plain_DI, Key_DI, Round_DP,K0_out, Data_Round_out, Data_DP, Key_out)
    variable tmp0 : std_logic_vector(N - 1 downto 0);
    variable tmp1 : std_logic_vector(N - 1 downto 0);
  begin
    -- default
    Round_DN <= Round_DP;
    Data_DN <= Data_DP;

    Finish_SO <= '0';
    Round_in <= 0;
    Key_in <= (others => '0');

    Cipher_DO <= Data_DP;

    
    -- output
    case State_DP is
      when init =>
        if Init_SI = '1' then
          Round_DN <= 0;
          Data_DN <= K0_out xor Plain_DI;
        end if;
        Finish_SO <= '1';
        Cipher_DO <= Data_DP;
      when enc_round =>
        if Round_DP < R - 1 then
          Round_DN <= Round_DP + 1;
        end if;
        Round_in <= Round_DP;
        Key_in <= Key_DI;
        Data_DN <= Data_Round_out xor RCMATRIX(Round_DP) xor Key_out;
    end case;
  end process;

  -- next state logic
  process (State_DP, Init_SI, Round_DP)
  begin
    --default
    State_DN <= State_DP;
    case State_DP is
      when init =>
        if Init_SI = '1' then
          State_DN <= enc_round;
        end if;

      when enc_round =>
        if Round_DP = R - 1 then
          State_DN <= init;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        Round_DP   <= 0;
        Data_DP <= (others => '0');
        State_DP   <= init;
        --Data_tmp_DP <= (others => '0');
      else
        Round_DP   <= Round_DN;
        State_DP   <= State_DN;
        Data_DP <= Data_DN;
        --Data_tmp_DP <= Data_tmp_DN;
      end if;
    end if;
  end process;

end behavorial;
