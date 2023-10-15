library ieee;
use ieee.std_logic_1164.all;

library work;
use work.picnic_pkg.all;

package bram_pkg is
  -- seed RAM
  constant SEED_ADDR_WIDTH : integer := 32;
  constant SEED_DATA_WIDTH : integer := 128;
  constant SEED_ENTRIES : integer := 1024; 

  constant SEED_I_ADDR_WIDTH : integer := 32;
  constant SEED_I_DATA_WIDTH : integer := 64;
  constant SEED_I_ENTRIES : integer := 2 * 512; 
  
  constant INPUT_ADDR_WIDTH : integer := 32;
  constant INPUT_DATA_WIDTH : integer := 64;
  constant INPUT_ENTRIES : integer := 2 * 256; 

  constant AUX_ADDR_WIDTH : integer := 32;
  constant AUX_DATA_WIDTH : integer := 64;
  constant AUX_ENTRIES : integer := 16 * 256; 

  constant COMMC_ADDR_WIDTH : integer := 32;
  constant COMMC_DATA_WIDTH : integer := 64;
  constant COMMC_ENTRIES : integer := 4 * 256;

  constant COMMH_ADDR_WIDTH : integer := 32;
  constant COMMH_DATA_WIDTH : integer := 64;
  constant COMMH_ENTRIES : integer := 4 * 256; 

  constant MSGS_ADDR_WIDTH : integer := 32;
  constant MSGS_DATA_WIDTH : integer := 64;
  constant MSGS_ENTRIES : integer := 9 * 256; 

  constant COMMV_ADDR_WIDTH : integer := 32;
  constant COMMV_DATA_WIDTH : integer := 64;
  constant COMMV_ENTRIES : integer := 4 * 256; 

  constant CV_ADDR_WIDTH : integer := 32;
  constant CV_DATA_WIDTH : integer := 128;
  constant CV_ENTRIES : integer := 512; 

  constant ENTRIE_PER_AM : integer := 9;

end bram_pkg;
