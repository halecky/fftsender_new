---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--  version		: $Version:	1.0 $ 
--  revision		: $Revision: 1.1.1.1 $ 
--  designer name  	: $Author: jzhang $ 
--  company name   	: altera corp.
--  company address	: 101 innovation drive
--                  	  san jose, california 95134
--                  	  u.s.a.
-- 
--  copyright altera corp. 2003
-- 
-- 
--  $Header: /ipbu/cvs/dsp/projects/FFT/src/rtl/lib/asj_fft_wrswgen.vhd,v 1.1.1.1 2005/12/08 01:14:15 jzhang Exp $ 
--  $log$ 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- generate address and data switch select lines for writing butterfly outputs to RAM
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
library work;
use work.fft_pack.all;

entity asj_fft_wrswgen is
	generic(
						nps : integer :=4096;
						cont : integer:=0;
						arch : integer:=0;
						nume : integer :=1;
						n_passes : integer :=5;
						log2_n_passes : integer:= 3;
						apr : integer :=10;
						del : integer :=17
					);
	port(			clk 						: in std_logic;
						k_count   	  : in std_logic_vector(apr-1 downto 0);
						p_count       : in std_logic_vector(log2_n_passes-1 downto 0);
						sw_data_write : out std_logic_vector(1 downto 0); -- swd
						sw_addr_write : out std_logic_vector(1 downto 0) --swa
			);
end asj_fft_wrswgen;

architecture gen_all of asj_fft_wrswgen is


type sw_array is array (0 to del-1) of std_logic_vector(1 downto 0);
signal swd_tdl : sw_array;
signal swa_tdl : sw_array;
signal swd : std_logic_vector(1 downto 0);
signal swa : std_logic_vector(1 downto 0);

begin


sw_data_write <= swd_tdl(del-1);
sw_addr_write <= swa_tdl(del-1);

-- Output delayed version of siwtches to sync with RAM-bound data
tdl_sw : process(clk,swd,swa,swd_tdl,swa_tdl) is
	begin
		if(rising_edge(clk)) then
			for i in del-1 downto 1 loop
				swd_tdl(i)<=swd_tdl(i-1);
				swa_tdl(i)<=swa_tdl(i-1);
			end loop;
			swd_tdl(0)<=swd;
			swa_tdl(0)<=swa;
		end if;
	end process tdl_sw;
			
	
-----------------------------------------------------------------------------------------
--Streaming 512,1024
-----------------------------------------------------------------------------------------
gen_streaming : if(arch=0) generate

gen_cont : if(cont=1) generate

gen_512_addr : if(nps=512) generate

swa<=swd;

get_512_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + ('0' & k_count(6));
				when others =>
				 	swd <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

swa <= swd;

get_1024_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				when others =>
				 	swd <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
end generate gen_1024_addr;

end generate gen_cont;

-----------------------------------------------------------------------------------------------
-- Non-Continous : All Streaming architectures except 512 and 1024
-----------------------------------------------------------------------------------------------
gen_non_cont:if(cont=0) generate


gen_32_addr : if(nps=32) generate
	get_32_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + ('0' & k_count(2));
				 	swa <= '0' & k_count(2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_32_sw;
	
	 
end generate gen_32_addr;



gen_64_addr : if(nps=64) generate

	get_64_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;

-----------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------
	gen_2048_addr : if(nps=2048) generate
	
		swa <= swd;
		get_2048_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
	end generate gen_2048_addr;
	
	gen_4096_addr : if(nps=4096) generate
		swa <= swd;
		get_4096_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ ('0' & k_count(8));
						 	--swa <= '0' & k_count(8);
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
	
	gen_8192_addr : if(nps=8192) generate
		swa <=swd;
		get_8192_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	--swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) ;
						 	--swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
	end generate gen_8192_addr;
	
	gen_16384_addr : if(nps=16384) generate
	swa <=swd; 
		get_16384_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	--swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	--swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	--swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	--swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	--swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + ('0' & k_count(10));
						 	--swa <= '0' & k_count(10);
						when others =>
						 	swd <=(others=>'0');
						 	--swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;

end generate gen_non_cont;

end generate gen_streaming;


-----------------------------------------------------------------------------------------------
-- Burst and Buffered Burst
-----------------------------------------------------------------------------------------------
gen_b : if(arch=1 or arch=2) generate

gen_se_addr : if(nume=1) generate 

gen_64_addr : if(nps=64) generate

	get_64_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_512_addr : if(nps=512) generate

get_512_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + ('0' & k_count(6));
				 	swa <= '0' & k_count(6);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_1024_addr : if(nps=1024) generate

get_1024_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				 	swa <= k_count(7 downto 6);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
	 
		
end generate gen_1024_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_2048_addr : if(nps=2048) generate

get_2048_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				 	swa <= k_count(7 downto 6);
				when "101" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) + ('0' & k_count(8));
				 	swa <= '0' & k_count(8);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_2048_sw;
	
	 
		
end generate gen_2048_addr;


	gen_4096_addr : if(nps=4096) generate

		get_4096_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
-----------------------------------------------------------------------------------------------
--N-8192
-----------------------------------------------------------------------------------------------
gen_8192_addr : if(nps=8192) generate
get_8192_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
				 	swa <= k_count(7 downto 6);
				when "101" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+k_count(9 downto 8);
				 	swa <= k_count(9 downto 8);
				when "110" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0) + k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6) +k_count(9 downto 8) + ('0' & k_count(10));
				 	swa <= '0' & k_count(10);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_8192_sw;
end generate gen_8192_addr;
	
-----------------------------------------------------------------------------------------------
--N=16384
-----------------------------------------------------------------------------------------------
	gen_16384_addr : if(nps=16384) generate

		get_16384_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8)+ k_count(11 downto 10);
						 	swa <= k_count(11 downto 10);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;


end generate gen_se_addr;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Dual Engine Switch Generator
-----------------------------------------------------------------------------------------------

gen_de_addr : if(nume=2) generate 
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_64_addr : if(nps=64) generate

	get_64_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + ('0' & k_count(2));
				 	swa <= '0' & k_count(2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2);
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = mod(floor(k/4),4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4)
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_512_addr : if(nps=512) generate

get_512_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_1024_addr : if(nps=1024) generate

get_1024_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					--    swd = mod(k,4);
        	--    swa = mod(k,4)
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					--    swd = mod(floor(k/1)+floor(k/4),4);
        	--    swa = floor(k/4);
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
        	--    swa = mod(floor(k/16),4);
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
					--    swa = mod(floor(k/64),4);
         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + ('0' & k_count(6));
				 	swa <= '0' & k_count(6);
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
	 
		
end generate gen_1024_addr;


	gen_2048_addr : if(nps=2048) generate
		get_2048_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
	end generate gen_2048_addr;
	
	gen_4096_addr : if(nps=4096) generate
		get_4096_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ ('0' & k_count(8));
						 	swa <= '0' & k_count(8);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
	
	gen_8192_addr : if(nps=8192) generate
		get_8192_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) ;
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
	end generate gen_8192_addr;
	
	gen_16384_addr : if(nps=16384) generate
		get_16384_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							--    swd = mod(k,4);
		        	--    swa = mod(k,4)
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							--    swd = mod(floor(k/1)+floor(k/4),4);
		        	--    swa = floor(k/4);
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16),4);
		        	--    swa = mod(floor(k/16),4);
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64),4);
							--    swa = mod(floor(k/64),4);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/256);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							--    swd = mod(floor(k/1)+floor(k/4)+floor(k/16)+floor(k/64)+floor(k/256),4);
		        	--    swa = floor(k/1024);
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8) + ('0' & k_count(10));
						 	swa <= '0' & k_count(10);
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;
end generate gen_de_addr;

-----------------------------------------------------------------------------------------------
-- QUAD Engine Switch Generator
-----------------------------------------------------------------------------------------------

gen_qe_addr : if(nume=4) generate 
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_64_addr : if(nps=64) generate

	get_64_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
				 	swd <= k_count(1 downto 0) + ('0' & k_count(2));
				 	swa <= '0' & k_count(2);
				when others =>
				 	 	swd <=(others=>'0');
				 	 	swa <=(others=>'0');
			end case;
		end if;
	end process get_64_sw;
	
	 
end generate gen_64_addr;

-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_128_addr : if(nps=128) generate
--
get_128_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2);
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_128_sw;
	
	 
end generate gen_128_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

gen_256_addr : if(nps=256) generate
--
get_256_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(1 downto 0) is
				when "01" =>
         	swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "10" =>
				 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "11" => 	
				 	swd <= k_count(1 downto 0)+k_count(3 downto 2);
				 	--swd <= "00";
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_256_sw;
	
	 
end generate gen_256_addr;
-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------
gen_512_addr : if(nps=512) generate

get_512_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					swd <= k_count(1 downto 0)+k_count(3 downto 2) + ('0' & k_count(4));
				 	swa <= '0' & k_count(4);
				when "100" => 	
				 	swd <= "00";
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_512_sw;
	
	 
		
end generate gen_512_addr;
-----------------------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------------------
gen_1024_addr : if(nps=1024) generate

get_1024_sw : process(clk,p_count,k_count) is
	begin
		if(rising_edge(clk)) then
			case p_count(2 downto 0) is
				when "001" =>
					swd <= k_count(1 downto 0);
         	swa <= k_count(1 downto 0);
				when "010" =>
					swd <= k_count(1 downto 0) + k_count(3 downto 2);
				 	swa <= k_count(3 downto 2);
				when "011" => 	
					swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
				 	swa <= k_count(5 downto 4);
				when "100" => 	
					swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) ;
				 	swa <= "00";
				when others =>
				 	swd <=(others=>'0');
				 	swa <=(others=>'0');
			end case;
		end if;
	end process get_1024_sw;
	
	 
		
end generate gen_1024_addr;


	gen_2048_addr : if(nps=2048) generate
		get_2048_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4) + ('0' & k_count(6));
						 	swa <= ('0' & k_count(6));
						when "101" => 	
						 	swd <= "00";
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_2048_sw;
	end generate gen_2048_addr;
	
	gen_4096_addr : if(nps=4096) generate
		get_4096_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4)  + k_count(7 downto 6);
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_4096_sw;
	end generate gen_4096_addr;
	
	gen_8192_addr : if(nps=8192) generate
		get_8192_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
		         	swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
						 	swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
						 	swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
		         	swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ ('0' & k_count(8));
						 	swa <= '0' & k_count(8);
						when "110" => 	 	
		         	swd <= "00";
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_8192_sw;
	end generate gen_8192_addr;
	
	gen_16384_addr : if(nps=16384) generate
		get_16384_sw : process(clk,p_count,k_count) is
			begin
				if(rising_edge(clk)) then
					case p_count(2 downto 0) is
						when "001" =>
							swd <= k_count(1 downto 0);
		         	swa <= k_count(1 downto 0);
						when "010" =>
							swd <= k_count(1 downto 0) + k_count(3 downto 2);
						 	swa <= k_count(3 downto 2);
						when "011" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) + k_count(5 downto 4);
						 	swa <= k_count(5 downto 4);
						when "100" => 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6);
						 	swa <= k_count(7 downto 6);
						when "101" => 	 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= k_count(9 downto 8);
						when "110" => 	 	
							swd <= k_count(1 downto 0)+k_count(3 downto 2) +k_count(5 downto 4) + k_count(7 downto 6)+ k_count(9 downto 8);
						 	swa <= "00";
						when others =>
						 	swd <=(others=>'0');
						 	swa <=(others=>'0');
					end case;
				end if;
			end process get_16384_sw;
	end generate gen_16384_addr;
end generate gen_qe_addr;


end generate gen_b;

end;
