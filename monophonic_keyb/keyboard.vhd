
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity keyboard is
	port(
    clk: IN std_logic;
    rst: IN std_logic;
    ps2Clk: IN std_logic;
    ps2Data: IN std_logic;
	 segs : out  STD_LOGIC_VECTOR (6 downto 0);	  
	 altavoz: OUT std_logic
  );
end keyboard;

 
architecture Behavioral of keyboard is

	component ps2KeyboardInterface	
		port ( clk: IN std_logic;
				 rst: IN std_logic;
				 ps2Clk: IN std_logic;
				 ps2Data: IN std_logic;        
				 data: OUT std_logic_vector (7 DOWNTO 0);
				 newData: OUT std_logic;
				 newDataAck: IN std_logic
		);
	end component; 
	
	type fsm_estados is (esperando, pulsada, despulsarPosible);
	signal estado: fsm_estados;
	
	signal scancode: std_logic_vector (7 downto 0);
	signal newData: std_logic;
	signal newDataAck: std_logic;
	signal letra: std_logic_vector (7 downto 0);
	signal in_semiperiodo: std_logic_vector (17 downto 0);
	signal out_semiperiodo: std_logic_vector (17 downto 0);
	signal cuentacont: std_logic_vector (17 downto 0);
	signal onda: std_logic;
	signal silencio: std_logic;
	signal clSemiper: std_logic;
	signal clLetra: std_logic;
	signal ldLetra: std_logic;
	signal ldNewNote: std_logic;
	signal  st : std_logic_vector (2 downto 0); 


begin	
	 
	interfaz_ps2: ps2KeyboardInterface port map (
													rst => rst,
													clk => clk,
													ps2Clk => ps2Clk,
													ps2Data => ps2Data,
													data => scancode, 
													newData => newData,
													newDataAck => newDataAck
												);
												
												
	--tabla memoria para convertir codigo de teclas al semiperiodo de la nota
	memoria_notas: process(letra)
	begin
		case letra is 
			when "00011100" => in_semiperiodo <= "010111010101001101"; --A(1C): do
			when "00011101" => in_semiperiodo <= "010110000001001011"; --W(1D): do#
			when "00011011" => in_semiperiodo <= "010100110010000000"; --S(1B): re
			when "00100100" => in_semiperiodo <= "010011100111101000"; --E(24): re#
			when "00100011" => in_semiperiodo <= "010010100001001001"; --D(23): mi
			when "00101011" => in_semiperiodo <= "010001011110101000"; --F(2B): fa
			when "00101100" => in_semiperiodo <= "010000011111101111"; --T(2C): fa#
			when "00110100" => in_semiperiodo <= "001111100100011111"; --G(34): sol
			when "00110101" => in_semiperiodo <= "001110101100001000"; --Y(35): sol#
			when "00110011" => in_semiperiodo <= "001101110111110010"; --H(33): la
			when "00111100" => in_semiperiodo <= "001101000101111001"; --U(3C): la#
			when "00111011" => in_semiperiodo <= "001100010110111001"; --J(3b): si
			when "01000010" => in_semiperiodo <= "001011101010011101"; --K(42): do 
			when "00000000" => in_semiperiodo <= "000000000000000000"; -- silencio
			when others     => in_semiperiodo <= "000000000000000000"; -- silencio
		end case;
	end process memoria_notas;

	
	--maquina de estados-----------------------------------------------------

	controladorEstados: process (clk, rst, newData, scancode) 
	begin 
		if(rst = '0') then   
			estado <= esperando;
		elsif (clk'event and clk = '1') then
			estado <= esperando;  -- estado por defecto, puede ser sobreescrito luego
			case estado is
				when esperando => 
					if (newData = '1') then
						estado <= pulsada;
					else									
						estado <= esperando;
					end if;
					
				when pulsada => 
					if (newData = '1' and scancode /= "11110000") then  --11110000: F0
						estado <= pulsada;
					elsif (newData = '1' and scancode = "11110000") then  --11110000: F0
						estado <= despulsarPosible;
					else 
						estado <= pulsada;
					end if;
					
				when despulsarPosible =>
					if (newData = '1' and scancode = letra) then
						estado <= esperando;
					elsif (newData = '1' and scancode /= letra) then
						estado <= pulsada;
					else 
						estado <= despulsarPosible;
					end if;					
			end case;
		end if;
	end process;


	generadorSalidaMealy: process (newDataAck, scancode, estado, newData, letra)
	begin
		--inicializamos:
		newDataAck <= '0';
		clLetra <= '0';
		ldletra <= '0';
		case estado is
			when esperando =>
				if (newData = '1') then
					ldletra <= '1';
					ldNewNote <= '1';
					newDataAck <= '1';
				end if;
			when pulsada =>
				if (newData = '1') then  --esto contiene las 2 posibles transiciones
						newDataAck <= '1';
						ldletra <= '0';
				end if;
			when despulsarPosible =>
				if (newData = '1') then
					if (scancode = letra) then
						clLetra <= '1';
						newDataAck <= '1';
						ldNewNote <= '1';
					else
						newDataAck <= '1';
					end if;
				end if;
			when others => 
				newDataAck <= '0';	
		end case;
	end process;
	
	
	generadorSalidaMoore: process (estado) --genera st
	begin
		case estado is
			when esperando =>
			  st <= "000";  	
			when pulsada =>
			  st <= "001"; 
			when despulsarPosible =>
			  st <= "010"; 
		end case;
	end process;
	
	
	conversor7seg: process(st)
	begin
		case st is
								     -- gfedcba
			when "000" => segs <= "0111111";   -- cerrado: Locked
			when "001" => segs <= "0000110"; 
			when "010" => segs <= "1011011"; 
			when "011" => segs <= "1001111"; 
			when others => segs <= "1111001";  -- error
			end case;
	end process;
	
	
	-----------------------------------------------------------------------------

	oscilador18bits: process(clk,rst,clSemiper) 
	begin
		if(rst = '0')then
			cuentacont <= (others => '0');
			onda <= '0';      --reset biestable T
			
		elsif(clk'event and clk = '1') then
				if (clSemiper = '1') then   
					cuentacont  <= (others => '0');
					onda <= not onda;
				else 
					cuentacont  <= cuentacont + 1;  
				end if;
		end if;	
	end process oscilador18bits;		

	
	generadorSonido: process(clk,rst,out_semiperiodo,cuentacont,letra,onda,silencio)
	begin
		if(rst = '0')then -- registro SemiPer
				out_semiperiodo <= (others => '0');
		elsif(clk'event and clk = '1' and ldNewNote = '1') then	
				out_semiperiodo <= in_semiperiodo;
		end if;
		
		if (out_semiperiodo = cuentaCont) then -- comparador del oscilador
			clSemiper <= '1';
		else 
			clSemiper <= '0';
		end if;
		
		if (letra = "00000000") then  -- puerta NOR para generar silencio
			silencio <= '1';
		else 
			silencio <= '0';
		end if;
		
		altavoz <= onda or silencio;  -- puerta OR para generar onda del sonido
				
	end process generadorSonido;

		
	registroLetra: process(rst,clk,ldLetra,clLetra)
	begin
		if(rst = '0')then 
				letra <= (others => '0');
		elsif(clk'event and clk = '1' ) then
				if (clLetra = '1') then
					letra <= (others => '0');
				elsif (ldLetra = '1') then	
					letra <= scancode;
				end if;
		end if;	
	end process	registroLetra;
		
end Behavioral;

