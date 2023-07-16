library ieee;
use ieee.std_logic_1164.all;

library work;
use work.lowmc_pkg.all;

package picnic_pkg is
  constant PICNIC_S : integer := 128;
  constant DIGEST_L : integer := 256;
  constant MSG_LEN : integer := 512;
  constant SALT_LEN : integer := 256;
  constant KECCAK_PAD : std_logic_vector(7 downto 0) := x"1F";
  constant STATE_SIZE_BIT : std_logic_vector(15 downto 0) := x"00FF";
  constant MAX_SIG : integer := 9000000;
  constant HASH_PREFIX_N : std_logic_vector(7 downto 0) := x"FF";
  constant HASH_PREFIX_1 : std_logic_vector(7 downto 0) := x"01";
  constant HASH_PREFIX_3 : std_logic_vector(7 downto 0) := x"02";


  constant PDI_WIDTH : integer := 128;
  constant SDI_WIDTH : integer := 64;
  constant PDO_WIDTH : integer := 128;

  constant T : integer := 206;--160
  constant FIRST_LEAF : integer := 255;
  constant tau : integer := 66;--86
  constant numNodes : integer := FIRST_LEAF + T;
  constant KECCAK_R : integer := 1344;

  constant RN_PAD_BYTE : integer := ((R * N + 7) / 8);
  constant N_PAD_BYTE : integer := ((N + 7) / 8);

  -- fifo
  constant UNALIGNED_WIDTH : integer := 8;

  type SEED_ARR is  array(0 to P - 1) of std_logic_vector(PICNIC_S - 1 downto 0);
  type DIGE_ARR is  array(0 to P - 1) of std_logic_vector(DIGEST_L - 1 downto 0);

end picnic_pkg;
