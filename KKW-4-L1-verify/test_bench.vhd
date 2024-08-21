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

    type state is (init, rand0, rand1, start, start0, start1, start2, start3, start4, start5,
        start6, start7, start8, start9, start10, start11, start12, start13, start14, start15, start16, s_end);
    signal state_dp : state;
    signal state_dn : state;
    constant PL : std_logic_vector(N - 1 downto 0) := "010101010101010101010100000001010001000001000101000001010101010100000100010001010101010100010001000000000001000100000100000100010";
    constant CI : std_logic_vector(N - 1 downto 0) := "000010110001011001101010101010011010000001110110000110111000101101100100101001000010110000010001010011111011101111010011110011011";
    constant KE : std_logic_vector(N - 1 downto 0) := "010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010";
    constant ME : std_logic_vector(512 - 1 downto 0) := "00000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001";
    
    component lowmc is
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
    end component;
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
    signal tmp_addra, tmp_addrb : std_logic_vector(32 - 1 downto 0);
    signal tmp_wea, tmp_web : std_logic;
    signal tmp_dina, tmp_dinb : std_logic_vector(64 - 1 downto 0);
    signal tmp_douta, tmp_doutb : std_logic_vector(64 - 1 downto 0);

    signal Counter_DN, Counter_DP : integer range 0 to T;
    signal Rand_DN, Rand_DP : std_logic_vector(N - 1 downto 0);
    
    
    signal lowmc_plain, lowmc_key, lowmc_cipher : std_logic_vector(N - 1 downto 0);
    signal lowmc_inst, lowmc_finish : std_logic;
begin


    dbf_lowmc : lowmc
        port map (
            Clk_CI => Clk_CI,
            Rst_RI => Rst_RI,
            Plain_DI => lowmc_plain,
            Key_DI => lowmc_key,
            Init_SI => lowmc_inst,
            Finish_SO => lowmc_finish,
            Cipher_DO => lowmc_cipher
        );
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

    PROCESS_BRAM : xilinx_TDP_RAM
        generic map(
          ADDR_WIDTH => 32,
          DATA_WIDTH => 64,
          ENTRIES => 8192
        )
        port map(
          clk => Clk_CI,
          addra => tmp_addra,
          addrb => tmp_addrb,
          dina => tmp_dina,
          dinb => tmp_dinb,
          wea => tmp_wea,
          web => tmp_web,
          ena => '1',
          enb => '1',
          douta => tmp_douta,
          doutb => tmp_doutb
        );
     
        
    process (state_dp, dbg_end, pdi_ready, sdi_ready, Counter_DP, pdo_valid, status_ready, verify_pdi_ready, verify_pdo_valid, verify_status_ready, pdo_data, pdo_last, tmp_douta, tmp_doutb, Rand_DP, lowmc_cipher, lowmc_finish)
    begin
        Rst_RI <= '0'; 
        pdi_valid <= '0';
        sdi_valid <= '0';
        pdo_ready <= '0';

        verify_pdi_valid <= '0';
        verify_pdo_ready <= '0';
        verify_pdi_data <= (others => '0');

        tmp_addra <= (others => '0');
        tmp_addrb <= (others => '0');
        tmp_dina <= (others => '0');
        tmp_dinb <= (others => '0');
        tmp_wea <= '0';
        tmp_web <= '0';

        Counter_DN <= Counter_DP;
        Rand_DN <= Rand_DP;
        
        lowmc_plain <= (others => '0');
        lowmc_key <= (others => '0');
        lowmc_inst <=  '0';
        
        
        case state_dp is
            when init =>
                Rand_DN <= (others => '0');
            when rand0 =>
                lowmc_inst <= '1';
                lowmc_plain <= PL xor Rand_DP;
                lowmc_key <= KE xor Rand_DP;
            when start =>
                pdi_data <= I_LDPRIVKEY & pad_112;
                pdi_valid <= '1';
            when start0 =>
                sdi_data <= L1_H_PRIV & pad_32;
                sdi_valid <= '1';
            when start1 =>
                sdi_data <= KE(N - 1 downto N - SDI_WIDTH) xor Rand_DP(N - 1 downto N - SDI_WIDTH);
                sdi_valid <= '1';
            when start2 =>
                sdi_data <= KE(N - SDI_WIDTH - 1 downto N - 2 * SDI_WIDTH) xor Rand_DP(N - SDI_WIDTH - 1 downto N - 2 * SDI_WIDTH);
                sdi_valid <= '1';
            when start3 =>
                sdi_data(SDI_WIDTH - 1) <= KE(0) xor Rand_DP(0);
                sdi_valid <= '1';
            when start4 =>
                pdi_data <= L1_H_PUB & pad_96;
                pdi_valid <= '1';
                verify_pdi_data <= L1_H_PUB & pad_96;
                verify_pdi_valid <= '1';
            when start5 =>
                pdi_data <= lowmc_cipher(N - 1 downto N - PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= lowmc_cipher(N - 1 downto N - PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start6 =>
                pdi_data(SDI_WIDTH - 1) <= lowmc_cipher(0);
                pdi_valid <= '1';
                verify_pdi_data(SDI_WIDTH - 1) <= lowmc_cipher(0);
                verify_pdi_valid <= '1';
            when start7 =>
                pdi_data <= PL(N - 1 downto N - PDI_WIDTH) xor Rand_DP(N - 1 downto N - PDI_WIDTH);
                pdi_valid <= '1';
                verify_pdi_data <= PL(N - 1 downto N - PDI_WIDTH) xor Rand_DP(N - 1 downto N - PDI_WIDTH);
                verify_pdi_valid <= '1';
            when start8 =>
                pdi_data(PDI_WIDTH - 1) <= PL(0) xor Rand_DP(0);
                pdi_valid <= '1';
                verify_pdi_data(PDI_WIDTH - 1) <= PL(0) xor Rand_DP(0);
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
                tmp_addra <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP, 32));
                tmp_addrb <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 1, 32));
                pdo_ready <= '1';
                if pdo_valid = '1' then
                    tmp_dina <= pdo_data(127 downto 64);
                    tmp_dinb <= pdo_data(63 downto 0);
                    tmp_wea <= '1';
                    tmp_web <= '1';
                    Counter_DN <= Counter_DP + 1;
                    Rand_DN(N - 1 downto N - PDI_WIDTH) <= tmp_dina & tmp_dinb;
                end if;
            when start16 =>
                Counter_DN <= 0;
                tmp_addra <= std_logic_vector(to_unsigned(0, 32));
                tmp_addrb <= std_logic_vector(to_unsigned(1, 32));
            when s_end =>
                tmp_addra <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP, 32));
                tmp_addrb <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 1, 32));
                verify_pdi_valid <= '1';
                if verify_pdi_ready = '1' then
                    verify_pdi_data <= tmp_douta & tmp_doutb;
                    Counter_DN <= Counter_DP + 1;
                    tmp_addra <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 2, 32));
                    tmp_addrb <= std_logic_vector(to_unsigned(Counter_DP + Counter_DP + 3, 32));
                end if;
                if verify_status_ready = '1' then
                    if verify_pdo_data = S_SUCCESS & pad_112 then
                        report "SUCCESS";
                    else
                        report "FAILURE";
                    end if;
                end if;
            when others =>
                null;
        end case;
    end process;

    
    process (state_dp, dbg_end, pdi_ready, sdi_ready, pdo_valid, status_ready, pdo_last, verify_pdo_last, lowmc_finish)
    begin
        state_dn <= state_dp;

        case state_dp is
            when init =>
                state_dn <= rand0;
            when rand0 =>
                state_dn <= rand1;
            when rand1 =>
                if lowmc_finish = '1' then
                    state_dn <= start;
                end if;
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
                if verify_pdo_last = '1' then
                    state_dn <= init;
                end if;
                
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
                Rand_DP <= (others => '0');
            else
                State_DP           <= State_DN;
                Counter_DP <= Counter_DN;
                Rand_DP <= Rand_DN;
            end if;
        end if;
    end process;

    clk_process :process
    begin
        Clk_CI <= not Clk_CI;
        wait for clk_period/2;
    end process;
end Behavioral;