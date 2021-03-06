----------------------------------------------------------------------------------
-- Company: University of Southern Denmark
-- Engineer: Anders Blaabjerg Lange
-- 
-- Create Date:    09:00:12 04/10/2012 
-- Design Name: 
-- Module Name:    ram_sdp - Behavioral 
-- Project Name: 
-- Target Devices: Spartan6 and Virtex6 (Spartan3 using the simple_sdp_ram_gen architecture)
-- Tool versions:  ISE 13.4 - 14.2 
-- Description:  	 
--
--		Simple Dual Ported Memory with support for different aspect 
--		ratios on port_a <> port_b.
--
--		RULE:	port_a_data_width * 2^port_a_addr_width = port_b_data_width * 2^port_b_addr_width
--
-- Dependencies: 
--
--		Unity-HDL libraries:
--			- utility_v01_00_a
--
-- Revision History:
-- -----------------------------------------
-- Version	Date			Author	Comment
-- 0.01		04/10-2012	ANLAN		File Created, based on the ram_tdp module v2.00
-- 0.02			 
--
-- Additional Comments: 
--
-- -----------------------------------------------------------------------------
-- Licensing:     (c) Copyright 2012, Anders Blaabjerg Lange
--                            All Rights Reserved
--
--  This file is part of the Unity HDL Library (Unity-lib).
--
--  Unity-lib is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  Unity-lib is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with Unity-lib.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library utility_v01_00_a;
use utility_v01_00_a.util_pkg.all;
use utility_v01_00_a.log_pkg.all;

entity ram_sdp is
   generic ( 
      C_RAMSTYLE      		: string  := "AUTO"; -- DISTRIBUTED, BLOCK, AUTO
		C_PORTA_DATA_WIDTH	: integer := 8;
		C_PORTA_ADDR_WIDTH	: integer := 10;
		C_PORTB_DATA_WIDTH	: integer := 32;
      C_PORTB_ADDR_WIDTH	: integer := 8;
		C_PORTB_OUTPUT_REG  	: integer range 0 to 1 := 1;	-- 1: Activates output (pipeline) registers
		C_ASYNC_OUTPUT_EN		: integer range 0 to 1 := 0;	-- 1: Enables asynchronous data output from the generated RAM, N.B. ONLY AVAILABLE FOR THE 'simple_sdp_ram_gen' ARCHITECTURE IN "distributed" MODE!
      C_INIT_DATA     		: integer := 0
      ); 
	port (
		 clk_a_i		: in  std_logic;
		 en_a_i		: in  std_logic;
		 we_a_i		: in	std_logic;
		 addr_a_i	: in  std_logic_vector(C_PORTA_ADDR_WIDTH-1 downto 0);
		 din_a_i		: in  std_logic_vector(C_PORTA_DATA_WIDTH-1 downto 0);
		 
		 clk_b_i		: in  std_logic;
		 en_b_i		: in  std_logic;
		 addr_b_i 	: in  std_logic_vector(C_PORTB_ADDR_WIDTH-1 downto 0);
		 dout_b_o 	: out std_logic_vector(C_PORTB_DATA_WIDTH-1 downto 0)
	);
end ram_sdp;

architecture sp6_sdp_ram_gen of ram_sdp is

	function limit_low(val: integer; low: integer) return integer is
	begin
		if val > low then		
			return val;
		else
			return low;
		end if;
	end limit_low;

	------------------------------------------------------
	-- Spartan6/Virtex6 BRAM limits
	------------------------------------------------------
	constant BRAM_MAX_ADDR_WIDTH 		: integer := 14;
	constant BRAM_MAX_DATA_WIDTH 		: integer := 32;	-- 16KBit BRAM
	--constant BRAM_MAX_EXT_DATA_WIDTH : integer := 36;	-- 16Kbit BRAM + 2KBit ECC-bits (18Kbit)
	------------------------------------------------------
	
	------------------------------------------------------
	-- use the smallest data+addr width
	------------------------------------------------------
	constant MAX_DATA_WIDTH		: integer := max(C_PORTA_DATA_WIDTH, C_PORTB_DATA_WIDTH);
	constant MIN_DATA_WIDTH		: integer := min(C_PORTA_DATA_WIDTH, C_PORTB_DATA_WIDTH);
	constant MAX_ADDR_WIDTH		: integer := max(C_PORTA_ADDR_WIDTH, C_PORTB_ADDR_WIDTH);
	constant MIN_ADDR_WIDTH		: integer := min(C_PORTA_ADDR_WIDTH, C_PORTB_ADDR_WIDTH);

	-- Memory depth
	-- address (y) (y = 2**(MAX_ADDR_WIDTH-14))	
	constant MEM_DEPTH  			: integer := 2**(limit_low(MAX_ADDR_WIDTH-BRAM_MAX_ADDR_WIDTH, 0));

	-- Memory width
	-- data (x) (x = (2**(MIN_ADDR_WIDTH-14+LOG2(MAX_DATA_WIDTH)))/y)
	constant MEM_WIDTH  			: integer := (2**(limit_low(MIN_ADDR_WIDTH-BRAM_MAX_ADDR_WIDTH+log2c(MAX_DATA_WIDTH), 0)))/MEM_DEPTH;

	constant PORTA_DATA_WIDTH 	: integer := C_PORTA_DATA_WIDTH/MEM_WIDTH;
	constant PORTA_ADDR_WIDTH 	: integer := C_PORTA_ADDR_WIDTH-log2c(MEM_DEPTH);
	constant PORTB_DATA_WIDTH 	: integer := C_PORTB_DATA_WIDTH/MEM_WIDTH;
	constant PORTB_ADDR_WIDTH 	: integer := C_PORTB_ADDR_WIDTH-log2c(MEM_DEPTH);
	------------------------------------------------------
	
	type din_a_array is array (0 to MEM_WIDTH-1) of std_logic_vector(PORTA_DATA_WIDTH-1 downto 0);
	type din_b_array is array (0 to MEM_WIDTH-1) of std_logic_vector(PORTB_DATA_WIDTH-1 downto 0);
	type dout_a_array is array (0 to MEM_WIDTH-1) of std_logic_vector(PORTA_DATA_WIDTH-1 downto 0);
	type dout_b_array is array (0 to MEM_WIDTH-1) of std_logic_vector(PORTB_DATA_WIDTH-1 downto 0);
	
	type dout_a_matrix is array (0 to MEM_DEPTH-1) of dout_a_array;
	type dout_b_matrix is array (0 to MEM_DEPTH-1) of dout_b_array;
	
	signal we_a 	: std_logic_vector(MEM_DEPTH-1 downto 0);
	signal din_a	: din_a_array;
	
	signal dout_b	: dout_b_matrix;

	signal addr_a_hreg : std_logic_vector(C_PORTA_ADDR_WIDTH-PORTA_ADDR_WIDTH-1 downto 0) := (others=>'0');
	signal addr_b_hreg : std_logic_vector(C_PORTB_ADDR_WIDTH-PORTB_ADDR_WIDTH-1 downto 0) := (others=>'0');

begin

	ASSERT 2**C_PORTA_ADDR_WIDTH * C_PORTA_DATA_WIDTH = 2**C_PORTB_ADDR_WIDTH * C_PORTB_DATA_WIDTH REPORT "Number of accessible bits on port_a and port_b MUST be identical!" SEVERITY FAILURE;
	ASSERT not(C_ASYNC_OUTPUT_EN=1) REPORT "Setting C_ASYNC_OUTPUT_EN=1 is only available for the 'simple_sdp_ram_gen' architecture in 'distributed' mode!" SEVERITY FAILURE;

	-------------------------------------------------------
	-- MaxAddressWidth <= 14
	-- -------------------------
	-- MaxAddressWidth*MinDataWidth <= 16K -> 1 BlockRAM is enough
	-- MaxAddressWidth*MinDataWidth > 16K  -> MEM_WIDTH BlockRAM memories will be connected in 
	--														parallel (x) sharing the same en, we and addr 
	--														inputs (no additional logic needed).
	-------------------------------------------------------
	
	-------------------------------------------------------
	-- MaxAddressWidth > 14
	-- -------------------------
	-- MaxDataWidth <= 32 -> MEM_WIDTH BlockRAM memories will be connected in parallel (x) 
	--								 sharing the lower 14 addr bits and the same en and data inputs, but 
	--								 utilizing input mux's on we and decoding logic on the upper (MaxAddressWidth-14)
	--								 addr bits as well as output data mux's.
	--
	-- MaxDataWidth > 32  -> MEM_WIDTH BlockRAM memories will be connected in parallel (x), and MEM_DEPTH instances of 
	--								 those will be connected in "series" (y) all sharing the lower 14 addr bits and the same 
	--								 en inputs, but utilizing input mux's on we and data inputs, decoding logic on the upper 
	--								 (MaxAddressWidth-14) addr bits as well as output data mux's.
	--------------------------------------------------------
	
	-- address a (high part) register
	process(clk_a_i)
	begin
		if rising_edge(clk_a_i) then
			addr_a_hreg <= addr_a_i(C_PORTA_ADDR_WIDTH-1 downto PORTA_ADDR_WIDTH);
		end if;
	end process;
	
	-- address b (high part) register
	process(clk_b_i)
	begin
		if rising_edge(clk_b_i) then
			addr_b_hreg <= addr_b_i(C_PORTB_ADDR_WIDTH-1 downto PORTB_ADDR_WIDTH);
		end if;
	end process;

	MEM_DEPTH_GEN:
	for y in 0 to MEM_DEPTH-1 generate
	begin
		MEM_WIDTH_GEN:
		for x in 0 to MEM_WIDTH-1 generate
		begin
		
			WE_GEN1:
			if MEM_DEPTH=1 generate
				we_a(y) <= '1' when we_a_i='1' else '0';
			end generate;		
		
			WE_GEN2:
			if MEM_DEPTH>1 generate
				we_a(y) <= '1' when unsigned(addr_a_hreg)=y and we_a_i='1' else '0';
			end generate;
			
		
			DATA_IN_GEN1:
			if PORTA_DATA_WIDTH=PORTB_DATA_WIDTH generate
				din_a(x) <= din_a_i(((x+1)*PORTA_DATA_WIDTH)-1 downto ((x)*PORTA_DATA_WIDTH));
			end generate;
			
			DATA_IN_GEN2:
			if PORTA_DATA_WIDTH<PORTB_DATA_WIDTH generate		
				din_a(x) <= din_a_i(((x+1)*PORTA_DATA_WIDTH)-1 downto ((x)*PORTA_DATA_WIDTH));
			end generate;
		
			DATA_IN_GEN3:
			if PORTA_DATA_WIDTH>PORTB_DATA_WIDTH generate
			
				SPLIT_DATA_OUT_GEN2:
				for i in 0 to (PORTA_DATA_WIDTH/PORTB_DATA_WIDTH)-1 generate
				begin
					din_a(x)(((i+1)*PORTB_DATA_WIDTH)-1 downto (i*PORTB_DATA_WIDTH)) <= din_a_i((i*(C_PORTA_DATA_WIDTH/(PORTA_DATA_WIDTH/PORTB_DATA_WIDTH)))+((x+1)*PORTB_DATA_WIDTH)-1 downto (i*(C_PORTA_DATA_WIDTH/(PORTA_DATA_WIDTH/PORTB_DATA_WIDTH)))+(x*PORTB_DATA_WIDTH));					
				end generate;
				
			end generate;		
		
		
			ram_sdp_simple_inst : entity work.ram_sdp_simple
			generic map(
				C_RAMSTYLE      		=> C_RAMSTYLE,
				C_PORTA_DATA_WIDTH	=> PORTA_DATA_WIDTH,
				C_PORTA_ADDR_WIDTH	=> PORTA_ADDR_WIDTH,
				C_PORTB_DATA_WIDTH	=> PORTB_DATA_WIDTH,
				C_PORTB_ADDR_WIDTH	=> PORTB_ADDR_WIDTH,
				C_OUTPUT_REG  			=> C_PORTB_OUTPUT_REG,
				C_INIT_DATA     		=> C_INIT_DATA
			)
			port map(
				clk_a_i    => clk_a_i,
				enable_a_i => en_a_i,
				we_a_i     => we_a(y),
				addr_a_i   => addr_a_i(PORTA_ADDR_WIDTH-1 downto 0),
				data_a_i   => din_a(x),

				clk_b_i    => clk_b_i,
				enable_b_i => en_b_i,
				addr_b_i   => addr_b_i(PORTB_ADDR_WIDTH-1 downto 0),
				data_b_o   => dout_b(y)(x)
			);
			

			DATA_OUT_GEN1:
			if PORTA_DATA_WIDTH=PORTB_DATA_WIDTH generate
				dout_b_o(((x+1)*PORTB_DATA_WIDTH)-1 downto ((x)*PORTB_DATA_WIDTH)) <= dout_b(to_integer(unsigned(addr_b_hreg)))(x);
			end generate;
			
			DATA_OUT_GEN2:
			if PORTA_DATA_WIDTH<PORTB_DATA_WIDTH generate
				
				SPLIT_DATA_OUT_GEN1:
				for i in 0 to (PORTB_DATA_WIDTH/PORTA_DATA_WIDTH)-1 generate
				begin
					dout_b_o((i*(C_PORTB_DATA_WIDTH/(PORTB_DATA_WIDTH/PORTA_DATA_WIDTH)))+((x+1)*PORTA_DATA_WIDTH)-1 downto (i*(C_PORTB_DATA_WIDTH/(PORTB_DATA_WIDTH/PORTA_DATA_WIDTH)))+(x*PORTA_DATA_WIDTH)) <= dout_b(to_integer(unsigned(addr_b_hreg)))(x)(((i+1)*PORTA_DATA_WIDTH)-1 downto (i*PORTA_DATA_WIDTH));
				end generate;
				
			end generate;
		
			DATA_OUT_GEN3:
			if PORTA_DATA_WIDTH>PORTB_DATA_WIDTH generate
			
				dout_b_o(((x+1)*PORTB_DATA_WIDTH)-1 downto ((x)*PORTB_DATA_WIDTH)) <= dout_b(to_integer(unsigned(addr_b_hreg)))(x);
				
			end generate;
			
		end generate;
	end generate;		

end sp6_sdp_ram_gen;

architecture simple_sdp_ram_gen of ram_sdp is

	------------------------------------------------------
	-- use the smallest data+addr width
	------------------------------------------------------
	constant MAX_DATA_WIDTH	: integer := max(C_PORTA_DATA_WIDTH, C_PORTB_DATA_WIDTH);
	constant MIN_DATA_WIDTH	: integer := min(C_PORTA_DATA_WIDTH, C_PORTB_DATA_WIDTH);
	constant MAX_ADDR_WIDTH	: integer := max(C_PORTA_ADDR_WIDTH, C_PORTB_ADDR_WIDTH);
	constant MIN_ADDR_WIDTH	: integer := min(C_PORTA_ADDR_WIDTH, C_PORTB_ADDR_WIDTH);
	
	constant DATA_WIDTH 	: integer := MIN_DATA_WIDTH;
	constant ADDR_WIDTH 	: integer := MIN_ADDR_WIDTH;
	constant ADDR_WDIF	: integer := MAX_ADDR_WIDTH-MIN_ADDR_WIDTH;
	constant MEM_COUNT  	: integer := MAX_DATA_WIDTH/MIN_DATA_WIDTH;
	------------------------------------------------------
	
	signal en_a 	: std_logic;
	signal we_a 	: std_logic_vector(MEM_COUNT-1 downto 0);
	signal addr_a 	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal din_a 	: std_logic_vector((MEM_COUNT*DATA_WIDTH)-1 downto 0);

	signal en_b 	: std_logic;
	signal addr_b 	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal dout_b 	: std_logic_vector((MEM_COUNT*DATA_WIDTH)-1 downto 0);	

	signal o_sel	: std_logic_vector(ADDR_WDIF-1 downto 0) := (others=>'0');

begin
	
	ASSERT 2**C_PORTA_ADDR_WIDTH * C_PORTA_DATA_WIDTH = 2**C_PORTB_ADDR_WIDTH * C_PORTB_DATA_WIDTH REPORT "Number of accessible bits on port_a and port_b MUST be identical!" SEVERITY FAILURE;
	ASSERT not(C_ASYNC_OUTPUT_EN=1 and C_RAMSTYLE /= "DISTRIBUTED") REPORT "Setting C_ASYNC_OUTPUT_EN=1 is only available for the 'simple_sdp_ram_gen' architecture when RAMSTYLE is set to ''DISTRIBUTED''!" SEVERITY FAILURE;	

	DIN_GEN_A:
	if C_PORTA_DATA_WIDTH <= C_PORTB_DATA_WIDTH generate
	begin	
		process(en_a_i, we_a_i, addr_a_i, din_a_i, en_b_i, addr_b_i)
		begin
			en_a <= en_a_i;
			we_a <= (others=>'0');
			we_a(to_integer(unsigned(addr_a_i(ADDR_WDIF-1 downto 0)))) <= we_a_i;		
			addr_a <= addr_a_i(C_PORTA_ADDR_WIDTH-1 downto ADDR_WDIF);			
			for i in 0 to MEM_COUNT-1 loop
				din_a((DATA_WIDTH*(i+1))-1 downto (DATA_WIDTH*i))  <= din_a_i;
			end loop;			
			
			en_b   <= en_b_i;			
			addr_b <= addr_b_i;
		end process;
	end generate;
	
	DIN_GEN_B:
	if C_PORTB_DATA_WIDTH < C_PORTA_DATA_WIDTH generate
	begin		
		process(en_a_i, we_a_i, addr_a_i, din_a_i, en_b_i, addr_b_i)
		begin
			en_a 	 <= en_a_i;
			for i in 0 to MEM_COUNT-1 loop
				we_a(i) <= we_a_i;
			end loop;
			addr_a <= addr_a_i;
			din_a  <= din_a_i;
			
			en_b   <= en_b_i;
			addr_b <= addr_b_i(C_PORTB_ADDR_WIDTH-1 downto ADDR_WDIF);
		end process;	
	end generate;

	SYNC_MEM_GEN:
	if C_ASYNC_OUTPUT_EN=0 generate
	begin
		MEM_GEN:
		for i in 0 to MEM_COUNT-1 generate
		begin
			ram_wr_dc_inst : entity work.ram_wr_dc(sync_rd)
			generic map( 
				ADDR_WIDTH    => ADDR_WIDTH,
				DATA_WIDTH    => DATA_WIDTH,
				RAMSTYLE      => C_RAMSTYLE,
				PIPE_REGB_EN  => C_PORTB_OUTPUT_REG,
				INIT_DATA     => C_INIT_DATA
			)      
			port map( 
				clk_a_i    => clk_a_i,
				en_a_i 	  => en_a,
				we_a_i     => we_a(i),
				addr_a_i   => addr_a,
				data_a_i   => din_a((DATA_WIDTH*(i+1))-1 downto (DATA_WIDTH*i)),

				clk_b_i    => clk_b_i,
				en_b_i 	  => en_b,
				addr_b_i   => addr_b,
				data_b_o   => dout_b((DATA_WIDTH*(i+1))-1 downto (DATA_WIDTH*i))
			);
		end generate;
	end generate;
		
	ASYNC_MEM_GEN:
	if C_ASYNC_OUTPUT_EN=1 generate
	begin
		MEM_GEN:
		for i in 0 to MEM_COUNT-1 generate
		begin
			ram_wr_dc_inst : entity work.ram_wr_dc(async_rd)
			generic map( 
				ADDR_WIDTH    => ADDR_WIDTH,
				DATA_WIDTH    => DATA_WIDTH,
				RAMSTYLE      => C_RAMSTYLE,
				PIPE_REGB_EN  => C_PORTB_OUTPUT_REG,
				INIT_DATA     => C_INIT_DATA
			)      
			port map( 
				clk_a_i    => clk_a_i,
				en_a_i 	  => en_a,
				we_a_i     => we_a(i),
				addr_a_i   => addr_a,
				data_a_i   => din_a((DATA_WIDTH*(i+1))-1 downto (DATA_WIDTH*i)),

				clk_b_i    => clk_b_i,
				en_b_i 	  => en_b,
				addr_b_i   => addr_b,
				data_b_o   => dout_b((DATA_WIDTH*(i+1))-1 downto (DATA_WIDTH*i))
			);
		end generate;
	end generate;
	
	
	DOUT_GEN_A:
	if C_PORTA_DATA_WIDTH <= C_PORTB_DATA_WIDTH generate
	begin	
		dout_b_o <= dout_b;
	end generate;
	
	DOUT_GEN_B:
	if C_PORTB_DATA_WIDTH < C_PORTA_DATA_WIDTH generate
	begin
		process(clk_b_i)
		begin
			if rising_edge(clk_b_i) then
				o_sel	<= addr_b_i(o_sel'range);
			end if;
		end process;

		process(o_sel, dout_b)
			variable n : integer;
		begin
			n := to_integer(unsigned(o_sel));
			dout_b_o <= dout_b((DATA_WIDTH*(n+1))-1 downto (DATA_WIDTH*n));
		end process;
	end generate;
	
end simple_sdp_ram_gen;