library work;
use work.picnic_pkg.all;
use work.bram_pkg.all;
use work.protocol_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity input_fifo is
  port(
    -- Clock and Reset
    signal clk                : in std_logic;
    signal rst                : in std_logic;
    -- Inputs
    signal Init_SI            : in std_logic;
    signal Data_DI            : in std_logic_vector(PDI_WIDTH - 1 downto 0);
    signal Valid_SI           : in std_logic;
    signal Ready_Data_SI      : in std_logic;
    signal Ready_Unaligned_SI : in std_logic;
    -- Outputs
    signal Ready_SO           : out std_logic;
    signal Data_DO            : out std_logic_vector(PDI_WIDTH - 1 downto 0);
    signal Unaligned_DO       : out std_logic_vector(UNALIGNED_WIDTH - 1 downto 0);
    signal Valid_SO           : out std_logic
  );
end entity;

architecture behavorial of input_fifo is
  type states is (state0, state1, state2, state3, state4, state5,
                        state6, state7, state8, state9, state10, state11,
                        state12, state13, state14, state15);
  signal State_DN, State_DP : states;

  signal Saved_DN, Saved_DP : std_logic_vector(PDI_WIDTH - 1 downto 0);
begin

  -- output logic
  process (State_DP, Saved_DP, Ready_Unaligned_SI, Ready_Data_SI, Valid_SI, Data_DI)
  begin
    --default
    Saved_DN <= Saved_DP;
    Data_DO <= Saved_DP;
    Unaligned_DO <= (others => '0');
    Valid_SO <= Valid_SI;
    Ready_SO <= '0';

    case State_DP is
      when state0 =>
        Data_DO <= Data_DI;
        Unaligned_DO <= Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 8);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 9 downto 0) <= Data_DI(PDI_WIDTH - 9 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 8) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN <= (others => '0');
        end if;
      when state1 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 9 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 8);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 9 downto PDI_WIDTH - 16);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 16) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 9 downto 0) <= Data_DI(PDI_WIDTH - 9 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 8) <= (others => '0');
        end if;
      when state2 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 17 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 16);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 17 downto PDI_WIDTH - 24);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 24) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 17 downto 0) <= Data_DI(PDI_WIDTH - 17 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 16) <= (others => '0');
        end if;
      when state3 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 25 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 24);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 25 downto PDI_WIDTH - 32);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 32) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 25 downto 0) <= Data_DI(PDI_WIDTH - 25 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 24) <= (others => '0');
        end if;
      when state4 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 33 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 32);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 33 downto PDI_WIDTH - 40);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 40) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 33 downto 0) <= Data_DI(PDI_WIDTH - 33 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 32) <= (others => '0');
        end if;
      when state5 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 41 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 40);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 41 downto PDI_WIDTH - 48);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 48) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 41 downto 0) <= Data_DI(PDI_WIDTH - 41 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 40) <= (others => '0');
        end if;
      when state6 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 49 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 48);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 49 downto PDI_WIDTH - 56);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 56) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 49 downto 0) <= Data_DI(PDI_WIDTH - 49 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 48) <= (others => '0');
        end if;
      when state7 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 57 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 56);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 57 downto PDI_WIDTH - 64);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 64) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 57 downto 0) <= Data_DI(PDI_WIDTH - 57 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 56) <= (others => '0');
        end if;
      when state8 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 65 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 64);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 65 downto PDI_WIDTH - 72);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 72) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 65 downto 0) <= Data_DI(PDI_WIDTH - 65 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 64) <= (others => '0');
        end if;
      when state9 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 73 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 72);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 73 downto PDI_WIDTH - 80);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 80) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 73 downto 0) <= Data_DI(PDI_WIDTH - 73 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 72) <= (others => '0');
        end if;
      when state10 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 81 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 80);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 81 downto PDI_WIDTH - 88);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 88) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 81 downto 0) <= Data_DI(PDI_WIDTH - 81 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 80) <= (others => '0');
        end if;
      when state11 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 89 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 88);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 89 downto PDI_WIDTH - 96);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 96) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 89 downto 0) <= Data_DI(PDI_WIDTH - 89 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 88) <= (others => '0');
        end if;
      when state12 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 97 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 96);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 97 downto PDI_WIDTH - 104);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 104) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 97 downto 0) <= Data_DI(PDI_WIDTH - 97 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 96) <= (others => '0');
        end if;
      when state13 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 105 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 104);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 105 downto PDI_WIDTH - 112);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 112) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 105 downto 0) <= Data_DI(PDI_WIDTH - 105 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 104) <= (others => '0');
        end if;
      when state14 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 113 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 112);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 113 downto PDI_WIDTH - 120);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 120) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 113 downto 0) <= Data_DI(PDI_WIDTH - 113 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 112) <= (others => '0');
        end if;
      when state15 =>
        Data_DO <= Saved_DP(PDI_WIDTH - 121 downto 0) & Data_DI(PDI_WIDTH - 1 downto PDI_WIDTH - 120);
        Unaligned_DO <= Saved_DP(PDI_WIDTH - 121 downto PDI_WIDTH - 128);
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 128) <= (others => '0');
        elsif Valid_SI = '1' and Ready_Data_SI = '1' then
          Ready_SO <= '1';
          Saved_DN(PDI_WIDTH - 121 downto 0) <= Data_DI(PDI_WIDTH - 121 downto 0);
          Saved_DN(PDI_WIDTH - 1 downto PDI_WIDTH - 120) <= (others => '0');
        end if;
    end case;
  end process;

  -- next state logic
  process (State_DP, Init_SI, Valid_SI, Ready_Unaligned_SI)
  begin
    --default
    State_DN <= State_DP;

    case State_DP is
      when state0 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state1;
        end if;
      when state1 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state2;
        end if;
      when state2 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state3;
        end if;
      when state3 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state4;
        end if;
      when state4 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state5;
        end if;
      when state5 =>
      if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
        State_DN <= state6;
      end if;
      when state6 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state7;
        end if;
      when state7 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state8;
        end if;
      when state8 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state9;
        end if;
      when state9 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state10;
        end if;
      when state10 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state11;
        end if;
      when state11 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state12;
        end if;
      when state12 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state13;
        end if;
      when state13 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state14;
        end if;
      when state14 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
          State_DN <= state15;
        end if;
      when state15 =>
        if Valid_SI = '1' and Ready_Unaligned_SI = '1' then
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

end behavorial;
