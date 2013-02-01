
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity cronometer is
	port (
   	startStop: IN std_logic;
   	puesta0: IN std_logic;
   	clk: IN std_logic;
	 	reset: IN std_logic;    --reset activo a baja!
		ampliacion: IN std_logic;
  	rightSegs: OUT std_logic_vector(6 downto 0);
	 	leftSegs: OUT std_logic_vector(6 downto 0);
		upSegs: OUT std_logic_vector(6 downto 0);
		puntoSegs1: OUT std_logic;
		puntoSegs2: OUT std_logic;
		puntoSegs3: OUT std_logic
	);
end cronometer;

 
architecture Behavioral of cronometer is
	
	component debouncer	
		port ( rst: IN std_logic;   --reset a 1!
				clk: IN std_logic;
				x: IN std_logic;
				xDeb: OUT std_logic;
				xDebFallingEdge: OUT std_logic;
				xDebRisingEdge: OUT std_logic
		);
	end component; 
	
	signal startStop2: std_logic;
  signal puesta02: std_logic;
	signal start: std_logic;   -- biestable T: 1 cuando cuente, 0 cuando no cuente
	
	signal cuentacont1: STD_LOGIC_VECTOR(23 downto 0);  --contador1decima
	signal fin_cuenta1: STD_LOGIC;
	signal cuentacont2: STD_LOGIC_VECTOR(3 downto 0);  --contador decimas de segundo
	signal fin_cuenta2: STD_LOGIC;
	signal cuentacont3: STD_LOGIC_VECTOR(3 downto 0);  --contador unidades de segundo
	signal fin_cuenta3: STD_LOGIC;
	signal cuentacont4: STD_LOGIC_VECTOR(3 downto 0);  --contador decenas de segundo
	signal fin_cuenta4: STD_LOGIC;
	signal cuentacont5: STD_LOGIC_VECTOR(3 downto 0);  --contador unidades de minuto
	signal fin_cuenta5: STD_LOGIC;
	signal cuentacont6: STD_LOGIC_VECTOR(3 downto 0);  --contador decenas de minuto
	signal fin_cuenta6: STD_LOGIC;
	
	signal senialpunto: STD_LOGIC;
	signal cuenta_segs_right: STD_LOGIC_VECTOR(3 downto 0);
	signal cuenta_segs_left: STD_LOGIC_VECTOR(3 downto 0);
	
  
begin
  
	norebotes1: debouncer port map ( 	rst => reset,
													clk => clk,
													x => startStop,
													xDeb => open,
													xDebFallingEdge => startStop2, 
													xDebRisingEdge => open
												);
	
	norebotes2: debouncer port map ( 	rst => reset,
													clk => clk,
													x => puesta0,
													xDeb => open,
													xDebFallingEdge => puesta02, 
													xDebRisingEdge => open
												);
	
	
	contador1decima: process(reset,clk,startStop2,puesta02)  --contador mod 10.000.000 (de 0 a 9.999.999)
	begin
		if(reset = '0')then
			cuentacont1 <= (others => '0');
			fin_cuenta1 <= '0';
			start <= '0';
			senialpunto <= '0';
		elsif(clk'event and clk = '1') then
				if (startStop2 = '1') then    --biestable T
					start <= not start;
				end if;
				if (puesta02 = '1') then
					cuentacont1  <= (others => '0');
					fin_cuenta1 <= '0';
				elsif (start = '1' and cuentacont1 /=   "100110001001011001111111") then  
					cuentacont1 <= cuentacont1 + 1; 
					fin_cuenta1 <= '0';
				elsif (start = '1' and cuentacont1 = "100110001001011001111111") then
					fin_cuenta1 <= '1';
					senialpunto <= not senialpunto;
					puntoSegs1 <= senialpunto;
					puntoSegs2 <= senialpunto;
					puntoSegs3 <= senialpunto;
					cuentacont1  <= (others => '0');
				end if;
				if (fin_cuenta1 = '1') then
					fin_cuenta1 <= '0';
				end if;				
		end if;
	end process contador1decima;


	contador_decimas: process(reset,clk,puesta02,fin_cuenta1)  --contador mod 10 (de 0 a 9)
	begin
		if(reset = '0')then
			cuentacont2 <= (others => '0');
			fin_cuenta2 <= '0';
		elsif(clk'event and clk = '1') then
				if (puesta02 = '1') then
					cuentacont2  <= (others => '0');
					fin_cuenta2 <= '0';	
				elsif (fin_cuenta1 = '1' and cuentacont2 /= "1001") then  
					cuentacont2  <= cuentacont2 + 1;  
					fin_cuenta2 <= '0';					
				elsif (fin_cuenta1 = '1' and cuentacont2 = "1001") then
					fin_cuenta2 <= '1';
					cuentacont2  <= (others => '0');
				end if;
				if (fin_cuenta2 = '1') then
					fin_cuenta2 <= '0';
				end if;	
		end if;
	end process contador_decimas;
	
	
	contador_uds_seg: process(reset,clk,puesta02,fin_cuenta2)  --contador mod 10 (de 0 a 9)
	begin
		if(reset = '0')then
			cuentacont3 <= (others => '0');
			fin_cuenta3 <= '0';
		elsif(clk'event and clk = '1') then
				if (puesta02 = '1') then
					cuentacont3  <= (others => '0');
					fin_cuenta3 <= '0';
				elsif (fin_cuenta2 = '1' and cuentacont3 /= "1001") then  
					cuentacont3 <= cuentacont3 + 1; 
					fin_cuenta3 <= '0';					
				elsif (fin_cuenta2 = '1' and cuentacont3 = "1001") then
					fin_cuenta3 <= '1';
					cuentacont3  <= (others => '0');
				end if;
				if (fin_cuenta3 = '1') then
					fin_cuenta3 <= '0';
				end if;	
		end if;
	end process contador_uds_seg;
	
	
	contador_decenas_seg: process(reset,clk,puesta02,fin_cuenta3)  --contador mod 6 (de 0 a 5)
	begin
		if(reset = '0')then
			cuentacont4 <= (others => '0');
			fin_cuenta4 <= '0';
		elsif(clk'event and clk = '1') then
				if (puesta02 = '1') then
					cuentacont4  <= (others => '0');
					fin_cuenta4 <= '0';		
				elsif (fin_cuenta3 = '1' and cuentacont4 /= "0101") then  
					cuentacont4  <= cuentacont4 + '1';  
					fin_cuenta4 <= '0';					
				elsif (fin_cuenta3 = '1' and cuentacont4 = "0101") then
					fin_cuenta4 <= '1';
					cuentacont4  <= (others => '0');
				end if;
				if (fin_cuenta4 = '1') then
					fin_cuenta4 <= '0';
				end if;	
		end if;
	end process contador_decenas_seg;
	
	
	contador_uds_minuto: process(reset,clk,puesta02,fin_cuenta4)  --contador mod 10 (de 0 a 9)
	begin
		if(reset = '0')then
			cuentacont5 <= (others => '0');
			fin_cuenta5 <= '0';
		elsif(clk'event and clk = '1') then
				if (puesta02 = '1') then
					cuentacont5  <= (others => '0');
					fin_cuenta5 <= '0';		
				elsif (fin_cuenta4 = '1' and cuentacont5 /= "1001") then  
					cuentacont5  <= cuentacont5 + '1';  
					fin_cuenta5 <= '0';					
				elsif (fin_cuenta4 = '1' and cuentacont5 = "1001") then
					fin_cuenta5 <= '1';
					cuentacont5  <= (others => '0');
				end if;
				if (fin_cuenta5 = '1') then
					fin_cuenta5 <= '0';
				end if;	
		end if;
	end process contador_uds_minuto;


	contador_decenas_minuto: process(reset,clk,puesta02,fin_cuenta5)  --contador mod 6 (de 0 a 5)
	begin
		if(reset = '0')then
			cuentacont6 <= (others => '0');
			fin_cuenta6 <= '0';
		elsif(clk'event and clk = '1') then
				if (puesta02 = '1') then
					cuentacont6  <= (others => '0');
					fin_cuenta6 <= '0';		
				elsif (fin_cuenta5 = '1' and cuentacont6 /= "0101") then  
					cuentacont6  <= cuentacont6 + '1';  
					fin_cuenta6 <= '0';					
				elsif (fin_cuenta5 = '1' and cuentacont6 = "0101") then
					fin_cuenta6 <= '1';
					cuentacont6  <= (others => '0');
				end if;
				if (fin_cuenta6 = '1') then
					fin_cuenta6 <= '0';
				end if;	
		end if;
	end process contador_decenas_minuto;	
	
	
	conv7segRight:	process(cuenta_segs_right)
	begin
		case cuenta_segs_right is
											  -- gfedcba
			when "0000" => rightSegs <= "0111111";   
			when "0001" => rightSegs <= "0000110"; 
			when "0010" => rightSegs <= "1011011"; 
			when "0011" => rightSegs <= "1001111"; 
			when "0100" => rightSegs <= "1100110";
			when "0101" => rightSegs <= "1101101"; 
			when "0110" => rightSegs <= "1111101"; 
			when "0111" => rightSegs <= "0000111"; 
			when "1000" => rightSegs <= "1111111"; 
			when "1001" => rightSegs <= "1100111";
			
			when "1010" => rightSegs <= "1110111";
			when "1011" => rightSegs <= "1111100";
			when "1100" => rightSegs <= "0111001";
			when "1101" => rightSegs <= "1011110";
			when "1110" => rightSegs <= "1111001";
			when "1111" => rightSegs <= "1110001";
			when OTHERS => rightSegs <= "1111001";  -- error
			end case;
	end process;
	
	
	conv7segLeft:	process(cuenta_segs_left)
	begin
		case cuenta_segs_left is
								      	 -- gfedcba
			when "0000" => leftSegs <= "0111111";   
			when "0001" => leftSegs <= "0000110"; 
			when "0010" => leftSegs <= "1011011"; 
			when "0011" => leftSegs <= "1001111"; 
			when "0100" => leftSegs <= "1100110";
			when "0101" => leftSegs <= "1101101"; 
			when "0110" => leftSegs <= "1111101"; 
			when "0111" => leftSegs <= "0000111"; 
			when "1000" => leftSegs <= "1111111"; 
			when "1001" => leftSegs <= "1100111";
			
			when "1010" => leftSegs <= "1110111";
			when "1011" => leftSegs <= "1111100";
			when "1100" => leftSegs <= "0111001";
			when "1101" => leftSegs <= "1011110";
			when "1110" => leftSegs <= "1111001";
			when "1111" => leftSegs <= "1110001";
			when OTHERS => leftSegs <= "1111001";  -- error
			end case;
	end process;	 

	conv7segUp:	process(cuentacont2)
	begin
		case cuentacont2 is
								     	  -- gfedcba
			when "0000" => upSegs <= "0111111";   
			when "0001" => upSegs <= "0000110"; 
			when "0010" => upSegs <= "1011011"; 
			when "0011" => upSegs <= "1001111"; 
			when "0100" => upSegs <= "1100110";
			when "0101" => upSegs <= "1101101"; 
			when "0110" => upSegs <= "1111101"; 
			when "0111" => upSegs <= "0000111"; 
			when "1000" => upSegs <= "1111111"; 
			when "1001" => upSegs <= "1100111";
			
			when "1010" => upSegs <= "1110111";
			when "1011" => upSegs <= "1111100";
			when "1100" => upSegs <= "0111001";
			when "1101" => upSegs <= "1011110";
			when "1110" => upSegs <= "1111001";
			when "1111" => upSegs <= "1110001";
			when OTHERS => upSegs <= "1111001";  -- error
			end case;
	end process;	

	segunda_parte: process(ampliacion)
	begin
		if (ampliacion = '0') then 
			cuenta_segs_right <= cuentacont3;
			cuenta_segs_left <= cuentacont4;
		else
			cuenta_segs_right <= cuentacont5;
			cuenta_segs_left <= cuentacont6;
		end if;
	end process;

end Behavioral; 

