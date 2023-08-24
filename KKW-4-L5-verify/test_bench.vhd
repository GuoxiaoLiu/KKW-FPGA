library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.picnic_pkg.all;
use work.protocol_pkg.all;
use work.lowmc_pkg.all;

entity test_bench is
end test_bench;

    architecture Behavioral of test_bench is

    constant clk_period   : time := 8 ns;
    constant rst_period   : time := 1000 ms;
    signal Clk_CI         : std_logic := '1';
    signal Rst_RI         : std_logic := '1';

    signal dbg_start : std_logic := '0';
    signal dbg_end : std_logic := '0';

    type state is (init, start, start0, start1, start2, start3, start4, start41, start5,
        start6, start7, start8, start9, start10, start11, start12, start13, start14, start15, start16, s_end);
    signal state_dp : state;
    signal state_dn : state;
    constant PL : std_logic_vector(N - 1 downto 0) := "010101010101010101010100000001010001000001000101000001010101010100000100010001010101010100010001000000000001000100000100000100010101010101010101010101000000010100010000010001010000010101010101000001000100010101010101000100010000000000010001000001000001000";
    constant CI : std_logic_vector(N - 1 downto 0) := "000010110001011001101010101010011010000001110110000110111000101101100100101001000010110000010001010011111011101111010011110011011010101010101010101010000000101000100000100010100000101010101010000010001000101010101010001000100000000000100010000010000010001";
    constant KE : std_logic_vector(N - 1 downto 0) := "010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010010101010000010001000101010101010001000100000000000100010000010000010001010101010101010101010100000001010001000001000101010101";
    constant ME : std_logic_vector(512 - 1 downto 0) := "00000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001";
    

    component picnic3_sign is
        port(
            -- Clock and Reset
            signal clk          : in std_logic;
            signal rst          : in std_logic;
            -- Public Data Inputs
            signal pdi_data     : in std_logic_vector(PDI_WIDTH - 1 downto 0);
            signal pdi_valid    : in std_logic;
            signal pdi_ready    : out std_logic;
            --Secret Data Inputs
            signal sdi_data     : in std_logic_vector(SDI_WIDTH - 1 downto 0);
            signal sdi_valid    : in std_logic;
            signal sdi_ready    : out std_logic;
            -- Public Data Outputs
            signal pdo_data     : out std_logic_vector(PDO_WIDTH - 1 downto 0);
            signal pdo_valid    : out std_logic;
            signal pdo_ready    : in std_logic;
            signal pdo_last     : out std_logic;
            -- Status
            signal status_ready : out std_logic
        );
    end component;
    
    component picnic3_verify is
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

    signal pdi_data     : std_logic_vector(PDI_WIDTH - 1 downto 0);
    signal pdi_valid    : std_logic;
    signal pdi_ready    : std_logic;
    --Secret Data Inputs
    signal sdi_data     : std_logic_vector(SDI_WIDTH - 1 downto 0);
    signal sdi_valid    : std_logic;
    signal sdi_ready    :  std_logic;
    -- Public Data Outputs
    signal pdo_data     :  std_logic_vector(PDO_WIDTH - 1 downto 0);
    signal pdo_valid    :  std_logic;
    signal pdo_ready    : std_logic;
    signal pdo_last     :  std_logic;
    -- Status
    signal status_ready :  std_logic;

    signal verify_pdi_data     : std_logic_vector(PDI_WIDTH - 1 downto 0);
    signal verify_pdi_valid    : std_logic;
    signal verify_pdi_ready    : std_logic;

    -- Public Data Outputs
    signal verify_pdo_data     :  std_logic_vector(PDO_WIDTH - 1 downto 0);
    signal verify_pdo_valid    :  std_logic;
    signal verify_pdo_ready    : std_logic;
    signal verify_pdo_last     :  std_logic;
    -- Status
    signal verify_status_ready :  std_logic;


    -- aux bram
    signal aux_addra, aux_addrb : std_logic_vector(32 - 1 downto 0);
    signal aux_wea, aux_web : std_logic;
    signal aux_dina, aux_dinb : std_logic_vector(64 - 1 downto 0);
    signal aux_douta, aux_doutb : std_logic_vector(64 - 1 downto 0);

    signal Counter_DN, Counter_DP : integer range 0 to T;
begin
    dbg_picnic_sign: picnic3_sign
        port map (
            clk => Clk_CI,
            rst => Rst_RI,
            pdi_data => pdi_data,
            pdi_valid => pdi_valid,
            pdi_ready => pdi_ready,
            sdi_data => sdi_data,
            sdi_valid => sdi_valid,
            sdi_ready => sdi_ready,
            pdo_data => pdo_data,
            pdo_valid => pdo_valid,
            pdo_ready => pdo_ready,
            pdo_last => pdo_last,
            status_ready => status_ready
        );
    dbg_picnic_verify: picnic3_verify
        port map (
            clk => Clk_CI,
            rst => Rst_RI,
            pdi_data => verify_pdi_data,
            pdi_valid => verify_pdi_valid,
            pdi_ready => verify_pdi_ready,
            pdo_data => verify_pdo_data,
            pdo_valid => verify_pdo_valid,
            pdo_ready => verify_pdo_ready,
            pdo_last => verify_pdo_last,
            status_ready => verify_status_ready
        );

    AUX_BRAM : xilinx_TDP_RAM
        generic map(
          ADDR_WIDTH => 32,
          DATA_WIDTH => 64,
          ENTRIES => 8192 * 2
        )
        port map(
          clk => Clk_CI,
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
     
        
    process (state_dp, dbg_end, pdi_ready, sdi_ready, Counter_DP, pdo_valid, status_ready, verify_pdi_ready, verify_pdo_valid, verify_status_ready, pdo_data, pdo_last, aux_douta, aux_doutb)
    begin
        Rst_RI <= '0'; 
        pdi_valid <= '0';
        sdi_valid <= '0';
        pdo_ready <= '0';
        pdi_data <= (others => '0');
        verify_pdi_valid <= '0';
        verify_pdo_ready <= '0';
        verify_pdi_data <= (others => '0');

        aux_addra <= (others => '0');
        aux_addrb <= (others => '0');
        aux_dina <= (others => '0');
        aux_dinb <= (others => '0');
        aux_wea <= '0';
        aux_web <= '0';

        Counter_DN <= Counter_DP;

        case state_dp is
            when init =>
            when start =>
                pdi_data <= I_LDPRIVKEY & pad_112;
                pdi_valid <= '1';
            when start0 =>
                sdi_data <= L1_H_PRIV & pad_32;
                sdi_valid <= '1';
            when start1 =>
                sdi_data <= KE(N - 1 downto N - SDI_WIDTH);
                sdi_valid <= '1';
            when start2 =>
                sdi_data <= KE(N - SDI_WIDTH - 1 downto N - 2 * SDI_WIDTH);
                sdi_valid <= '1';
            when start3 =>
                sdi_data <= KE(N - 2 * SDI_WIDTH - 1 downto N - 3 * SDI_WIDTH);
                sdi_valid <= '1';
            when start41 =>
                sdi_data(SDI_WIDTH - 1 downto 1 ) <= KE(N - 3 * SDI_WIDTH - 1 downto 0);
                sdi_valid <= '1';
            when start4 =>
                pdi_data <= L1_H_PUB & pad_96;
                pdi_valid <= '1';
                verify_pdi_data <= L1_H_PUB & pad_96;
                verify_pdi_valid <= '1';
            when start5 =>
                pdi_data <= CI(N - 1 downto N - PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= CI(N - 1 downto N - PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start6 =>
                pdi_data(PDI_WIDTH - 1 downto 1) <= CI(N - PDI_WIDTH - 1 downto 0);
                pdi_valid <= '1';
                verify_pdi_data(PDI_WIDTH - 1 downto 1) <= CI(N - PDI_WIDTH - 1 downto 0);
                verify_pdi_valid <= '1';
            when start7 =>
                pdi_data <= PL(N - 1 downto N - PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= PL(N - 1 downto N - PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start8 =>
                pdi_data(PDI_WIDTH - 1 downto 1) <= PL(N - PDI_WIDTH - 1 downto 0);
                pdi_valid <= '1';
                verify_pdi_data(PDI_WIDTH - 1 downto 1) <= PL(N - PDI_WIDTH - 1 downto 0);
                verify_pdi_valid <= '1';
            when start9 =>
                pdi_data <= I_SGN & pad_112;
                pdi_valid <= '1';
                verify_pdi_data <= I_VER & pad_112;
                verify_pdi_valid <= '1';
            when start10 =>
                pdi_data <= L1_H_MSG & pad_96;
                pdi_valid <= '1';
                verify_pdi_data <= L1_H_MSG_VER & pad_96;
                verify_pdi_valid <= '1';
            when start11 =>
                pdi_data <= ME(MSG_LEN - 1 downto MSG_LEN - PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= ME(MSG_LEN - 1 downto MSG_LEN - PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start12 =>
                pdi_data <= ME(MSG_LEN - PDI_WIDTH - 1 downto MSG_LEN - 2 * PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= ME(MSG_LEN - PDI_WIDTH - 1 downto MSG_LEN - 2 * PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start13 =>
                pdi_data <= ME(MSG_LEN - 2 * PDI_WIDTH - 1 downto MSG_LEN - 3 * PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= ME(MSG_LEN - 2 * PDI_WIDTH - 1 downto MSG_LEN - 3 * PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start14 =>
                pdi_data <= ME(MSG_LEN - 3 * PDI_WIDTH - 1 downto MSG_LEN - 4 * PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= ME(MSG_LEN - 3 * PDI_WIDTH - 1 downto MSG_LEN - 4 * PDI_WIDTH);
                verify_pdi_valid <= '1';
                Counter_DN <= 0;
            when start15 =>
                aux_addra <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP, 32));
                aux_addrb <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 1, 32));
                pdo_ready <= '1';
                if pdo_valid = '1' then
                    aux_dina <= pdo_data(127 downto 64);
                    aux_dinb <= pdo_data(63 downto 0);
                    aux_wea <= '1';
                    aux_web <= '1';
                    Counter_DN <= Counter_DP + 1;
                end if;
            when start16 =>
                Counter_DN <= 0;
                aux_addra <= std_logic_vector(to_unsigned(0, 32));
                aux_addrb <= std_logic_vector(to_unsigned(1, 32));
            when s_end =>
                aux_addra <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP, 32));
                aux_addrb <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 1, 32));
                verify_pdi_valid <= '1';
                if verify_pdi_ready = '1' then
                    verify_pdi_data <= aux_douta & aux_doutb;
                    Counter_DN <= Counter_DP + 1;
                    aux_addra <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 2, 32));
                    aux_addrb <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 3, 32));
                end if;
            when others =>
                null;
        end case;
    end process;

    
    process (state_dp, dbg_end, pdi_ready, sdi_ready, pdo_valid, status_ready, pdo_last)
    begin
        state_dn <= state_dp;

        case state_dp is
            when init =>
                state_dn <= start;
            when start =>
                if pdi_ready = '1' then
                    state_dn <= start0;
                end if;
            when start0 =>
                if sdi_ready = '1' then
                    state_dn <= start1;
                end if;
            when start1 =>
                if sdi_ready = '1' then
                    state_dn <= start2;
                end if;
            when start2 =>
                if sdi_ready = '1' then
                    state_dn <= start3;
                end if;
            when start3 =>
                if sdi_ready = '1' then
                    state_dn <= start41;
                end if;
            when start41 =>
                if sdi_ready = '1' then
                    state_dn <= start4;
                end if;
            when start4 =>
                if pdi_ready = '1' then
                    state_dn <= start5;
                end if;
            when start5 =>
                if pdi_ready = '1' then
                    state_dn <= start6;
                end if;
            when start6 =>
                if pdi_ready = '1' then
                    state_dn <= start7;
                end if;
            when start7 =>
                if pdi_ready = '1' then
                    state_dn <= start8;
                end if;
            when start8 =>
                if pdi_ready = '1' then
                    state_dn <= start9;
                end if;
            when start9 =>
                if pdi_ready = '1' then
                    state_dn <= start10;
                end if;
            when start10 =>
                if pdi_ready = '1' then
                    state_dn <= start11;
                end if;
            when start11 =>
                if pdi_ready = '1' then
                    state_dn <= start12;
                end if;
            when start12 =>
                if pdi_ready = '1' then
                    state_dn <= start13;
                end if;
            when start13 =>
                if pdi_ready = '1' then
                    state_dn <= start14;
                end if;
            when start14 =>
                if pdi_ready = '1' then
                    state_dn <= start15;
                end if;
                if status_ready = '1' then
                    state_dn <= start15;
                end if;
            when start15 =>
                if pdo_last = '1' then
                    state_dn <= start16;
                end if;
            when start16 =>
                state_dn <= s_end;
            when s_end => 
                null;
            when others =>
                null; 
        end case;
    end process;

    process (Clk_CI, Rst_RI)
    begin  -- process register_p
        if Clk_CI'event and Clk_CI = '1' then
            if Rst_RI = '1' then               -- synchronous reset (active high)
                State_DP           <= init;
                Counter_DP <= 0;
            else
                State_DP           <= State_DN;
                Counter_DP <= Counter_DN;
            end if;
        end if;
    end process;

    clk_process :process
    begin
        Clk_CI <= not Clk_CI;
        wait for clk_period/2;
    end process;
end Behavioral;
