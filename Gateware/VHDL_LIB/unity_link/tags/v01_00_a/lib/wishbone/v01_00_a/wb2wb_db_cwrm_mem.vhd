----------------------------------------------------------------------------------
-- Company: University of Southern Denmark
-- Engineer: Anders Blaabjerg Lange 
-- 
-- Create Date:    15:46:53 03/27/2012 
-- Design Name: 
-- Module Name:    wb2wb_db_cwrm_mem - structural 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
--  -----------------------------------------------------------------
--	 |								WISHBONE DATASHEET							  |
--  -----------------------------------------------------------------
--	 |	DESCRIPTION				|	SPECIFICATION								  |
--  -----------------------------------------------------------------
--	 |	General description	| 	32-bit SLAVE double buffered memory   |
--	 |								|	with 32-bit granularity, Commit Write |
--	 |								|	+ Read Multiple (CWRM) functionality. |
--  -----------------------------------------------------------------
--	 |	Wishbone version 		| 	Protocol version B4 						  |
--  -----------------------------------------------------------------
--	 |	Supported cycles		| 	SLAVE, READ/WRITE							  |
--	 |								| 	SLAVE, BLOCK READ/WRITE					  |
--  -----------------------------------------------------------------
--  |	Data port:				|													  | 
--	 |		size					|	32-bit (QWORD)								  |
--	 |		granularity  		|	32-bit (QWORD)								  |
--	 |		max. operand size	|	32-bit (QWORD)								  |
--  |	Data transfer: 		|													  |
--	 |		ordering  			|	LITTLE ENDIAN								  |
--  |		sequence    		|	UNDEFINED									  |
--  -----------------------------------------------------------------
--
--  Signal name description and cross references:
--	 .... PENDING
--  .........
--  .............
--
--  Error generation : ERR_O is asserted under the following conditions
--	 .... PENDING
--  .........
--  .............
--
--  -----------------------------------------------------------------
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.wb_classic_interface.all;

library db_mem_v01_00_a;
use db_mem_v01_00_a.db_mem.all;

entity wb2wb_db_cwrm_mem is
	generic (
		-- DB CWRM MEM configuration
		C_MEM_ADDR_WIDTH 		: integer range 0 to 32 := 10;	-- Memory depth/size
		C_IO_ADDR_BIT 			: integer range 0 to 31 := 2;		-- default: 2 (TosNet mode)
		C_CW_TIMEOUT 			: natural 					:= 10;
		C_RST_ON_CW_TIMEOUT 	: integer range 0 to 1 	:= 0		
	);
	port ( 
			-- wb syscon interface	
			clk_i : in  std_logic;
			rst_i : in  std_logic;
			
			-- wb slave interface 1
			wb_si1_i 	: in  wb_ad32sb_if;
			wb_si1_o 	: out wb_d32ae_if;
			
			-- wb slave interface 2
			wb_si2_i 	: in  wb_ad32sb_if;
			wb_si2_o 	: out wb_d32ae_if		
	);
end wb2wb_db_cwrm_mem;

architecture structural of wb2wb_db_cwrm_mem is

	signal m_db_i : db_mem_cwrm_i_if;
	signal m_db_o : db_mem_cwrm_o_if;
	signal s_db_i : db_mem_cwrm_i_if;
	signal s_db_o : db_mem_cwrm_o_if;	

begin

	wb_slv_db_mem_ctrl_inst1 : entity work.wb_slv_db_mem_ctrl
	generic map(
		C_MEM_ADDR_WIDTH 	=> C_MEM_ADDR_WIDTH
	)
	port map( 
		-- wb syscon interface	
		clk_i => clk_i,
		rst_i => rst_i,
		
		-- wb slave interface
		wb_i 	=> wb_si1_i,
		wb_o 	=> wb_si1_o,
		
		-- db_mem interface
		db_i 	=> m_db_o,
		db_o 	=> m_db_i
	);
	
	wb_slv_db_mem_ctrl_inst2 : entity work.wb_slv_db_mem_ctrl
	generic map(
		C_MEM_ADDR_WIDTH 	=> C_MEM_ADDR_WIDTH
	)
	port map( 
		-- wb syscon interface	
		clk_i => clk_i,
		rst_i => rst_i,
		
		-- wb slave interface
		wb_i 	=> wb_si2_i,
		wb_o 	=> wb_si2_o,
		
		-- db_mem interface
		db_i 	=> s_db_o,
		db_o 	=> s_db_i
	);	

	db_mem_cwrm_inst : db_mem_cwrm
		generic map(
			C_IO_ADDR_BIT 			=> C_IO_ADDR_BIT,
			C_ADDR_WIDTH 			=> C_MEM_ADDR_WIDTH,
			C_DATA_WIDTH 			=> 32,
			C_CW_TIMEOUT 			=> C_CW_TIMEOUT,
			C_RST_ON_CW_TIMEOUT 	=> C_RST_ON_CW_TIMEOUT
		)
		port map( 
			clk_i    	=> clk_i,
			reset_i  	=> rst_i,
			
			-- master io
			m_db_i 		=> m_db_i,
			m_db_o 		=> m_db_o,
			
			-- slave io
			s_db_i 		=> s_db_i,
			s_db_o 		=> s_db_o
		);

end structural;
