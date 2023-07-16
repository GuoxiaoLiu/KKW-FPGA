library work;
use work.keccak_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity keccak4 is
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
end entity;

architecture behavorial of keccak4 is
  -- CONSTANTS
  constant C : integer := B - GEN_R;
  constant R_LANES : integer := GEN_R / W;
  constant OUT_LANES : integer := OUT_BIT / W;

  type FSM is (init, rounds);
  signal FSM_DN, FSM_DP : FSM;
  signal State_DN, State_DP : T_STATE;
  signal State_in, State_tmp1, State_tmp2, State_tmp3, State_out : T_STATE;
  signal Round_DN, Round_DP, Round_next1, Round_next2, Round_next3 : integer range 0 to KECCAK_N;

  component keccak_round
    port(
      -- Input signals
      signal State_DI : in T_STATE;
      signal Round_DI : integer range 0 to KECCAK_N;
      -- Output signals
      signal State_DO : out T_STATE
    );
  end component;

begin

  -- 1st round
  ROUND1 : keccak_round
  port map(
    State_DI => State_in,
    Round_DI => Round_DP,
    State_DO => State_tmp1
  );

  -- 2nd round
  ROUND2 : keccak_round
  port map(
    State_DI => State_tmp1,
    Round_DI => Round_next1,
    State_DO => State_tmp2
  );

  -- 3th round
  ROUND3 : keccak_round
  port map(
    State_DI => State_tmp2,
    Round_DI => Round_next2,
    State_DO => State_tmp3
  );

  -- 4th round
  ROUND4 : keccak_round
  port map(
    State_DI => State_tmp3,
    Round_DI => Round_next3,
    State_DO => State_out
  );

  -- Output the hash
  process(State_DP)
    type T_OUT_LANES is array (0 to OUT_LANES) of T_ROW;
    variable Lane_end : T_OUT_LANES;
  begin
    ROW_OUT : for row in 0 to (CUBE_LEN - 1) loop
      COL_OUT : for col in 0 to (CUBE_LEN - 1) loop
        -- endianess correction
        END_OUT : for i in 0 to W / 8 - 1 loop
          Lane_end(row * CUBE_LEN + col)((i + 1) * 8 - 1 downto i * 8) := State_DP(row)(col)((W / 8 - i) * 8 - 1 downto (W / 8 - 1 - i) * 8);
        end loop END_OUT;

        exit ROW_OUT when row * CUBE_LEN + col = OUT_LANES;

        Hash_DO(OUT_BIT - (CUBE_LEN * row + col) * W - 1 downto OUT_BIT - (CUBE_LEN * row + col) * W - W) <= Lane_end(row * CUBE_LEN + col);
      end loop COL_OUT;
    end loop ROW_OUT;
    -- output of last incomplete slide if necessary
    if (OUT_LANES * W < OUT_BIT) then
      Hash_DO(OUT_BIT - OUT_LANES * W - 1 downto 0) <= Lane_end(OUT_LANES)(W - 1 downto W - OUT_BIT + OUT_LANES * W);
    end if;
  end process;

  -- next state and output logic
  process (FSM_DP, State_DP, Round_DP, State_out, Absorb_SI, Squeeze_SI, Init_SI, Block_DI)
    type T_R_LANES is array (0 to R_LANES - 1) of T_ROW;
    variable Lane_init, Lane_end : T_R_LANES;
  begin
    -- default:
    FSM_DN <= FSM_DP;
    Round_DN <= Round_DP;
    State_DN <= State_DP;
    Valid_SO <= '0';
    State_in <= State_DP;

    if Round_DP + 3 < KECCAK_N - 1 then
      Round_next1 <= Round_DP + 1;
      Round_next2 <= Round_DP + 2;
      Round_next3 <= Round_DP + 3;
    else
      Round_next1 <= 0;
      Round_next2 <= 0;
      Round_next3 <= 0;
    end if;

    case FSM_DP is
      when init =>
        Valid_SO <= '1';
        if Init_SI = '1' then
          State_DN <= (others => (others => (others => '0')));
        else
          if Absorb_SI = '1' and Squeeze_SI = '0' then
            FSM_DN <= rounds;
            Round_DN <= 1;
            State_DN <= State_out;
            ROW_AB : for row in 0 to (CUBE_LEN - 1) loop
              COL_AB : for col in 0 to (CUBE_LEN - 1) loop
                exit ROW_AB when row * CUBE_LEN + col = R_LANES;
                -- endianess correction
                END_OUT : for i in 0 to W / 8 - 1 loop
                  Lane_init(row * CUBE_LEN + col) := Block_DI(GEN_R - (CUBE_LEN * row + col) * W - 1 downto GEN_R - (CUBE_LEN * row + col) * W - W);
                  Lane_end(row * CUBE_LEN + col)((i + 1) * 8 - 1 downto i * 8) := Lane_init(row * CUBE_LEN + col)((W / 8 - i) * 8 - 1 downto (W / 8 - 1 - i) * 8);
                end loop END_OUT;

                State_in(row)(col) <= State_DP(row)(col) xor Lane_end(row * CUBE_LEN + col);
              end loop COL_AB;
            end loop ROW_AB;
          elsif Absorb_SI = '0' and Squeeze_SI = '1' then
            FSM_DN <= rounds;
            Round_DN <= 1;
            State_DN <= State_out;
          end if;
        end if;
      when rounds =>
        
        if Round_DP + 3 < KECCAK_N - 1 then
          Round_DN <= Round_DP + 4;
          State_DN <= State_out;
        else
          Round_DN <= 0;
          FSM_DN <= init;
          State_DN <= State_tmp3;
        end if;
    end case;
  end process;

  -- the registers
  process (Clk_CI, Rst_RI)
  begin  -- process register_p
    if Clk_CI'event and Clk_CI = '1' then
      if Rst_RI = '1' then               -- synchronous reset (active high)
        State_DP <= (others =>(others =>(others => '0')));
        Round_DP <= 0;
        FSM_DP   <= init;
      else
        State_DP <= State_DN;
        Round_DP <= Round_DN;
        FSM_DP   <= FSM_DN;
      end if;
    end if;
  end process;
end behavorial;