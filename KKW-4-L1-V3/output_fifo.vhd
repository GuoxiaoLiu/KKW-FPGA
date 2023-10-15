library work;
use work.picnic_pkg.all;
use work.bram_pkg.all;
use work.protocol_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity output_fifo is
  port(
    -- Clock and Reset
    signal clk                : in std_logic;
    signal rst                : in std_logic;
    -- Inputs
    signal Init_SI            : in std_logic;
    signal Data_DI            : in std_logic_vector(PDO_WIDTH - 1 downto 0);
    signal Valid_Data_SI      : in std_logic;
    signal Unaligned_DI       : in std_logic_vector(UNALIGNED_WIDTH - 1 downto 0);
    signal Valid_Unaligned_SI : in std_logic;
    signal Ready_SI           : in std_logic;
    -- Outputs
    signal Data_DO            : out std_logic_vector(PDO_WIDTH - 1 downto 0);
    signal Valid_SO           : out std_logic;
    signal Ready_SO           : out std_logic
  );
end entity;

architecture behavorial of output_fifo is
  type states is (state0, state1, state2, state3, state4, state5,
                  state6, state7, state8, state9, state10, state11,
                  state12, state13, state14, state15, state_skip);
  signal State_DN, State_DP : states;

  signal Saved_DN, Saved_DP : std_logic_vector(PDO_WIDTH - 1 downto 0);
begin

  -- output logic
  process (State_DP, Saved_DP, Valid_Data_SI, Valid_Unaligned_SI, Ready_SI, Data_DI, Unaligned_DI)
  begin
    --default
    Saved_DN <= Saved_DP;
    Data_DO <= (others => '0');
    Valid_SO <= '0';
    Ready_SO <= Ready_SI;

    case State_DP is
      when state0 =>
        
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto UNALIGNED_WIDTH);
          Saved_DN(UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_Data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Data_DI;
        end if;
      when state1=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(1 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 2 * UNALIGNED_WIDTH);
          Saved_DN(2 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(2 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 2 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(1 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 1 * UNALIGNED_WIDTH);
          Saved_DN(1 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(1 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 1 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state2=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(2 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 3 * UNALIGNED_WIDTH);
          Saved_DN(3 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(3 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 3 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(2 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 2 * UNALIGNED_WIDTH);
          Saved_DN(2 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(2 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 2 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state3=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(3 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 4 * UNALIGNED_WIDTH);
          Saved_DN(4 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(4 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 4 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(3 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 3 * UNALIGNED_WIDTH);
          Saved_DN(3 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(3 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 3 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state4=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(4 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 5 * UNALIGNED_WIDTH);
          Saved_DN(5 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(5 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 5 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(4 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 4 * UNALIGNED_WIDTH);
          Saved_DN(4 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(4 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 4 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state5=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(5 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 6 * UNALIGNED_WIDTH);
          Saved_DN(6 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(6 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 6 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(5 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 5 * UNALIGNED_WIDTH);
          Saved_DN(5 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(5 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 5 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state6=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(6 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 7 * UNALIGNED_WIDTH);
          Saved_DN(7 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(7 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 7 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(6 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 6 * UNALIGNED_WIDTH);
          Saved_DN(6 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(6 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 6 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state7=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(7 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 8 * UNALIGNED_WIDTH);
          Saved_DN(8 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(8 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 8 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(7 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 7 * UNALIGNED_WIDTH);
          Saved_DN(7 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(7 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 7 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state8=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(8 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 9 * UNALIGNED_WIDTH);
          Saved_DN(9 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(9 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 9 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(8 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 8 * UNALIGNED_WIDTH);
          Saved_DN(8 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(8 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 8 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state9=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(9 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 10 * UNALIGNED_WIDTH);
          Saved_DN(10 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(10 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 10 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(9 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 9 * UNALIGNED_WIDTH);
          Saved_DN(9 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(9 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 9 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state10=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(10 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 11 * UNALIGNED_WIDTH);
          Saved_DN(11 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(11 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 11 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(10 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 10 * UNALIGNED_WIDTH);
          Saved_DN(10 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(10 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 10 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state11=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(11 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 12 * UNALIGNED_WIDTH);
          Saved_DN(12 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(12 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 12 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(11 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 11 * UNALIGNED_WIDTH);
          Saved_DN(11 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(11 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 11 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state12=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(12 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 13 * UNALIGNED_WIDTH);
          Saved_DN(13 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(13 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 13 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(12 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 12 * UNALIGNED_WIDTH);
          Saved_DN(12 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(12 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 12 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state13=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(13 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 14 * UNALIGNED_WIDTH);
          Saved_DN(14 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(14 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 14 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(13 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 13 * UNALIGNED_WIDTH);
          Saved_DN(13 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(13 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 13 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state14=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(14 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI & Data_DI(PDO_WIDTH - 1 downto 15 * UNALIGNED_WIDTH);
          Saved_DN(15 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(15 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 15 * UNALIGNED_WIDTH) <= (others => '0');
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(14 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 14 * UNALIGNED_WIDTH);
          Saved_DN(14 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(14 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 14 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state15=>
        if Valid_data_SI = '1' and Valid_Unaligned_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(15 * UNALIGNED_WIDTH - 1 downto 0) & Unaligned_DI;
          Saved_DN <= Data_DI;
        elsif Valid_data_SI = '1' then
          Valid_SO <= '1';
          Data_DO <= Saved_DP(15 * UNALIGNED_WIDTH - 1 downto 0) & Data_DI(PDO_WIDTH - 1 downto 15 * UNALIGNED_WIDTH);
          Saved_DN(15 * UNALIGNED_WIDTH - 1 downto 0) <= Data_DI(15 * UNALIGNED_WIDTH - 1 downto 0);
          Saved_DN(PDO_WIDTH - 1 downto 15 * UNALIGNED_WIDTH) <= (others => '0');
        end if;
      when state_skip =>
        Ready_SO <= '0';
        Valid_SO <= '1';
        Data_DO <= Saved_DP;  
        if Ready_SI = '1' then
          Saved_DN <= (others => '0');
        end if;
    end case;
  end process;

  -- next state logic
  process (State_DP, Valid_Data_SI, Valid_Unaligned_SI, Ready_SI, Init_SI)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when state0 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state1;
        end if;
      when state1 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state2;
        end if;
      when state2 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state3;
        end if;
      when state3 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state4;
        end if;
      when state4 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state5;
        end if;
      when state5 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state6;
        end if;
      when state6 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state7;
        end if;
      when state7 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state8;
        end if;
      when state8 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state9;
        end if;
      when state9 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state10;
        end if;
      when state10 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state11;
        end if;
      when state11 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state12;
        end if;
      when state12 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state13;
        end if;
      when state13 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state14;
        end if;
      when state14 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state15;
        end if;
      when state15 =>
        if Valid_Unaligned_SI = '1' and Valid_Data_SI = '1' and Ready_SI = '1' then
          State_DN <= state_skip;
        end if;
      when state_skip =>
        if Ready_SI = '1' then
          State_DN <= state0;
        end if;
    end case;

    if Init_SI = '1' then
      State_DN <= state0;
    end if;
  end process;

  process (clk, rst)
  begin  -- process register_p
    if clk'event and clk = '1' then
      if rst = '1' then               -- synchronous reset (active high)
        State_DP     <= state0;
        Saved_DP     <= (others => '0');
      else
        State_DP     <= State_DN;
        Saved_DP     <= Saved_DN;
      end if;
    end if;
  end process;

end architecture behavorial;
