-- hecho para ser visto con tab size = 3

library IEEE;
library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity tron is
	port (
    ps2Clk: IN std_logic;
    ps2Data: IN std_logic;
    clk: IN std_logic;
	reset: IN std_logic;    --reset activo a baja!
	hSync: OUT std_logic;
	Vsync: OUT std_logic;
	colisionOUT: OUT std_logic;
	DI2: OUT std_logic_vector(0 downto 0);
	DI1: OUT std_logic_vector(0 downto 0);
	segs: OUT std_logic_vector (6 downto 0);
	R: OUT std_logic_vector (2 downto 0); -- alconversor D/A
	G: OUT std_logic_vector (2 downto 0); -- alconversor D/A
	B: OUT std_logic_vector (2 downto 0)  -- alconversor D/A
	);
end tron;

 
architecture Behavioral of tron is
 
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
	
	--señales maquina de estados
	type fsmEstados is (pulsadas, despulsadas);
	signal estado: fsmEstados;
	type fsmEstados2 is (jugando, parado, reseteo);
	signal estado2: fsmEstados2;
	
	--señales PS2
	signal newData, newDataAck: std_logic;
	signal scancode: std_logic_vector (7 downto 0);

	--señales VGA
	signal senialHSync, senialVSync: std_logic;
	signal finPixelCont: std_logic;
	signal cuentaPixelCont: std_logic_vector (10 downto 0);
	signal cuentaLineCont: std_logic_vector (9 downto 0);
	signal comp1, comp2, comp3, comp4, comp5, comp6: std_logic;	
	signal Rcoche1,Rcoche2,Restela: std_logic_vector (2 downto 0); 
	signal Gcoche1,Gcoche2,Gestela: std_logic_vector (2 downto 0); 
	signal Bcoche1,Bcoche2,Bestela: std_logic_vector (2 downto 0);
	
	--señales juego
	signal pixelCoche1Hor,pixelCoche2Hor: std_logic_vector (7 downto 0); --153 pixeles (10011001)
	signal pixelCoche1Ver,pixelCoche2Ver: std_logic_vector (6 downto 0); --102 pixeles
	signal movCoche1,movCoche2: std_logic_vector (1 downto 0);  -- 00 = arriba , 01 = derecha , 10 = abajo , 11 = izquierda
	signal ldMov1,ldMov2: std_logic;
	signal moverCoches: std_logic;   
	signal cuenta1dec: STD_LOGIC_VECTOR(19 downto 0);  --contador1decima
	signal finCuenta1Dec: STD_LOGIC;
	signal cuentacontReseteo: std_logic_vector(14 downto 0);
	signal finCuentaContReseteo,enableContReseteo,hayColision: std_logic;
	signal coche1SeMueve, coche2SeMueve,coche1SeMueve2, coche2SeMueve2: std_logic;
	
	--señales teclas 
	signal teclaSPC: std_logic;
	signal clTeclaSPC: std_logic;
	signal ldTeclaSPC: std_logic;
	
	--seniales memorias
	signal estelaCoche1MenosSig,estelaCoche2MenosSig,estelaCoche1MasSig,estelaCoche2MasSig,DOBcoche1MenosSig,DOBcoche1MasSig,DOBcoche2MenosSig,DOBcoche2MasSig: std_logic_vector(0 downto 0);
	signal selPixelPantalla: std_logic_vector (14 downto 0);  -- pixeles logicos hor (120) concatenado con pixeles logicos ver (153): cuentaPixelCont(10 downto 3)++cuentaLineCont(8 downto 2)
	signal selPixelCoche1,selPixelCoche2: std_logic_vector (14 downto 0);  --pixelCoche1/2Hor concatenado pixelCoche1/2Ver
	signal estelaMem: std_logic_vector (1 downto 0);
	signal WEBmenosSig1, WEBmasSig,WEBmenosSig2, WEBmasSig2,WEcoche1,WEcoche2,senialWEA: std_logic; 
	signal DIBcoche1,DIBcoche2,DOBcoche1,DOBcoche2: std_logic_vector(0 downto 0);

	--señales de depuracion
	signal st : std_logic_vector (1 downto 0); 


begin

--------------------------- RAM ------------------------------------------------
	colisionOUT <= hayColision;
	DI1 <= DIBcoche1;
	DI2 <= DIBcoche2;

	selPixelCoche1(14 downto 7) <= pixelCoche1Hor;
	selPixelCoche1(6 downto 0) <= pixelCoche1Ver;
	
	selPixelCoche2(14 downto 7) <= pixelCoche2Hor;
	selPixelCoche2(6 downto 0) <= pixelCoche2Ver;
	
	selPixelPantalla(14 downto 7) <= cuentaPixelCont(10 downto 3);
	selPixelPantalla(6 downto 0) <= cuentaLineCont(8 downto 2); 
	
	
	--http://www.xilinx.com/itp/xilinx10/books/docs/spartan3_hdl/spartan3_hdl.pdf
	rojoMenosSignif: RAMB16_S1_S1
		generic map(
			WRITE_MODE_B => "READ_FIRST"
		)
		port map (
			DOA => estelaCoche1MenosSig, -- Port A 1-bit Data Output
			DOB => DOBcoche1MenosSig, -- Port B 1-bit Data Output
			ADDRA => selPixelPantalla(13 downto 0), -- Port A 14-bit Address Input
			ADDRB => selPixelCoche1(13 downto 0), -- Port B 14-bit Address Input
			CLKA => clk, -- Port A Clock
			CLKB => clk, -- Port B Clock
			DIA => "0", -- Port A 1-bit Data Input
			DIB => DIBcoche1, -- Port B 1-bit Data Input  --pintamos rojo
			ENA => '1', -- Port A RAM Enable Input
			ENB => '1', -- PortB RAM Enable Input
			SSRA => '0', -- Port A Synchronous Set/Reset Input
			SSRB => '0', -- Port B Synchronous Set/Reset Input
			WEA => senialWEA, -- Port A Write Enable Input
			WEB => WEBmenosSig1 -- Port B Write Enable Input
		);
		
	rojoMasSignif: RAMB16_S1_S1
		generic map(
			WRITE_MODE_B => "READ_FIRST"
		)
		port map (
			DOA => estelaCoche1MasSig, -- Port A 1-bit Data Output
			DOB => DOBcoche1MasSig, -- Port B 1-bit Data Output
			ADDRA => selPixelPantalla(13 downto 0), -- Port A 14-bit Address Input
			ADDRB => selPixelCoche1(13 downto 0), -- Port B 14-bit Address Input
			CLKA => clk, -- Port A Clock
			CLKB => clk, -- Port B Clock
			DIA => "0", -- Port A 1-bit Data Input
			DIB => DIBcoche1, -- Port B 1-bit Data Input --pintamos rojo
			ENA => '1', -- Port A RAM Enable Input
			ENB => '1', -- PortB RAM Enable Input
			SSRA => '0', -- Port A Synchronous Set/Reset Input
			SSRB => '0', -- Port B Synchronous Set/Reset Input
			WEA => senialWEA, -- Port A Write Enable Input
			WEB =>WEBmasSig -- Port B Write Enable Input
		);
	
	azulMenosSignif: RAMB16_S1_S1
		generic map(
			WRITE_MODE_B => "READ_FIRST"
		)
		port map (
			DOA => estelaCoche2MenosSig, -- Port A 1-bit Data Output
			DOB => DOBcoche2MenosSig, -- Port B 2-bit Data Output
			ADDRA => selPixelPantalla(13 downto 0), -- Port A 14-bit Address Input
			ADDRB => selPixelCoche2(13 downto 0), -- Port B 14-bit Address Input
			CLKA => clk, -- Port A Clock
			CLKB => clk, -- Port B Clock
			DIA => "0", -- Port A 1-bit Data Input
			DIB => DIBcoche2, -- Port B 1-bit Data Input --pintamos azul
			ENA => '1', -- Port A RAM Enable Input
			ENB => '1', -- PortB RAM Enable Input
			SSRA => '0', -- Port A Synchronous Set/Reset Input
			SSRB => '0', -- Port B Synchronous Set/Reset Input
			WEA => senialWEA, -- Port A Write Enable Input
			WEB => WEBmenosSig2 -- Port B Write Enable Input
		);
	
	azulMasSignif: RAMB16_S1_S1
		generic map(
			WRITE_MODE_B => "READ_FIRST"
		)
		port map (
			DOA => estelaCoche2MasSig, -- Port A 1-bit Data Output
			DOB => DOBcoche2MasSig, -- Port B 1-bit Data Output
			ADDRA => selPixelPantalla(13 downto 0), -- Port A 14-bit Address Input
			ADDRB => selPixelCoche2(13 downto 0), -- Port B 14-bit Address Input
			CLKA => clk, -- Port A Clock
			CLKB => clk, -- Port B Clock
			DIA => "0", -- Port A 1-bit Data Input
			DIB => DIBcoche2, -- Port B 1-bit Data Input --pintamos azul
			ENA => '1', -- Port A RAM Enable Input
			ENB => '1', -- PortB RAM Enable Input
			SSRA => '0', -- Port A Synchronous Set/Reset Input
			SSRB => '0', -- Port B Synchronous Set/Reset Input
			WEA => senialWEA, -- Port A Write Enable Input
			WEB => WEBmasSig2 -- Port B Write Enable Input
		);	
	
	WEB_MasSig2
interfazPS2: ps2KeyboardInterface port map (
														rst => reset,
														clk => clk,
														ps2Clk => ps2Clk,
														ps2Data => ps2Data,
														data => scancode, 
														newData => newData,
														newDataAck => newDataAck
													);


	decoSalida: process(selPixelCoche1,selPixelCoche2,selPixelPantalla,DOBcoche1MenosSig,
						 DOBcoche1MasSig,DOBcoche2MenosSig,DOBcoche2MasSig,WEcoche1,
						 WEcoche2,estelaCoche1MenosSig,estelaCoche1MasSig,estelaCoche2MenosSig,
						 estelaCoche2MasSig)
	begin
		if (selPixelPantalla(14) = '0') then
			--direccionar a las menos signif
			estelaMem(1 downto 1) <= estelaCoche1MenosSig;
			estelaMem(0 downto 0) <= estelaCoche2MenosSig;
		else
			--direccionar a las mas signif
			estelaMem(1 downto 1) <= estelaCoche1MasSig;
			estelaMem(0 downto 0) <= estelaCoche2MasSig;
		end if;	
			
		if (selPixelCoche1(14) = '0') then
			--direccionar a las menos signif
			WEBmenosSig1 <= WEcoche1;
			WEBmasSig <= '0';
			DOBcoche1 <= DOBcoche1MenosSig;
		else
			--direccionar a las mas signif
			WEBmenosSig1 <= '0';
			WEBmasSig <= WEcoche1;
			DOBcoche1 <= DOBcoche1MasSig;
		end if;
		
		if (selPixelCoche2(14) = '0') then
			--direccionar a las menos signif
			WEBmenosSig2 <= WEcoche2;
			WEBmasSig2 <= '0';
			DOBcoche2 <= DOBcoche2MenosSig;
		else
			--direccionar a las mas signif
			WEBmenosSig2 <= '0';
			WEBmasSig2 <= WEcoche2;
			DOBcoche2 <= DOBcoche2MasSig;
		end if;
	end process decoSalida;
	
	


--------------------------- PANTALLA -------------------------------------------


	hSync <= senialHSync; 
	vSync <= senialVSync;

	pantalla: process(clk, reset,cuentaPixelCont,cuentaLineCont,Rcoche1,Rcoche2,
						Gcoche1,Gcoche2,Bcoche1,Bcoche2,Restela,Gestela,Bestela)
	begin
		
		--cont mod 1589 (pixelCont para sincronismo horizontal)
		if (cuentaPixelCont = "11000110100") then
			finPixelCont <= '1';
		else 
			finPixelCont <= '0';
		end if;
		
		if(reset = '0')then
			cuentaPixelCont <= (others => '0');
			finPixelCont <= '0';
		elsif(clk'event and clk = '1') then
				if (cuentaPixelCont /= "11000110100") then   --1588
					cuentaPixelCont  <= cuentaPixelCont + '1';  
				elsif (cuentaPixelCont = "11000110100") then
					cuentaPixelCont  <= (others => '0');	
				end if;
				
		end if;
		
		--cont mod 528 (lineCont para sincronismo vertical)
		if(reset = '0')then
			cuentaLineCont <= (others => '0');
		elsif(clk'event and clk = '1') then
				if (finPixelCont = '1' and cuentaLineCont /= "1000001111") then   --527
					cuentaLineCont  <= cuentaLineCont + '1';  
				elsif (finPixelCont = '1' and cuentaLineCont = "1000001111") then
					cuentaLineCont  <= (others => '0');
				end if;	
		end if;		
		
		--comparaciones
		if (cuentaPixelCont > 1257) then  comp1 <= '1';  else  comp1 <= '0'; end if;
		if (cuentaPixelCont > 1304) then  comp2 <= '1';  else  comp2 <= '0'; end if;
		if (cuentaPixelCont <= 1493) then  comp3 <= '1';  else  comp3 <= '0'; end if;
		if (cuentaLineCont > 479) then  comp4 <= '1';  else  comp4 <= '0'; end if;
		if (cuentaLineCont > 493) then  comp5 <= '1';  else  comp5 <= '0'; end if;
		if (cuentaLineCont <= 495) then  comp6 <= '1';  else  comp6 <= '0'; end if;  
		
		
		senialHSync <= comp2 nand comp3;
		senialVSync <= comp5 nand comp6;
		
		if (senialHSync = '0' or senialVSync = '0') then --no pinta
			R <= "000";
			G <= "000";
			B <= "000";
		else 
			R(2) <= ( (not (comp1 or comp4))  and  (Rcoche1(2) or Rcoche2(2) or Restela(2)) );
			R(1) <= ( (not (comp1 or comp4))  and  (Rcoche1(1) or Rcoche2(1) or Restela(1)) );
			R(0) <= ( (not (comp1 or comp4))  and  (Rcoche1(0) or Rcoche2(0) or Restela(0)) );
			G(2) <= ( (not (comp1 or comp4))  and  (Gcoche1(2) or Gcoche2(2) or Gestela(2)) );
			G(1) <= ( (not (comp1 or comp4))  and  (Gcoche1(1) or Gcoche2(1) or Gestela(1)) );
			G(0) <= ( (not (comp1 or comp4))  and  (Gcoche1(0) or Gcoche2(0) or Gestela(0)) );
			B(2) <= ( (not (comp1 or comp4))  and  (Bcoche1(2) or Bcoche2(2) or Bestela(2)) );
			B(1) <= ( (not (comp1 or comp4))  and  (Bcoche1(1) or Bcoche2(1) or Bestela(1)) );
			B(0) <= ( (not (comp1 or comp4))  and  (Bcoche1(0) or Bcoche2(0) or Bestela(0)) );
		end if;

	end process;
	

-------------------------------  PINTAR JUEGO ----------------------------------
		
			-- vertical: 479 limite de pixeles visibles
			-- 120 pixeles -> 479            x= (479*1)/120 = 3.99 = aprox 4
			-- 1   pixeles -> x
			
			-- horizontal: 1257 limite de pixeles visibles
			-- 153 pixeles -> 1257           x= (1257*1)/153 = 8.21 = aprox 8
			-- 1   pixeles -> x

	
	pintarCoche1: process(cuentaLineCont,cuentaPixelCont,pixelCoche1Ver,pixelCoche1Hor)
	begin
		-- inicializacion
		Rcoche1 <= "000";
		Gcoche1 <= "000";
		Bcoche1 <= "000";

		--pintar
		if ((cuentaLineCont(9 downto 2) >= pixelCoche1Ver-1 and 
			cuentaLineCont(9 downto 2) <= pixelCoche1Ver+1) and 
			(cuentaPixelCont(10 downto 3) >= pixelCoche1Hor-1 and 
			cuentaPixelCont(10 downto 3) <= pixelCoche1Hor+1)) then 
				Rcoche1 <= "111";--coche rojo
				Gcoche1 <= "000";
				Bcoche1 <= "000";
		end if;
	end process pintarCoche1;
	 
	 
	pintarCoche2: process(cuentaLineCont,cuentaPixelCont,pixelCoche2Ver,pixelCoche2Hor)
	begin
		-- inicializacion
		Rcoche2 <= "000";
		Gcoche2 <= "000";
		Bcoche2 <= "000";

		--pintar
		if ((cuentaLineCont(9 downto 2) >= pixelCoche2Ver-1 and 
			cuentaLineCont(9 downto 2) <= pixelCoche2Ver+1) and 
			(cuentaPixelCont(10 downto 3) >= pixelCoche2Hor-1 and 
			cuentaPixelCont(10 downto 3) <= pixelCoche2Hor+1)) then 
				Rcoche2 <= "000";
				Gcoche2 <= "000";
				Bcoche2 <= "111";--coche azul
		end if;
	end process pintarCoche2;
	
	
	pintarEstelas: process(cuentaLineCont,cuentaPixelCont,estelaMem)
	begin
		-- inicializacion
		Restela <= "000";
		Gestela <= "000";
		Bestela <= "000";

		--pintar
		case estelaMem is
			when "01" => Restela <= "000";  --pintamos estela azul
							 Gestela <= "000";
							 Bestela <= "111";
			when "10" => Restela <= "111";  --pintamos estela rojo
							 Gestela <= "000";
							 Bestela <= "000";
			when "11" => Restela <= "111";  --las estelas se superponen
							 Gestela <= "000";
							 Bestela <= "111";
			when others => Restela <= "000";  --no hay estela
								Gestela <= "000";
								Bestela <= "000";
		end case;
	end process pintarEstelas;
	
--#################### CONTROL JUEGO ###########################################
	
	
	contadorMediaDecima: process(reset,clk,cuenta1dec)  --contador mod 5.000.000 (de 0 a 4.999.999)
	begin
		if (cuenta1dec = "11110100001000111111") then
			finCuenta1Dec <= '1';
		else 
			finCuenta1Dec <= '0';
		end if;
		
		if(reset = '0')then
			cuenta1dec <= (others => '0');
			finCuenta1Dec <= '0';
		elsif(clk'event and clk = '1') then
			if (cuenta1dec /= "11110100001000111111") then  
				cuenta1dec <= cuenta1dec + 1; 
			elsif (cuenta1dec = "11110100001000111111") then
				cuenta1dec  <= (others => '0');
			end if;		
		end if;
	end process contadorMediaDecima;
	
	
	coche1: process(moverCoches,finCuenta1Dec,clk,reset,movCoche1,pixelCoche1Hor,pixelCoche1Ver)
	begin
		coche1SeMueve <= '1';
		if(finCuenta1Dec = '1' and moverCoches = '1') then
				coche1SeMueve <= '1';
		else 
				coche1SeMueve <= '0';
		end if;		
		
					
		--vertical: cont mod 102 y horizontal: cont mod 153 
		if (reset = '0')then   --pos inicial coche1
			pixelCoche1Ver <= "0001000";  --en 9
			pixelCoche1Hor <= "00000000";  --en 1
			coche1SeMueve <= '0';
		elsif (clk'event and clk = '1') then
			if(finCuenta1Dec = '1' and moverCoches = '1') then
				case movCoche1 is
					when "00" => 	if  (pixelCoche1Ver = 0) then --va hacia arriba
															pixelCoche1Ver <= "1110111";
														else
																pixelCoche1Ver <= pixelCoche1Ver - '1'; 
														end if;
					when "10" => 	if  (pixelCoche1Ver = 120) then  --va hacia abajo
																pixelCoche1Ver <= "0000000";
														else
																pixelCoche1Ver <= pixelCoche1Ver + '1';  
														end if;
					when "11" => 	if  ( pixelCoche1Hor = 0) then --va hacia izquierda
																pixelCoche1Hor <= "10011000";
														else
																pixelCoche1Hor <= pixelCoche1Hor - '1'; 
														end if;
					when "01" => 	if  (pixelCoche1Hor = 153) then --va hacia derecha
																pixelCoche1Hor <= "00000000";
														else
																pixelCoche1Hor <= pixelCoche1Hor + '1';  
														end if;
					when others => null;
				end case;
			end if;
			if (teclaSPC = '1') then
				pixelCoche1Ver <= "0001000";  --en 9
				pixelCoche1Hor <= "00000000";  --en 1
			end if;
		end if;				
	end process coche1;
	
	
	coche2: process(finCuenta1Dec,moverCoches,clk,reset,movCoche2,pixelCoche2Hor,pixelCoche2Ver)
	begin
		coche2SeMueve <= '0';
		if(finCuenta1Dec = '1' and moverCoches = '1') then
				coche2SeMueve <= '1';
		else 
				coche2SeMueve <= '0';
		end if;
		
		--vertical: cont mod 102 y horizontal: cont mod 153 
		if (reset = '0')then   --pos inicial coche2
			pixelCoche2Ver <= "1101110";  --en 110
			pixelCoche2Hor <= "10011000";  --en 152
			coche2SeMueve <= '0';
		elsif (clk'event and clk = '1') then
			if(finCuenta1Dec = '1' and moverCoches = '1') then
				case movCoche2 is
					when "00" => 	if  (pixelCoche2Ver = 0) then --va hacia arriba
															pixelCoche2Ver <= "1110111";
														else
															pixelCoche2Ver <= pixelCoche2Ver - '1'; 
														end if;
					when "10" => 	if  (pixelCoche2Ver = 120) then  --va hacia abajo
															pixelCoche2Ver <= "0000000";
														else
															pixelCoche2Ver <= pixelCoche2Ver + '1';  
														end if;
					when "11" => 	if  ( pixelCoche2Hor = 0) then --va hacia izquierda
															pixelCoche2Hor <= "10011000";
														else
															pixelCoche2Hor <= pixelCoche2Hor - '1'; 
														end if;
					when "01" => 	if  (pixelCoche2Hor = 153) then --va hacia derecha
															pixelCoche2Hor <= "00000000";
														else
															pixelCoche2Hor <= pixelCoche2Hor + '1';  
														end if;
					when others => null;
				end case;
			end if;
			if (teclaSPC = '1') then
				pixelCoche2Ver <= "1101110";  --en 110
				pixelCoche2Hor <= "10011000";  --en 152
			end if;
		end if;
	end process coche2;
	
	
	colision: process(estelaMem,DOBcoche1,DOBcoche2,coche1SeMueve,coche2SeMueve,WEcoche1,WEcoche2)
	begin
		hayColision <= '0';  
		  
		if (estelaMem = "11" or --chocan entre ellos
			(DOBcoche1 = "1" and WEcoche1 = '1') or (DOBcoche2 = "1" and WEcoche2 = '1') --chocan consigo mismo
		)then
				hayColision <= '1';
		else
				hayColision <= '0';
		end if;
 
	end process colision; 

	

------maquina de estados con registros de flags---------------------------------

	controladorEstados: process (clk, reset, newData, scancode) 
	begin 
		if(reset = '0') then   
			estado <= pulsadas;
		elsif (clk'event and clk = '1') then
			estado <= pulsadas;  -- estado por defecto, puede ser sobreescrito luego
			case estado is
				when pulsadas => 
					estado <= pulsadas;
					if (newData = '1' and scancode = "11110000") then  --11110000: F0
						estado <= despulsadas;
					end if;
					
				when despulsadas =>
					estado <= despulsadas;
					if (newData = '1') then
						estado <= pulsadas;
					end if;					
			end case;
		end if;
	end process;


	generadorSalidaMealy: process (reset,newDataAck, scancode, estado, newData)
	begin
		newDataAck <= '0';
		clTeclaSPC <= '0';	
		ldTeclaSPC <= '0';
		case estado is
			when pulsadas =>
				if (newData = '1') then  --11110000: F0
					case scancode is   	--registros de flags:
						when "00010101" => ldMov1 <= '1' ; --Q=15 arriba
						when "00011100" => ldMov1 <= '1' ; --A=1C abajo
						when "00011010" => ldMov1 <= '1' ; --Z=1A izq
						when "00100010" => ldMov1 <= '1' ; --X=22 der
						when "01001101" => ldMov2 <= '1' ; --P=4D arriba
						when "01001011" => ldMov2 <= '1' ; --L=4B abajo
						when "00110001" => ldMov2 <= '1' ; --N=31 izq
						when "00111010" => ldMov2 <= '1' ; --M=3A der
						when "00101001" => ldTeclaSPC <= '1'; clTeclaSPC <= '0';  --SPC=29 
						when others => null; 
					end case;
					newDataAck <= '1';
				end if;

			when despulsadas =>
				if (newData = '1') then
					case scancode is   	--registros de flags:
						when "00101001" => ldTeclaSPC <= '0'; clTeclaSPC <= '1';  --SPC=29 
						when others => null; 
					end case;
					newDataAck <= '1'; 
				end if;

			when others => null;	
		end case;
	end process;
	
	
--------------------------------------------------------------------------------
	
	biestableDteclaSPC: process(reset,clk,ldTeclaSPC,clTeclaSPC)
	begin
		if(reset = '0')then 
				teclaSPC <= '0';
		elsif(clk'event and clk = '1' ) then
				if (clTeclaSPC = '1') then
					teclaSPC <=  '0';
				elsif (ldTeclaSPC = '1') then	
					teclaSPC <= '1';
				end if;
		end if;	
	end process	biestableDteclaSPC;
	
	
	registroMovCoche1: process(reset,clk,ldMov1,teclaSPC,scancode)
	begin
		if(reset = '0')then 
				movCoche1 <= "01"; --hacia der
		elsif(clk'event and clk = '1' ) then
				if (teclaSPC = '1') then
					movCoche1 <= "01"; --hacia der
				elsif (ldMov1 = '1') then	
					case scancode is
						when "00010101" => movCoche1 <= "00"; 	  --Q=15 arriba
						when "00011100" => movCoche1 <= "10";	  --A=1C abajo
						when "00011010" => movCoche1 <= "11";	  --Z=1A izq
						when "00100010" => movCoche1 <= "01";	  --X=22 der
						when others => null;
					end case;
				end if;
		end if;	
	end process	registroMovCoche1;
	
	
	registroMovCoche2: process(reset,clk,ldMov2,teclaSPC,scancode)
	begin
		if(reset = '0')then 
				movCoche2 <= "11"; --hacia der
		elsif(clk'event and clk = '1' ) then
				if (teclaSPC = '1') then
					movCoche2 <= "11"; --hacia der
				elsif (ldMov2 = '1') then	
					case scancode is
						when "01001101" => movCoche2 <= "00"; 	  --P=4D arriba
						when "01001011" => movCoche2 <= "10"; 	  --L=4B abajo
						when "00110001" => movCoche2 <= "11"; 	  --N=31 izq
						when "00111010" => movCoche2 <= "01"; 	  --M=3A der
						when others => null;
					end case;
				end if;
		end if;	
	end process	registroMovCoche2;
	
	
-----maquina de estados del juego ----------------------------------------------

	controladorEstados2: process (clk, reset, finCuentaContReseteo, hayColision, teclaSPC, finCuenta1Dec) 
	begin 
		if(reset = '0') then   
			estado2 <= jugando;
		elsif (clk'event and clk = '1') then
			estado2 <= jugando;  -- estado por defecto, puede ser sobreescrito luego
			case estado2 is
				when jugando =>
					estado2 <= jugando;
					if (hayColision = '1') then 
						estado2 <= parado;
					elsif (teclaSPC = '1') then 
						estado2 <= reseteo;
					end if;	
				
				when parado =>
					estado2 <= parado;
					if (teclaSPC = '1') then 
						estado2 <= reseteo;
					end if;	

				when reseteo => 
					estado2 <= reseteo;
					if (finCuentaContReseteo = '1') then  
						estado2 <= jugando;
					end if;					
			end case;
		end if;
	end process;

	
	generadorSalidaMoore2: process (estado2) 
	begin
		DIBcoche1 <= "1";
		DIBcoche2 <= "1";	
		enableContReseteo <= '0';
		moverCoches <= '1';
		st <= "00";
		senialWEA <= '0';

		case estado2 is
			when jugando =>								
				DIBcoche1 <= "1";
				DIBcoche2 <= "1";	
				enableContReseteo <= '0';
				moverCoches <= '1';
				st <= "00";
				senialWEA <= '0';
		
			when parado =>								
				DIBcoche1 <= "0";
				DIBcoche2 <= "0";	
				enableContReseteo <= '0';
				moverCoches <= '0';
				st <= "01";
				senialWEA <= '0';
				
			when reseteo =>
				DIBcoche1 <= "0";
				DIBcoche2 <= "0";	
				enableContReseteo <= '1';
				moverCoches <= '0';
				st <= "10";
				senialWEA <= '1';
			
			when others => null;	
		end case;
	end process;
	
	
	conversor7seg: process(st)
	begin
		case st is
								     --gfedcba
			when "00" => segs <= "0111111";  
			when "01" => segs <= "0000110"; 
			when "10" => segs <= "1011011"; 
			when OTHERS => segs <= "1111001";  -- error
			end case;
	end process;
	
	
--------------------------------------------------------------------------------
	
	
	contReseteo: process(reset,clk,cuentacontReseteo,enableContReseteo)  --contador mod 2^15=32768	(120 x 153 pixeles)
	begin
		if (cuentacontReseteo = "111111111111111") then 
			finCuentaContReseteo <= '1';
		else
			finCuentaContReseteo <= '0';
		end if;
		
		if(reset = '0')then
			cuentacontReseteo <= (others => '0');
			finCuentaContReseteo <= '0';
		elsif(clk'event and clk = '1') then 
			if(enableContReseteo = '1') then
				if (cuentacontReseteo /= "111111111111111") then  
					cuentacontReseteo <= cuentacontReseteo + 1; 
				end if;
			elsif (enableContReseteo = '0') then
				cuentacontReseteo <= (others => '0');
			end if;
		end if;
	end process contReseteo;
	
		
	biestableDcoche1SeMueveRetrasa1ciclo: process(reset,clk,coche1SeMueve)   --con estos biestablesD conseguimos escribir sólo una vez en memoria por cada movimiento de coche
	begin
		if(reset = '0')then 
			coche1SeMueve2 <= '0';
		elsif(clk'event and clk = '1' ) then
			coche1SeMueve2 <=  coche1SeMueve;
		end if;	
	end process	biestableDcoche1SeMueveRetrasa1ciclo;


	biestableDcoche2SeMueveRetrasa1ciclo: process(reset,clk,coche2SeMueve)
	begin
		if(reset = '0')then 
			coche2SeMueve2 <= '0';
		elsif(clk'event and clk = '1' ) then
			coche2SeMueve2 <=  coche2SeMueve;
		end if;	
	end process	biestableDcoche2SeMueveRetrasa1ciclo;
	
	
	biestableDWEcoche1: process(reset,clk,coche1SeMueve2)   --con estos biestablesD conseguimos escribir sólo una vez en memoria por cada movimiento de coche
	begin
		if(reset = '0')then 
			WEcoche1 <= '0';
		elsif(clk'event and clk = '1' ) then
			WEcoche1 <=  coche1SeMueve2;
		end if;	
	end process	biestableDWEcoche1;


	biestableDWEcoche2: process(reset,clk,coche2SeMueve2)
	begin
		if(reset = '0')then 
			WEcoche2 <= '0';
		elsif(clk'event and clk = '1' ) then
			WEcoche2 <=  coche2SeMueve2;
		end if;	
	end process	biestableDWEcoche2;
	

	

end Behavioral; 
