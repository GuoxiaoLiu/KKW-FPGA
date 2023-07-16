library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_KECCAK_Top is
end TB_KECCAK_Top;

architecture Behavioral of TB_KECCAK_Top is

    -- Component declaration
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
      signal Init_SI    : in std_logic;
      -- Output signals
      signal Hash_DO  : out std_logic_vector(OUT_BIT - 1 downto 0);
      signal Valid_SO : out std_logic
    );
  end component;
  component keccak3
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
  component keccak4
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
  component keccak6
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

  -- Signal declaration
  signal Clk : std_logic := '0';
  signal Rst : std_logic := '0';
  signal Block_in : std_logic_vector(1343 downto 0) := (others => '0');
  signal Absorb : std_logic := '0';
  signal Squeeze : std_logic := '0';
  signal Init : std_logic := '0';
  signal Hash1, Hash2 ,Hash3, Hash4, Hash6: std_logic_vector(255 downto 0);
  signal Valid1,  Valid2,Valid3,Valid4,Valid6: std_logic;

           
    constant clk_period : time := 10 ns;
    
    
begin
    UUT1: keccak
    generic map(
      GEN_R => 1344,
      OUT_BIT => 256
    )
    port map(
      Clk_CI => Clk,
      Rst_RI => Rst,
      Block_DI => Block_in,
      Absorb_SI => Absorb,
      Init_SI => Init,
      Hash_DO => Hash1,
      Valid_SO => Valid1
    );
    
    UUT2: keccak2
    generic map(
      GEN_R => 1344,
      OUT_BIT => 256
    )
    port map(
      Clk_CI => Clk,
      Rst_RI => Rst,
      Block_DI => Block_in,
      Absorb_SI => Absorb,
      Init_SI => Init,
      Hash_DO => Hash2,
      Valid_SO => Valid2
    );
    UUT3: keccak3
    generic map(
      GEN_R => 1344,
      OUT_BIT => 256
    )
    port map(
      Clk_CI => Clk,
      Rst_RI => Rst,
      Block_DI => Block_in,
      Absorb_SI => Absorb,
      Init_SI => Init,
      Hash_DO => Hash3,
      Valid_SO => Valid3
    );
    UUT4: keccak4
    generic map(
      GEN_R => 1344,
      OUT_BIT => 256
    )
    port map(
      Clk_CI => Clk,
      Rst_RI => Rst,
      Block_DI => Block_in,
      Absorb_SI => Absorb,
      Init_SI => Init,
      Hash_DO => Hash4,
      Valid_SO => Valid4
    );
    UUT6: keccak6
    generic map(
      GEN_R => 1344,
      OUT_BIT => 256
    )
    port map(
      Clk_CI => Clk,
      Rst_RI => Rst,
      Block_DI => Block_in,
      Absorb_SI => Absorb,
      Init_SI => Init,
      Hash_DO => Hash6,
      Valid_SO => Valid6
    );

    -- Clock Process
    clk_proc : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process;

    -- Stimulation Process
    stim_proc : process
    begin

        Init <= '1';
        Rst <= '0';
        wait for 3*clk_period;
        Block_in <= (others => '0');
        Init <= '0';
        Absorb <= '1';
        Squeeze <= '0';
        wait for 3*clk_period;
        Init <= '0';
        Absorb <= '0';
        Squeeze <= '0';

        wait for 25*clk_period;

        if (Hash1 = x"e7dde140798f25f18a47c033f9ccd584eea95aa61e2698d54d49806f304715bd") then
            report "SUCCESS";
        else
            report "FAILURE";
        end if;

        wait;
    end process;

end Behavioral;