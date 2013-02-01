-- Hecho para ser visto con tab size = 3


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity pong is
	port (
    ps2Clk: IN std_logic;
    ps2Data: IN std_logic;
    clk: IN std_logic;
	 reset: IN std_logic;    --reset activo a baja!
	 segs: OUT std_logic_vector (6 downto 0);
	 altavoz: OUT std_logic;
	 hSync: OUT std_logic;
	 Vsync: OUT std_logic;
	 R: OUT std_logic_vector (2 downto 0); -- alconversor D/A
	 G: OUT std_logic_vector (2 downto 0); -- alconversor D/A
	 B: OUT std_logic_vector (2 downto 0);  -- alconversor D/A
	 outTeclaQ: OUT std_logic
	);
end pong;

 
architecture Behavioral of pong is

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
	
	type fsmEstados is (pulsadas, despulsadas);
	signal estado: fsmEstados;
	
	--señales PS2
	signal newData, newDataAck: std_logic;
	signal scancode: std_logic_vector (7 downto 0);

	--señales VGA
	signal senialHSync, senialVSync: std_logic;
	signal finPixelCont: std_logic;
	signal cuentaPixelCont: std_logic_vector (10 downto 0);
	signal cuentaLineCont: std_logic_vector (9 downto 0);
	signal comp1, comp2, comp3, comp4, comp5, comp6: std_logic;	
	signal Rcampo: std_logic_vector (2 downto 0); 
	signal Gcampo: std_logic_vector (2 downto 0); 
	signal Bcampo: std_logic_vector (2 downto 0);
	signal Rpalas: std_logic_vector (2 downto 0); 
	signal Gpalas: std_logic_vector (2 downto 0); 
	signal Bpalas: std_logic_vector (2 downto 0);
	signal Rpelota: std_logic_vector (2 downto 0); 
	signal Gpelota: std_logic_vector (2 downto 0); 
	signal Bpelota: std_logic_vector (2 downto 0);
	
	--señales control
	signal pixelPalaIzq: std_logic_vector (6 downto 0); --102 pixeles (1100110)
	signal pixelPalaDer: std_logic_vector (6 downto 0); --102 pixeles
	signal pixelPelotaVer: std_logic_vector (6 downto 0); --102 pixeles
	signal pixelPelotaHor: std_logic_vector (7 downto 0); --153 pixeles (10011001)
	signal arribaPalaIzq: std_logic;		
	signal abajoPalaIzq: std_logic;		
	signal arribaPalaDer: std_logic;		
	signal abajoPalaDer: std_logic;
	signal horizontalPelota: std_logic;  -- 1 = derecha , 0 = izquieda
	signal verticalPelota: std_logic;	 -- 1 = abajo   , 0 = arriba
	signal moverPelota: std_logic;   
	signal cuenta1dec: STD_LOGIC_VECTOR(22 downto 0);  --contador1decima
	signal finCuenta1Dec: STD_LOGIC;
	
	--señales teclas
	signal teclaQ: std_logic;
	signal clTeclaQ: std_logic;
	signal ldTeclaQ: std_logic;
	signal teclaA: std_logic;
	signal clTeclaA: std_logic;
	signal ldTeclaA: std_logic;
	signal teclaP: std_logic;
	signal clTeclaP: std_logic;
	signal ldTeclaP: std_logic;
	signal teclaL: std_logic;
	signal clTeclaL: std_logic;
	signal ldTeclaL: std_logic;
	signal teclaSPC: std_logic;
	signal clTeclaSPC: std_logic;
	signal ldTeclaSPC: std_logic;
	
	--señales sonido
	signal ldScancode: std_logic;
	signal buzz,onda,silencio: std_logic;
	signal cuentaOscilador: std_logic_vector(17 downto 0);
	signal clOscilador: std_logic;

	--señales depuracion
	signal st : std_logic_vector (2 downto 0); 

begin


	interfazPS2: ps2KeyboardInterface port map (
														rst => reset,
														clk => clk,
														ps2Clk => ps2Clk,
														ps2Data => ps2Data,
														data => scancode, 
														newData => newData,
														newDataAck => newDataAck
													);

	hSync <= senialHSync; 
	vSync <= senialVSync;

	pantalla: process(clk, reset,cuentaPixelCont,cuentaLineCont,Rcampo,Rpelota,
						Rpalas,Gcampo,Gpelota,Gpalas,Bcampo,Bpelota,Bpalas)
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
			R(2) <= ( (not (comp1 or comp4))  and  (Rcampo(2) or Rpalas(2) or Rpelota(2))  );
			R(1) <= ( (not (comp1 or comp4))  and  (Rcampo(1) or Rpalas(1) or Rpelota(1))  );
			R(0) <= ( (not (comp1 or comp4))  and  (Rcampo(0) or Rpalas(0) or Rpelota(0))  );
			G(2) <= ( (not (comp1 or comp4))  and  (Gcampo(2) or Gpalas(2) or Gpelota(2))  );
			G(1) <= ( (not (comp1 or comp4))  and  (Gcampo(1) or Gpalas(1) or Gpelota(1))  );
			G(0) <= ( (not (comp1 or comp4))  and  (Gcampo(0) or Gpalas(0) or Gpelota(0))  );
			B(2) <= ( (not (comp1 or comp4))  and  (Bcampo(2) or Bpalas(2) or Bpelota(2))  );
			B(1) <= ( (not (comp1 or comp4))  and  (Bcampo(1) or Bpalas(1) or Bpelota(1))  );
			B(0) <= ( (not (comp1 or comp4))  and  (Bcampo(0) or Bpalas(0) or Bpelota(0))  );
		end if;
		
--		--para pintar un damero y probar la generación de hSync y vSync:
--		R(2) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		R(1) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		R(0) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		G(2) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		G(1) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		G(0) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		B(2) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		B(1) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );
--		B(0) <= ( (not (comp1 or comp4))  and  (cuentaPixelCont(6) xor cuentaLineCont(5))  );

	end process;
	

	--##########################  PINTAR JUEGO  ###############################--
		
			-- vertical: 479 limite de pixeles visibles
			-- 120 pixeles -> 479            x= (479*1)/120 = 3.99 = aprox 4
			-- 1   pixeles -> x
			
			-- horizontal: 1257 limite de pixeles visibles
			-- 153 pixeles -> 1257           x= (1257*1)/153 = 8.21 = aprox 8
			-- 1   pixeles -> x

	pintarCampo: process(cuentaLineCont,cuentaPixelCont)
	begin			
		-- inicializacion
		Rcampo <= "000";
		Gcampo <= "000";
		Bcampo <= "000";
		
		--linea continua superior
		if (cuentaLineCont(9 downto 2) = 8) then  
			Rcampo <= "111";
			Gcampo <= "111";
			Bcampo <= "111";
		end if;
		
		--red
		if (cuentaPixelCont(10 downto 3) = 76) then 											--mitad del campo,pintar la red
			if ( (cuentaLineCont(9 downto 2) > 8 and cuentaLineCont(9 downto 2) <= 16) or
				  (cuentaLineCont(9 downto 2) > 23 and cuentaLineCont(9 downto 2) <= 31) or
				  (cuentaLineCont(9 downto 2) > 39 and cuentaLineCont(9 downto 2) <= 47) or
				  (cuentaLineCont(9 downto 2) > 55 and cuentaLineCont(9 downto 2) <= 63) or
				  (cuentaLineCont(9 downto 2) > 71 and cuentaLineCont(9 downto 2) <= 79) or
				  (cuentaLineCont(9 downto 2) > 87 and cuentaLineCont(9 downto 2) <= 95) or
				  (cuentaLineCont(9 downto 2) > 103 and cuentaLineCont(9 downto 2) <= 111)
				 ) then 
					Rcampo <= "111";
					Gcampo <= "111";
					Bcampo <= "111";
			end if;
		end if;		
			
		--linea continua inferior
		if (cuentaLineCont(9 downto 2) = 112) then 
			Rcampo <= "111";
			Gcampo <= "111";
			Bcampo <= "111";
		end if;
	end process pintarCampo;
	

	pintarPalas: process(cuentaLineCont,cuentaPixelCont,pixelPalaIzq,pixelPalaDer)
	begin
		-- inicializacion
		Rpalas <= "000";
		Gpalas <= "000";
		Bpalas <= "000";
		
		--pala izquierda
		if (cuentaLineCont(9 downto 2) > 8 and cuentaLineCont(9 downto 2) < 112) then  --dentro del campo:
			if (cuentaPixelCont(10 downto 3) = 8) then --linea de la pala	
				if (cuentaLineCont(9 downto 2) >= pixelPalaIzq and 
					cuentaLineCont(9 downto 2) <= pixelPalaIzq+16) then--la pala en si (longitud pala= 16)
					Rpalas <= "111";
					Gpalas <= "111";
					Bpalas <= "111";
				end if;
			end if;
		end if;
		
		--pala derecha
		if (cuentaLineCont(9 downto 2) > 8 and cuentaLineCont(9 downto 2) < 112) then  --dentro del campo:
			if (cuentaPixelCont(10 downto 3) = 145) then --linea de la pala	
				if (cuentaLineCont(9 downto 2) >= pixelPalaDer and 
					cuentaLineCont(9 downto 2) <= pixelPalaDer+16) then --la pala en si (longitud pala= 16)
					Rpalas <= "111";
					Gpalas <= "111";
					Bpalas <= "111";
				end if;
			end if;
		end if;
	end process pintarPalas;
	
	
	pintarPelota: process(cuentaLineCont,cuentaPixelCont,pixelPelotaVer,pixelPelotaHor)
	begin
		-- inicializacion
		Rpelota <= "000";
		Gpelota <= "000";
		Bpelota <= "000";

		--pelota
		if (cuentaLineCont(9 downto 2) > 8 and 
			cuentaLineCont(9 downto 2) < 112) then  --dentro del campo:
			if (cuentaLineCont(9 downto 2) = pixelPelotaVer and 
				cuentaPixelCont(10 downto 3) = pixelPelotaHor) then --la pelota en si
				Rpelota <= "000";--Rpelota <= "111";
				Gpelota <= "111";
				Bpelota <= "000";--Bpelota <= "111";
			end if;
		end if;
	end process pintarPelota;
	
	
	--#########################################################################--
	
	
	contadorMediaDecima: process(reset,clk,cuenta1dec)  --contador mod 5.000.000 (de 0 a 4.999.999)
	begin
		if (cuenta1dec = "10011000100101100111111") then
			finCuenta1Dec <= '1';
		else 
			finCuenta1Dec <= '0';
		end if;
		
		if(reset = '0')then
			cuenta1dec <= (others => '0');
			finCuenta1Dec <= '0';
		elsif(clk'event and clk = '1') then
			if (cuenta1dec /= "10011000100101100111111") then  
				cuenta1dec <= cuenta1dec + 1; 
			elsif (cuenta1dec = "10011000100101100111111") then
				cuenta1dec  <= (others => '0');
			end if;		
		end if;
	end process contadorMediaDecima;
	
	
	palas: process(clk,reset,arribaPalaIzq,abajoPalaIzq,pixelPalaIzq,arribaPalaDer,
					abajoPalaDer,pixelPalaDer)
	begin
	
		--pala izq: cont mod 102 y pala der: cont mod 102 
		if(reset = '0')then
			pixelPalaIzq <= "0110100";  --en medio: (120/2)-8 = 52
			pixelPalaDer <= "0110100";  --en medio: (120/2)-8 = 52
		elsif(clk'event and clk = '1') then
			if (finCuenta1Dec = '1') then
				--pala izq
				if (arribaPalaIzq = '1' and (pixelPalaIzq > 9) and (pixelPalaIzq /= 9)) then  --si orden=arriba and (todavia puede subir)
					pixelPalaIzq  <= pixelPalaIzq - '1'; 
				end if;
				if (abajoPalaIzq = '1' and (pixelPalaIzq < (111 -16)) and (pixelPalaIzq /= 111-16)) then  --si orden=abajo and (todavia puede bajar)
					pixelPalaIzq  <= pixelPalaIzq + '1'; 
				end if;
				--pala der
				if (arribaPalaDer = '1' and (pixelPalaDer > 9)  and (pixelPalaDer /= 9)) then  --si orden=arriba and (todavia puede subir)
					pixelPalaDer  <= pixelPalaDer - '1'; 
				end if;
				if (abajoPalaDer = '1' and (pixelPalaDer < (111 -16))  and (pixelPalaDer /= 111-16)) then  --si orden=abajo and (todavia puede bajar)
					pixelPalaDer  <= pixelPalaDer + '1'; 
				end if;
			end if;
			if (teclaSPC = '1') then
				pixelPalaIzq <= "0110100";  --en medio: (120/2)-8 = 52
				pixelPalaDer <= "0110100";  --en medio: (120/2)-8 = 52
			end if;
		end if;
		
	
	end process palas;
	
	
	pelota: process(clk,reset,verticalPelota,horizontalPelota,pixelPelotaHor,pixelPelotaVer)
	begin
		
		--vertical: cont mod 102 y horizontal: cont mod 153 
		if (reset = '0')then
			pixelPelotaVer <= "0111001";  --en medio: (120/2) = aprox 57
			pixelPelotaHor <= "01000110";  --en medio: (153/2) = aprox 76. la ponemos a la izq, en 70
		elsif (clk'event and clk = '1') then
			if(finCuenta1Dec = '1' and moverPelota = '1') then
				--contador vertical
				if  (verticalPelota = '0') then 
					pixelPelotaVer <= pixelPelotaVer - '1';  --va hacia arriba
				else 
					pixelPelotaVer <= pixelPelotaVer + '1';  --va hacia abajo
				end if;
				--contador horizontal
				if  (horizontalPelota = '0') then 
					pixelPelotaHor <= pixelPelotaHor - '1'; --va hacia izquierda
				else 
					pixelPelotaHor <= pixelPelotaHor + '1'; --va hacia derecha
				end if;
			end if;
			if (teclaSPC = '1') then
				pixelPelotaVer <= "0111001";  --en medio: (120/2) = aprox 57
				pixelPelotaHor <= "01000110";  --en medio: (153/2) = aprox 76. la ponemos a la izq, en 70
			end if;
		end if;

		--controlador de movimiento
		if (reset = '0')then
			moverPelota <= '1';
			horizontalPelota <= '1';
			verticalPelota <= '1';
			buzz <= '0';
		elsif (clk'event and clk = '1') then
			if (finCuenta1Dec='1') then   --chequeo de colision
				buzz <= '0';
				--pala izquierda
				if (pixelPelotaHor = 10) then --esta enfrente de la pala
					if (pixelPelotaVer >= pixelPalaIzq and pixelPelotaVer <= pixelPalaIzq+16 ) then --choca con la pala
						horizontalPelota <= '1'; 
						buzz <= '1';
					end if;
				end if;
				--pala derecha
				if (pixelPelotaHor = 143) then --esta enfrente de la pala
					if (pixelPelotaVer >= pixelPalaDer and pixelPelotaVer <= pixelPalaDer+16 ) then --choca con la pala
						horizontalPelota <= '0';
						buzz <= '1';
					end if; 
				end if;
				--campo arriba
				if (pixelPelotaVer = 10) then --esta enfrente de la barrera =10
					verticalPelota <= '1'; 
					buzz <= '1';
				end if;
				--campo abajo
				if (pixelPelotaVer = 110) then --esta enfrente de la barrera =110
					verticalPelota <= '0';
					buzz <= '1';
				end if;
				--fuera
				if (pixelPelotaHor = 1 or pixelPelotaHor = 155) then
					moverPelota <= '0';
					buzz <= '1';
				end if;	
				if (teclaSPC = '1') then
					moverPelota <= '1';
					horizontalPelota <= '1';
					verticalPelota <= '1';
					buzz <= '0';
				end if;
			end if;
		end if;				
	
	end process pelota;
	

	

	--maquina de estados con registros de flags-------------------------------------------------

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


	generadorSalidaMealy: process (newDataAck, scancode, estado, newData)
	begin
		newDataAck <= '0';
		clTeclaQ <= '0';		
		clTeclaA <= '0';		
		clTeclaP <= '0';		
		clTeclaL <= '0';		
		clTeclaSPC <= '0';	
		ldTeclaQ <= '0';		
		ldTeclaA <= '0';		
		ldTeclaP <= '0';		
		ldTeclaL <= '0';		
		ldTeclaSPC <= '0';	
		case estado is
			when pulsadas =>
				if (newData = '1') then  --11110000: F0
					case scancode is   	--registros de flags:
						when "00010101" => ldTeclaQ <= '1';   clTeclaQ <= '0'; 	  --Q=15 
						when "00011100" => ldTeclaA <= '1';	  clTeclaA <= '0';	  --A=1C 
						when "01001101" => ldTeclaP <= '1';	  clTeclaP <= '0';	  --P=4D 
						when "01001011" => ldTeclaL <= '1';	  clTeclaL <= '0';	  --L=4B 
						when "00101001" => ldTeclaSPC <= '1'; clTeclaSPC <= '0';  --SPC=29 
						when others => null; 
					end case;
					newDataAck <= '1';
				end if;

			when despulsadas =>
				if (newData = '1') then
					case scancode is   	--registros de flags:
						when "00010101" => ldTeclaQ <= '0';   clTeclaQ <= '1'; 	  --Q=15 
						when "00011100" => ldTeclaA <= '0';	  clTeclaA <= '1';	  --A=1C 
						when "01001101" => ldTeclaP <= '0';	  clTeclaP <= '1';	  --P=4D 
						when "01001011" => ldTeclaL <= '0';	  clTeclaL <= '1';	  --L=4B 
						when "00101001" => ldTeclaSPC <= '0'; clTeclaSPC <= '1';  --SPC=29 
						when others => null; 
					end case;
					newDataAck <= '1'; 
				end if;

			when others => null;	
		end case;
	end process;
	
	
	generadorSalidaMoore: process (estado) --genera st
	begin
		case estado is
			when pulsadas =>
			  st <= "000";  
			when despulsadas =>
			  st <= "001"; 
		end case;
	end process;
	
	
	conversor7seg: process(st)
	begin
		case st is
								     -- gfedcba
			when "000" => segs <= "0111111";   -- cerrado: Locked
			when "001" => segs <= "0000110"; 
			when OTHERS => segs <= "1111001";  -- error
			end case;
	end process;
	
	
	-----------------------------------------------------------------------------
	
	outteclaQ <= teclaQ;
	arribaPalaIzq <= teclaQ and not teclaA;
	abajoPalaIzq <= teclaA;
	arribaPalaDer <= teclaP and not teclaL;
	abajoPalaDer <= teclaL;
	
	
	biestableDTeclaQ: process(reset,clk,ldTeclaQ,clTeclaQ)
	begin
		if(reset = '0')then 
				teclaQ <= '0';
		elsif(clk'event and clk = '1' ) then
				if (clTeclaQ = '1') then
					teclaQ <=  '0';
				elsif (ldTeclaQ = '1') then	
					teclaQ <= '1';
				end if;
		end if;	
	end process	biestableDTeclaQ;
	
	
	biestableDTeclaA: process(reset,clk,ldTeclaA,clTeclaA)
	begin
		if(reset = '0')then 
				teclaA <= '0';
		elsif(clk'event and clk = '1' ) then
				if (clTeclaA = '1') then
					teclaA <=  '0';
				elsif (ldTeclaA = '1') then	
					teclaA <= '1';
				end if;
		end if;	
	end process	biestableDTeclaA;
	
		
	biestableDTeclaP: process(reset,clk,ldTeclaP,clTeclaP)
	begin
		if(reset = '0')then 
				teclaP <= '0';
		elsif(clk'event and clk = '1' ) then
				if (clTeclaP = '1') then
					teclaP <=  '0';
				elsif (ldTeclaP = '1') then	
					teclaP <= '1';
				end if;
		end if;	
	end process	biestableDTeclaP;
	
	
	biestableDTeclaL: process(reset,clk,ldTeclaL,clTeclaL)
	begin
		if(reset = '0')then 
				teclaL <= '0';
		elsif(clk'event and clk = '1' ) then
				if (clTeclaL = '1') then
					teclaL <=  '0';
				elsif (ldTeclaL = '1') then	
					teclaL <= '1';
				end if;
		end if;	
	end process	biestableDTeclaL;
	
	
	biestableDTeclaSPC: process(reset,clk,ldTeclaSPC,clTeclaSPC)
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
	end process	biestableDTeclaSPC;
	
	
	
	----- GENERACIÓN DE SONIDO --------------------------------------------------
	
	oscilador18bits: process(clk,reset,clOscilador) 
	begin
		if(reset = '0')then
			cuentaOscilador <= (others => '0');
			onda <= '0';      --reset biestable T
			
		elsif(clk'event and clk = '1') then
				if (clOscilador = '1') then   
					cuentaOscilador  <= (others => '0');
					onda <= not onda;
				else 
					cuentaOscilador  <= cuentaOscilador + 1;  
				end if;
		end if;	
	end process oscilador18bits;		

	
	generadorSonido: process(clk,reset,cuentaOscilador,buzz,onda,silencio)
	begin
		
		if (cuentaOscilador = "010111010101001101") then -- comparador del oscilador
			clOscilador <= '1';
		else 
			clOscilador <= '0';
		end if;
		
		if (buzz = '0') then  -- puerta NOR para generar silencio
			silencio <= '1';
		else 
			silencio <= '0';
		end if;
		
		altavoz <= onda or silencio;  -- puerta OR para generar onda del sonido
				
	end process generadorSonido;
	
	----- FIN GENERACIÓN DE SONIDO ----------------------------------------------


end Behavioral; 
