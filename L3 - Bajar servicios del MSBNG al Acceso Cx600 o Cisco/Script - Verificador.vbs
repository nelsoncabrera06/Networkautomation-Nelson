# $language = "VBScript"
# $interface = "1.0"

' este script entra a equipos CISCO MSBNG, y tambien a los Huawei CX600, entra a la subinterface
' la analiza
' guarda los datos en variables 
' imprime todas las variables necesarias para armar el servicio

' Agregar en casos futuros: 
'	_ redes que esta compartiendo el neighbor en HUAWEI
' 	  ver los ping en el caso de VRF HUAWEI

Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8
Const BUTTON_YESNO = 4		' Yes and No buttons
Const IDYES = 6				' Yes button clicked
Const IDNO = 7				' No button clicked
Dim Estatica(50)
Dim ipPING(50)
Dim MASCARA_estatica(50)
Dim Cant_estaticas
Dim EQUIPO
Dim MARCA

NombreArchivo_Entrada = "Verificar.txt"
NombreArchivo_Salida = "OUTPUT - Verificacion.txt"
NombreArchivo_TABLADATOS = "OUTPUT - TabladeDatos.txt"
SEGUIR = 0
EQUIPO = "NO TIENE"
MARCA = "sin datos"


Sub Main

  crt.Screen.Synchronous = True
  Dim waitStrs, comandostring
  Dim row, screenrow, readline, items
	Dim pass, USUARIO

  Dim fso, file
  Set fso = CreateObject("Scripting.FileSystemObject")

  Dim fsodatos, filedatos, str
  Set fsodatos = CreateObject("Scripting.FileSystemObject")

  Set filedatos = fsodatos.OpenTextFile(NombreArchivo_Entrada, ForReading, False)
  Set file = fso.OpenTextFile(NombreArchivo_Salida, ForWriting, True)
  Set fileoutTabladeDatos = fso.OpenTextFile(NombreArchivo_TABLADATOS, ForWriting, True)
  
  row = 1 
  ESTADO = 0
  RESULTADO = 0
  Salir = 0
  waitStrs = Array( Chr(10), "...")
  index = 0
  
    crt.Screen.Synchronous = True
	crt.Screen.Send Chr(13)
	
	SEGUIR = funcion_AbrirINPUT(file, filedatos, index, CVLAN, SVLAN, ESTADO)
	if SEGUIR = 1 then
		MsgBox("Salida del script") 
		exit sub
	end if
	
	crt.Screen.Send Chr(13)
	ESTADO = crt.screen.WaitForStrings("Username:", ">", "#", "$", "...")
	Select Case ESTADO
		Case 2 'Ya estoy dentro del equipo caso HUAWEI
			ESTADO = 2 'Huawei
			crt.Screen.Send Chr(13)
			crt.screen.WaitForString ">"
			columnaActual = crt.screen.CurrentColumn
			screenrow = crt.screen.CurrentRow
			EQUIPO = crt.Screen.Get(screenrow, 2, screenrow, columnaActual-2)
			MARCA = "HUAWEI"
			'MsgBox EQUIPO
		Case 3 'estoy dentro de un CISCO
			ESTADO = 3 'Cisco
			crt.Screen.Send Chr(13)
			crt.screen.WaitForString "#"
			columnaActual = crt.screen.CurrentColumn
			screenrow = crt.screen.CurrentRow
			EQUIPO = crt.Screen.Get(screenrow, 1, screenrow, columnaActual-2)
			lngPos = Instr(EQUIPO, ":")
			EQUIPO = Mid(EQUIPO, lngPos+1, Len(EQUIPO))
			EQUIPO = trim(EQUIPO)
			MARCA = "CISCO"
			'MsgBox EQUIPO
		Case 4 'no estoy en ningun equipo
			ESTADO = 0
			USUARIO = crt.Dialog.Prompt("Ingrese su usuario")
			pass = crt.Dialog.Prompt("Ingrese su password:", "Logon Script", "", True)
	end select
	
    Do While filedatos.AtEndOfStream <> True
	      
		  do while ESTADO <> 7
		  Select Case ESTADO
		    Case 0 'inicio
				'EQUIPO = filedatos.Read(8) ' leo el equipo CASO CMUNECAS
				EQUIPO = crt.Dialog.Prompt("Ingrese el nombre del equipo")
				verific = crt.Dialog.MessageBox("Desea ingresar a " &EQUIPO , cap, BUTTON_YESNO)
				'MsgBox "Equipo " & str
				if verific = IDYES then
					crt.Screen.Send "ttelnet " & EQUIPO & Chr(13)
					ESTADO = crt.screen.WaitForStrings("Username:", ">", "#")', "$", "...")
				else 
					crt.Dialog.MessageBox("VUELVA A INTENTAR")
					ESTADO = 7
				end if
				'MsgBox "ESTADO " & ESTADO
			Case 1 'ingreso mi usuario
				crt.Screen.Send USUARIO & chr(13)
				crt.Screen.WaitForString "Password:"
				crt.Screen.Send pass & chr(13)
				ESTADO = crt.screen.WaitForStrings("Username:", ">", "#", "$")
			Case 2 'HUAWEI
				MARCA = "HUAWEI"
				RESULTADO = funcion_HUAWEI(file, filedatos, index, MARCA, EQUIPO, ESTADO, fileoutTabladeDatos)
				ESTADO = RESULTADO				
			Case 3 'CISCO
				MARCA = "CISCO"
			    RESULTADO = funcion_CISCO(file, filedatos, index, MARCA, EQUIPO, ESTADO, fileoutTabladeDatos)
				ESTADO = RESULTADO
			'Case 4 'no ingreso al equipo
			'	crt.Screen.Send chr(13)
			'	ESTADO = 0
			'Case 5 'escribe la IP del equipo
			'	screenrow = crt.screen.CurrentRow
		    '   readline = crt.Screen.Get(screenrow, 8, screenrow, crt.screen.CurrentColumn-4)
				'file.Write readline & vbCrLf
			'	ESTADO = crt.screen.WaitForStrings("Username:", ">", "#", "$", "...")
		   End Select
		Loop   	   
   Loop


  crt.screen.synchronous = false

	MsgBox("       Fin del script       " & vbCrLf & "Autor: Nelson Cabrera") 
	Set g_shell = CreateObject("WScript.Shell")
	g_shell.Run chr(34) & NombreArchivo_Salida & chr(34)
	
	    Set g_shell = CreateObject("WScript.Shell")
	g_shell.Run chr(34) & NombreArchivo_TABLADATOS & chr(34)
	
End Sub


Function funcion_AbrirINPUT(file, filedatos, index, CVLAN, SVLAN, ESTADO)
	MsgBox "FORMATO DE EJEMPLO: Te0/2/0/22.22010022"
	
	Set g_shell = CreateObject("WScript.Shell")
	g_shell.Run chr(34) & NombreArchivo_Entrada & chr(34) 'abro el Input.txt cargo los datos, guardo y cierro
	
	crt.Screen.Send "" & chr(13)
	verific = crt.Dialog.MessageBox("Continuar?", cap, BUTTON_YESNO)
 
	if verific = IDYES then 
		funcion_AbrirINPUT = 0
	else 
		funcion_AbrirINPUT = 1 'considero 1 para salir
	end if
	
End Function

Function funcion_HUAWEI(file, filedatos, index, MARCA, EQUIPO, ESTADO, fileoutTabladeDatos)
	Dim TABLA(30,10) 'sin tamaño
	Dim SVLAN(30) 'sin tamaño
	Dim Estatica(50) 
	Dim pingEstatica(50)
	Dim SalidaINTERNET(50)
	Dim MASCARA_estatica(50) 
	Dim ipPING(50)
	Dim Resultado_pingEstatica(50)
	Dim Redes_aprendidas(50)
	Cant_estaticas = 0
	Cant_redes = 0
	aux = 0
	indice = 0
	indice_SVLAN = 0
	indice_max = 0
	i_redes = 0
	Estatica(0) = "NO TIENE"
	SalidaINTERNET(0) = "NO TIENE"
	PUERTO = "NO TIENE"
	Subint = "NO TIENE"
	SUBINTERFACE = "NO TIENE"
	Estado_Subint = "NO TIENE"
	DESCRIPCION = "NO TIENE"
	BANDWIDTH = "NO TIENE"
	policy_input = "NO TIENE"
	policy_output = "NO TIENE"
	VRF = "NO TIENE"
	ip_WAN = "NO TIENE"
	mascara_WAN = "NO TIENE"
	NEXTHOP = "NO TIENE"
	CVLAN = "NO TIENE"
	RD = "NO TIENE"
	AS_actual = "NO TIENE"
	descripcion_BGP = "NO TIENE"
	BGP = "NO TIENE"
	neighbor_BGP = "NO TIENE"
	PEAKFLOW = "NO TIENE"
	PalabrasCLAVE = array("arg", "ARG", "GMT")
	Trafico_input = "NO TIENE"
	Trafico_output = "NO TIENE"
	Equipo_gestor = "<" & EQUIPO & ">"
	Cant_rutas_BGP = 0
			
    crt.Screen.Synchronous = True
	
	'str = filedatos.Readline 'aca lee el puerto o subinterface
	COMANDO = filedatos.Readline 'aca lee el puerto o subinterface
	PUERTO = str
	SUBINTERFACE = str
	'file.Write EQUIPO & " " & PUERTO & "	" & "Descripcion: disp int " & PUERTO & vbCrLf
	
	
	'lngPos = Instr(COMANDO, "begin") ' para el caso de bgp
	'if lngPos > 0 then
	'	IP = Mid(COMANDO, lngPos+6, Len(COMANDO))
	'	IP = trim(IP)
	'	'MsgBox "IP " & IP
	'	
	'	
	'	crt.Screen.Send COMANDO & chr(13) 'tira el comando
	'	'Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor)
	'	'crt.screen.WaitForString chr(13)
	'	do while Salir <> 2	' mientras no aparezca # hacer
	'		screenrow = crt.screen.CurrentRow 'fila actual
	'		readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
	'		readline = rtrim(readline)
	'		
	'		lngPos2 = Instr(COMANDO, IP) ' si encuentro la IP
	'		if lngPos2 > 0 then
	'			file.Write EQUIPO & "	" & readline & vbCrLf
	'		end if
	'		
	'		Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor)
	'		'Salir = crt.screen.WaitForStrings (chr(13), "#")
	'		Select Case Salir
	'			Case 2 'encontró # termino de mostrar la descripcion
	'				Salir = 2
	'				'MsgBox "aux = 2" 
	'		End Select
	'	Loop
	'	
	'	
	'	
	'end if
	
	
	crt.Screen.Send COMANDO & chr(13) 'tira el comando para mostrar la descripcion
	'Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor)
	'crt.screen.WaitForString chr(13)
	do while Salir <> 2	' mientras no aparezca # hacer
		screenrow = crt.screen.CurrentRow 'fila actual
		readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
		readline = rtrim(readline)
		file.Write EQUIPO & "	" & readline & vbCrLf
		Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor)
		'Salir = crt.screen.WaitForStrings (chr(13), "#")
		Select Case Salir
			Case 2 'encontró # termino de mostrar la descripcion
				Salir = 2
				'MsgBox "aux = 2" 
		End Select
	Loop
	'MsgBox "termine de mostrar la descripcion"
	
	ESTADO = 2 'Huawei
		
	'file.Write "--------------------------------------" & vbCrLf
	'file.Write "--------------------------------------" & vbCrLf
	'ESTADO = 0
	if filedatos.AtEndOfStream = True then ESTADO = 7
	funcion_HUAWEI = ESTADO
	
End Function

Function funcion_CISCO(file, filedatos, index, MARCA, EQUIPO, ESTADO, fileoutTabladeDatos)
	Dim TABLA(30,10) 'sin tamaño
	Dim SVLAN(30) 'sin tamaño
	
	'Dim Estatica(50) 
	'Dim ipPING(50)
	'Dim MASCARA_estatica(50) 
		
	Dim pingEstatica(50)
	Dim SalidaINTERNET(50)
	Dim Resultado_pingEstatica(50)
	Dim Redes_aprendidas(50)
	Cant_estaticas = 0
	Cant_redes = 0
	aux = 0
	indice = 0
	indice_SVLAN = 0
	indice_max = 0
	i_redes = 0
	
	Erase Estatica
	Erase ipPING
	Erase MASCARA_estatica ' clear the array
			
	Estatica(0) = "NO TIENE"
	SalidaINTERNET(0) = "NO TIENE"
	PUERTO = "NO TIENE"
	Subint = "NO TIENE"
	SUBINTERFACE = "NO TIENE"
	Estado_Subint = "NO TIENE"
	DESCRIPCION = "NO TIENE"
	BANDWIDTH = "NO TIENE"
	policy_input = "NO TIENE"
	policy_output = "NO TIENE"
	VRF = "NO TIENE"
	ip_WAN = "NO TIENE"
	mascara_WAN = "NO TIENE"
	NEXTHOP = "NO TIENE"
	CVLAN = "NO TIENE"
	RD = "NO TIENE"
	AS_actual = "NO TIENE"
	descripcion_BGP = "NO TIENE"
	BGP = "NO TIENE"
	neighbor_BGP = "NO TIENE"
	PEAKFLOW = "NO TIENE"
	PalabrasCLAVE = array("arg", "ARG", "GMT")
	Trafico_input = 0
	Trafico_output = 0
			
			
			'sh run desc | inc Gi0/0/0/3.12793649		 ' listo!! subint
			'sh run int Gi0/0/0/3.12793649				 ' listo!! subint
			'sh run vrf pami-vpn 		     			 ' listo!! VRF
			'sh run router bgp 7303 vrf pami-vpn neighbor 172.17.1.102  'listo!! BGP 'estaria bueno tmb ver la config completa del BGP
			'sh run router static vrf pami-vpn | inc 0/0/0/3.12793649 	'listo!! Estaticas
			'sh run router static vrf pami-vpn | inc 172.17.1.102		'listo!! Estaticas otra forma de ver masomenos lo mismo
			'sh run policy-map VPN-1M									'listo!!
			'sh run policy-map rt30-mc60-1M								'listo!!
			'ping vrf pami-vpn 10.160.194.38							'listo!! tirar ping			
		
            'file.Write "MARCA = " & MARCA & vbCrLf
			str = filedatos.Readline 'aca lee el puerto o subinterface
			PUERTO = str
			file.Write EQUIPO & " " & PUERTO & "	Descripcion: sh int " & PUERTO & vbCrLf
			crt.Screen.Send "sh int " & str & chr(13) 'tira el comando para mostrar la descripcion
			crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg
			Salir = crt.screen.WaitForStrings (chr(13), "#", "line protocol", "Description:")
			do while Salir <> 2						' mientras no aparezca # hacer
					screenrow = crt.screen.CurrentRow 'fila actual
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					file.Write EQUIPO & " " & PUERTO & "	" & readline & vbCrLf
					Salir = crt.screen.WaitForStrings (chr(13), "#", "line protocol", "Description:", "minute input rate ", "minute output rate ", "second input rate ", "second output rate ") 'esperar por los siguiente caracteres
				Select Case Salir
					Case 2 'encontró # termino de mostrar la descripcion
						Salir = 2
						'MsgBox "aux = 2" 
					Case 3 'encontró line protocol
						columnaActual = crt.screen.CurrentColumn - 15
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString chr(13)
						Estado_Subint = crt.Screen.Get(screenrow, 1, screenrow, 200)
						lngPos = Instr(Estado_Subint, " ")
						'SUBINTERFACE = Mid(Estado_Subint, 1, lngPos-1)
						SUBINTERFACE = PUERTO
						Estado_Subint = Mid(Estado_Subint, lngPos+4, Len(Estado_Subint))
						Estado_Subint = trim(Estado_Subint)
						'SUBINTERFACE = crt.Screen.Get(screenrow, 1, screenrow, columnaActual) 'toma la subinterface 
						'MsgBox "Estado_Subint " & Estado_Subint
						'MsgBox "SUBINTERFACE " & SUBINTERFACE
					Case 4 'encontró Description:
						columnaActual = crt.screen.CurrentColumn
						screenrow = crt.screen.CurrentRow	
						crt.screen.WaitForString chr(13)
						DESCRIPCION = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
						DESCRIPCION = trim(DESCRIPCION)
						'MsgBox "DESCRIPCION " & DESCRIPCION
						'MsgBox "SUBINTERFACE " & SUBINTERFACE
					Case 5 or 7' minute input rate
						'30 second input rate 167000 bits/sec, 63 packets/sec
						columnaActual = crt.screen.CurrentColumn
						screenrow = crt.screen.CurrentRow	
						crt.screen.WaitForString " "
						Trafico_input = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
						Trafico_input = trim(Trafico_input)
						'MsgBox "Trafico_input " & Trafico_input & " bits/sec = " & (Trafico_input/1000000) & " Mbps"
					Case 6 or 8' minute output rate
						columnaActual = crt.screen.CurrentColumn
						screenrow = crt.screen.CurrentRow	
						crt.screen.WaitForString " "
						Trafico_output = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
						Trafico_output = trim(Trafico_output)
						'MsgBox "Trafico_output " & Trafico_output & " bits/sec = " & (Trafico_output/1000000) & " Mbps"
						'30 second output rate 258000 bits/sec, 69 packets/sec
				End Select
			Loop
			'MsgBox "termine de mostrar la descripcion"
			
			file.Write EQUIPO & " " & SUBINTERFACE & "	Configuracion: sh run int " & PUERTO & vbCrLf
			crt.Screen.Send "sh run int " & PUERTO & chr(13) 'muestro la configuracion del puerto	
			crt.screen.WaitForStrings PalabrasCLAVE 'espera la palabra arg			
			Salir = crt.screen.WaitForStrings (chr(13), "#")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings(chr(13), "#", "bandwidth ", "policy input ", "policy output ", "vrf ", "ipv4 address ", "dot1q vlan ", "interface ", "description ", "encapsulation dot1q", "flow ipv4 monitor")
				Select Case Salir
				Case 3 ' bandwidth
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					BANDWIDTH = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
					BANDWIDTH = trim(BANDWIDTH)
					'MsgBox BANDWIDTH
				Case 4 ' policy input
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					policy_input = crt.Screen.Get(screenrow, columnaActual, screenrow, 50)
					policy_input = trim(policy_input)
					'MsgBox policy_input	
				Case 5 ' policy output
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					policy_output = crt.Screen.Get(screenrow, columnaActual, screenrow, 50)
					policy_output = trim(policy_output)
					'MsgBox policy_output
				Case 6 ' vrf
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					VRF = crt.Screen.Get(screenrow, columnaActual, screenrow, 100)
					VRF = trim(VRF)
					'MsgBox VRF
				Case 7 ' ipv4 address
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString " 255."
					columnaFinal = crt.screen.CurrentColumn - 5
					ip_WAN = crt.Screen.Get(screenrow, columnaActual, screenrow, columnaFinal)
					crt.screen.WaitForString chr(13)
					columnaActual = columnaFinal
					mascara_WAN = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
					mascara_WAN = trim(mascara_WAN)
					'MsgBox ip_WAN & " mascara: " & mascara_WAN
				Case 8 ' dot1q vlan -> caso C2BELGRANO y esos
					'  dot1q vlan 2009 27
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					CVLAN = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
					CVLAN = trim(CVLAN)
					lngPos = Instr(CVLAN, " ")
					if lngPos > 0 then
						CVLAN = Mid(CVLAN, lngPos, Len(CVLAN))
						CVLAN = trim(CVLAN)
					end if
					'MsgBox CVLAN
				Case 9 ' Interface
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString "."
					columnaFinal = crt.screen.CurrentColumn - 2
					PUERTO = crt.Screen.Get(screenrow, columnaActual, screenrow, columnaFinal)
					crt.screen.WaitForString chr(13)
					columnaActual = columnaFinal + 2
					Subint = crt.Screen.Get(screenrow, columnaActual, screenrow, 50)
				Case 10 ' Description
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					columnaFinal = crt.screen.CurrentColumn
					DESCRIPCION = crt.Screen.Get(screenrow, columnaActual, screenrow, 300)
					DESCRIPCION = trim(DESCRIPCION)
					'MsgBox DESCRIPCION
				Case 11 ' encapsulation dot1q -> para caso MSBNG ejemplo RSC1MB
					' encapsulation dot1q 294 second-dot1q 2
					lngPos = 0
					columnaActual = crt.screen.CurrentColumn
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					CVLAN = crt.Screen.Get(screenrow, columnaActual, screenrow, 200)
					CVLAN = trim(CVLAN)
					lngPos = Instr(CVLAN, "second-dot1q")
					if lngPos > 0 then
						CVLAN = Mid(CVLAN, lngPos+13, Len(CVLAN))
						CVLAN = trim(CVLAN)
					end if
					'MsgBox CVLAN
				Case 12 'flow ipv4 monitor FMMAP sampler FNF_SAMPLER_MAP ingress
					PEAKFLOW = "Si tiene"
				End Select
			loop
		
		
			'MsgBox "termine de leer la configuracion de la subinterface" 
			' ahora tengo que ver la configuracion de la VRF
			if VRF <> "NO TIENE" then
			file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual VRF: sh run vrf " & VRF & vbCrLf
			crt.Screen.Send "sh run vrf " & VRF & chr(13) 'muestro la configuracion de la VRF
			crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg			
			Salir = crt.screen.WaitForStrings (chr(13), "#")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings(chr(13), "#", "7303:")
				Select Case Salir
				Case 3 ' 7303 encontré el RD
					columnaActual = crt.screen.CurrentColumn - 5
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					RD = crt.Screen.Get(screenrow, columnaActual, screenrow, 15)
					'MsgBox RD			
				End Select
			loop
			end if
			'MsgBox "termine de leer la configuracion de la VRF"
			
			' ahora tengo que ver la configuracion del BGP
			'IP de WAN+1
			'Calculo de Siguiente IP 
			'MsgBox "Esta entrando en el else"
			
			if ip_WAN <> "NO TIENE" then
				NEXTHOP = SiguienteIP(ip_WAN)
				'MsgBox "NEXTHOP " & NEXTHOP
			end if
			
			if ip_WAN <> "NO TIENE" then
			if VRF <> "NO TIENE" then
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual BGP: sh run router bgp 7303 vrf " & VRF & " neighbor " & NEXTHOP & vbCrLf
				crt.Screen.Send "sh run router bgp 7303 vrf " & VRF & " neighbor " & NEXTHOP & chr(13) 'muestro la configuracion del BGP
				crt.screen.WaitForStrings PalabrasCLAVE   'espera la palabra arg
				crt.Screen.Synchronous = True				
				Salir = crt.screen.WaitForStrings (chr(13), "#", "remote-as ", "description ", "% No such configuration item(s)")
				
				do while Salir <> 2
					screenrow = crt.screen.CurrentRow
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					StringsArray = array(chr(13), "#", "remote-as ", "description ", "% No such configuration item(s)")
					Salir = encontrarString(readline, StringsArray)
					
				'	MsgBox readline & " " & Salir
					
				'	screenrow = crt.screen.CurrentRow
				'	readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				'	readline = rtrim(readline)
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				'	Salir = crt.screen.WaitForStrings(chr(13), "#", "remote-as ", "description ", "% No such configuration item(s)")
					Select Case Salir
					Case 3 ' remote-as 
						columnaActual = crt.screen.CurrentColumn 
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString chr(13)
						AS_actual = crt.Screen.Get(screenrow, columnaActual, screenrow, 30)
						AS_actual = trim(AS_actual)
						BGP = "Si tiene"
					Case 4 ' description BGP 
						columnaActual = crt.screen.CurrentColumn 
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString chr(13)
						descripcion_BGP = crt.Screen.Get(screenrow, columnaActual, screenrow, 100)
						descripcion_BGP = trim(descripcion_BGP)
						BGP = "Si tiene"
					Case 5 ' % No such configuration item(s)
						BGP = "NO TIENE"
					End Select
					Salir = crt.screen.WaitForStrings (chr(13), "#")
				loop
			else 
				'sh run router bgp 7303 neighbor 181.96.26.250
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual BGP: sh run router bgp 7303 " & " neighbor " & NEXTHOP & vbCrLf
				crt.Screen.Send "sh run router bgp 7303 " & " neighbor " & NEXTHOP & chr(13) 'muestro la configuracion del BGP
				crt.screen.WaitForStrings PalabrasCLAVE   'espera la palabra arg			
				Salir = crt.screen.WaitForStrings (chr(13), "#", "remote-as ", "description ", "% No such configuration item(s)")
				do while Salir <> 2
					screenrow = crt.screen.CurrentRow
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
					Salir = crt.screen.WaitForStrings(chr(13), "#", "remote-as ", "description ", "% No such configuration item(s)")
					Select Case Salir
					Case 3 ' remote-as 
						columnaActual = crt.screen.CurrentColumn 
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString chr(13)
						AS_actual = crt.Screen.Get(screenrow, columnaActual, screenrow, 30)
						AS_actual = trim(AS_actual)
						BGP = "Si tiene"
					Case 4 ' description BGP 
						columnaActual = crt.screen.CurrentColumn 
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString chr(13)
						descripcion_BGP = crt.Screen.Get(screenrow, columnaActual, screenrow, 100)
						BGP = "Si tiene"
					Case 5
						BGP = "NO TIENE"
					End Select
				loop
			end if
			end if
			neighbor_BGP = BGP
			'MsgBox "termine de leer la configuracion de la BGP"
			
			if neighbor_BGP = "NO TIENE" then
				if VRF <> "NO TIENE" then
					BGP = CISCO_ver_BGP(file,EQUIPO, SUBINTERFACE, ip_WAN, NEXTHOP, VRF, PalabrasCLAVE)
				else
					BGP = neighbor_BGP
				end if
			end if
			
			'ver las redes en BGP
			'RP/0/RSP0/CPU0:BGN1MB#sh bgp neighbor 181.88.88.90 routes          
			'Tue Jul 23 11:18:01.932 ARG
			'BGP router identifier 181.88.69.130, local AS number 7303
			'BGP generic scan interval 60 secs
			'Non-stop routing is enabled
			'BGP table state: Active
			'Table ID: 0xe0000000   RD version: 102015316
			'BGP main routing table version 102015316
			'BGP NSR Initial initsync version 3 (Reached)
			'BGP NSR/ISSU Sync-Group versions 102015316/0
			'BGP scan interval 60 secs

			'Status codes: s suppressed, d damped, h history, * valid, > best
			'			  i - internal, r RIB-failure, S stale, N Nexthop-discard
			'Origin codes: i - IGP, e - EGP, ? - incomplete
			'   Network            Next Hop            Metric LocPrf Weight Path
			'*> 200.45.248.8/29    181.88.88.90             0             0 64975 i
			'*> 200.45.248.248/29  181.88.88.90             0             0 64975 i
			
			' para caso que no encuentro nada
			' % Neighbor not found
			
			if ip_WAN <> "NO TIENE" then
			if VRF = "NO TIENE" then
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Redes BGP: sh bgp neighbor " & NEXTHOP & " routes " & vbCrLf
				crt.Screen.Send "sh bgp neighbor " & NEXTHOP & " routes " & chr(13) 'muestro la configuracion de redes BGP
			else 
				'caso con VRF BGN1MB#sh run int Te0/1/1/1.1140115
				'RP/0/RSP0/CPU0:BGN1MB#sh bgp vrf hipotecario-vpn neighbors 172.29.251.66 routes
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Redes BGP: sh bgp vrf " & VRF & " neighbors " & NEXTHOP & " routes " & vbCrLf
				crt.Screen.Send "sh bgp vrf " & VRF & " neighbors " & NEXTHOP & " routes " & chr(13) 'muestro la configuracion de redes BGP
			end if
			crt.screen.WaitForStrings PalabrasCLAVE   'espera la palabra arg			
			Salir = crt.screen.WaitForStrings (chr(13), "#", "Neighbor not found", "Path")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings(chr(13), "#", "Neighbor not found", "Path", AS_actual)
				Select Case Salir
				Case 3 ' Neighbor not found
					' no encontró el neighbor
					Redes_aprendidas(0) = "No aprende redes por BGP"
					i_redes = i_redes + 1
				Case 4 ' Path
					' arranca la tabla
					'   Network            Next Hop            Metric LocPrf Weight Path
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					Redes_aprendidas(i_redes) = crt.Screen.Get(screenrow, 1, screenrow, 200)
					Redes_aprendidas(i_redes) = rtrim(Redes_aprendidas(i_redes))
					i_redes = i_redes + 1
				Case 5 ' AS_actual
					'*> 200.45.248.8/29    181.88.88.90             0             0 64975 i
					'*> 200.45.248.248/29  181.88.88.90             0             0 64975 i
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					Redes_aprendidas(i_redes) = crt.Screen.Get(screenrow, 1, screenrow, 200)
					Redes_aprendidas(i_redes) = trim(Redes_aprendidas(i_redes))
					i_redes = i_redes + 1
				End Select
			loop
			end if 
			Cant_redes = i_redes
			'termine de ver las redes en BGP
			
			'Veo la tabla de arp
			'sh arp  vrf vpn-gestion-sdh-huawei Te0/2/1/0.1610900016
			algo = CISCO_mostrar_tabla_arp(file, EQUIPO, SUBINTERFACE, VRF)
			'Termine de mostrar la tabla arp
			
			
			'sh bgp vrf afip-vpn summary | inc 192.168.130.58
			if ip_WAN <> "NO TIENE" then
			if VRF <> "NO TIENE" then
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Redes BGP: sh bgp vrf " & vrf & " summary | inc " & NEXTHOP & vbCrLf
				crt.Screen.Send "sh bgp vrf " & vrf & " summary | inc " & NEXTHOP & chr(13) 'muestro la configuracion de redes BGP
			else 
				'sh bgp summary | inc NEXTHOP
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Redes BGP: sh bgp summary | inc " & NEXTHOP & vbCrLf
				crt.Screen.Send "sh bgp summary | inc " & NEXTHOP & chr(13) 'muestro la configuracion de redes BGP
			end if
			crt.screen.WaitForStrings PalabrasCLAVE   'espera la palabra arg			
			Salir = crt.screen.WaitForStrings (chr(13), "#", "Neighbor not found", "Path")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings(chr(13), "#", "Neighbor not found", "Path", AS_actual)
				Select Case Salir
				Case 3 ' Neighbor not found
					' no encontró el neighbor
					Redes_aprendidas(0) = "No aprende redes por BGP"
					i_redes = i_redes + 1
				Case 4 ' Path
					' arranca la tabla
					'   Network            Next Hop            Metric LocPrf Weight Path
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					Redes_aprendidas(i_redes) = crt.Screen.Get(screenrow, 1, screenrow, 200)
					Redes_aprendidas(i_redes) = rtrim(Redes_aprendidas(i_redes))
					i_redes = i_redes + 1
				Case 5 ' AS_actual
					'*> 200.45.248.8/29    181.88.88.90             0             0 64975 i
					'*> 200.45.248.248/29  181.88.88.90             0             0 64975 i
					screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					Redes_aprendidas(i_redes) = crt.Screen.Get(screenrow, 1, screenrow, 200)
					Redes_aprendidas(i_redes) = trim(Redes_aprendidas(i_redes))
					i_redes = i_redes + 1
				End Select
			loop
			end if 
			
			' ahora tengo que ver las estaticas
			algo = CISCO_estaticas(file,EQUIPO, SUBINTERFACE, ip_WAN, NEXTHOP, VRF, PalabrasCLAVE)
			'MsgBox "termine de ver las estaticas"
			
			' ahora tengo que ver las estaticas que tienen salida a internet
			' sh run | inc 181.10.29.16
			' sh run | inc IP_de_LAN
			do while indice < Cant_estaticas
				if MASCARA_estatica(indice) <> "32" then
					file.Write EQUIPO & " " & SUBINTERFACE & "	Estaticas con salida a internet: sh run | inc " & Estatica(indice) & vbCrLf
					crt.Screen.Send "sh run | inc " & Estatica(indice) & chr(13) 
					SalidaINTERNET(indice) = "NO TIENE"
					Salir = crt.screen.WaitForStrings (chr(13), "#", "red-integra", "arg")
					if Salir = 2 then 
						SalidaINTERNET(indice) = "NO TIENE"
						indice = indice + 1
					end if
					do while Salir <> 2
						Select Case Salir
						Case 3 ' red-integra 
							SalidaINTERNET(indice) = Estatica(indice)
							'MsgBox "SalidaINTERNET " & indice & " " & SalidaINTERNET(indice)
							crt.screen.WaitForString chr(13)
							indice = indice + 1
						End Select
						screenrow = crt.screen.CurrentRow
						readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
						readline = rtrim(readline)
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
						Salir = crt.screen.WaitForStrings (chr(13), "#", "red-integra", "arg")
						if Salir = 2 then
							SalidaINTERNET(indice) = "NO TIENE"
							indice = indice + 1
						end if
					loop
					'MsgBox "Cant_estaticas " & Cant_estaticas
				else 
					SalidaINTERNET(indice) = "NO TIENE"
					indice = indice + 1
				end if
			loop
			indice = 0
			'MsgBox "termine de ver las estaticas con salida a internet"
			
			
			
			' ahora tengo que ver los policy
			if policy_input <> "NO TIENE" then
			file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Policy input: sh run policy-map " & policy_input & vbCrLf
			crt.Screen.Send "sh run policy-map " & policy_input & chr(13) 'muestro el policy input
			crt.screen.WaitForStrings PalabrasCLAVE 'espera la palabra arg			
			Salir = crt.screen.WaitForStrings (chr(13), "#")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings(chr(13), "#")
			loop
			end if
			' MsgBox "termine de ver el policy input"
			' ahora tengo que ver el policy output
			if policy_output <> "NO TIENE" then
			file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Policy output: sh run policy-map " & policy_output & vbCrLf
			crt.Screen.Send "sh run policy-map " & policy_output & chr(13) 'muestro el policy output
			crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg				
			Salir = crt.screen.WaitForStrings (chr(13), "#")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings(chr(13), "#")
			loop
			end if
			'MsgBox "termine de ver el policy output"
			
			'-----------------------------------------------------
			' ahora tengo que tirar ping a la WAN+1
			'MsgBox "ip_WAN " & ip_WAN
			if ip_WAN <> "NO TIENE" then
			if VRF <> "NO TIENE" then
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Prueba de PING WAN+1: ping vrf " & VRF & " " & NEXTHOP & vbCrLf
				crt.Screen.Send "ping vrf " & VRF & " " & NEXTHOP & chr(13) 'tiro ping a la WAN+1
				crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg				
				Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
				do while Salir <> 2
					screenrow = crt.screen.CurrentRow
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
					Salir = crt.screen.WaitForStrings(chr(13), "#", "Success ")
					Select Case Salir
					Case 3 ' Success
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString ")"
						columnaFinal = crt.screen.CurrentColumn - 1
						Resultado_pingWAN = crt.Screen.Get(screenrow, 1, screenrow, columnaFinal)
						crt.screen.WaitForString chr(13)
					End Select
				loop
				file.Write EQUIPO & " " & SUBINTERFACE & vbCrLf 'solo un enter en el archivo
			else
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Prueba de PING WAN+1: ping " & " " & NEXTHOP & vbCrLf
				crt.Screen.Send "ping " & " " & NEXTHOP & chr(13) 'tiro ping a la WAN+1
				crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg				
				Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
				do while Salir <> 2
					screenrow = crt.screen.CurrentRow
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
					Salir = crt.screen.WaitForStrings(chr(13), "#", "Success ")
					Select Case Salir
					Case 3 ' Success
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString ")"
						columnaFinal = crt.screen.CurrentColumn - 1
						Resultado_pingWAN = crt.Screen.Get(screenrow, 1, screenrow, columnaFinal)
						crt.screen.WaitForString chr(13)
					End Select
				loop
				file.Write EQUIPO & " " & SUBINTERFACE & vbCrLf 'solo un enter en el archivo
			end if
			end if
			'MsgBox "termino el ping a la WAN+1"
			'-----------------------------------------------------
			
			'ahora tengo que tirar ping a las estaticas
			'(StrComp(Siguiente_EQUIPO,EQUIPO) = 0) 
			if Estatica(0) <> "NO TIENE" then
			if ip_WAN <> "NO TIENE" then
			file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Prueba de PING estaticas: " & vbCrLf
			indice = 0
			Salir = 0
			'MsgBox "MASCARA_estatica " & indice & ": " & MASCARA_estatica(indice)
			if VRF <> "NO TIENE" then
				do while Salir <> 4
					if MASCARA_estatica(indice) = 32 then
						crt.Screen.Send "ping vrf " & VRF & " " & ipPING(indice) & chr(13) 'tiro ping a la /32
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping vrf " & VRF & " " & ipPING(indice) & vbCrLf
						pingEstatica(indice) = "Ping Estatica:	ping vrf " & VRF & " " & ipPING(indice) & VBTab & "ping -vpn-instance " & VRF & " " & ipPING(indice) & vbCrLf
						crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg
						Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
					else 
						'Calculo de Siguiente IP 
						PING_PRUEBA = SiguienteIP(ipPING(indice))
						crt.Screen.Send "ping vrf " & VRF & " " & PING_PRUEBA & chr(13) 'tiro ping a la LAN
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping vrf " & VRF & " " & PING_PRUEBA & vbCrLf
						pingEstatica(indice) = "Ping Estatica:	ping vrf " & VRF & " " & PING_PRUEBA & VBTab & "ping -vpn-instance " & VRF & " " & PING_PRUEBA & vbCrLf
						crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg					
						Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
					end if
					
					do while Salir <> 2
						screenrow = crt.screen.CurrentRow
						readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
						readline = rtrim(readline)
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
						Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
						
						'Encontrado = Instr(readline, "Success")
						'if Encontrado <> 0 then
						'	Resultado_pingEstatica(indice) = Mid(readline, 1, 33)
						'	MsgBox Resultado_pingEstatica(indice)
						'end if
						
						Select Case Salir
						Case 3 ' Success
							screenrow = crt.screen.CurrentRow
							crt.screen.WaitForString ")"
							columnaFinal = crt.screen.CurrentColumn - 1
							Resultado_pingEstatica(indice) = crt.Screen.Get(screenrow, 1, screenrow, columnaFinal)
							crt.screen.WaitForString chr(13)
							'MsgBox Resultado_pingEstatica(indice)
						End Select
					loop
					

					
					indice = indice + 1
					if indice = Cant_estaticas then
						Salir = 4
					end if
				loop
				indice = 0
			else 
				do while Salir <> 4
					if MASCARA_estatica(indice) = 32 then
						crt.Screen.Send "ping " & ipPING(indice) & chr(13) 'tiro ping a la /32
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping " & ipPING(indice) & vbCrLf
						pingEstatica(indice) = "Ping Estatica:	ping " & ipPING(indice) & VBTab & "ping " & ipPING(indice) & vbCrLf
						'MsgBox "ping a la loopback - MASCARA_estatica(indice) " & MASCARA_estatica(indice)
						crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg
						Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
					else 
						'Calculo de Siguiente IP
						PING_PRUEBA = SiguienteIP(ipPING(indice))
						
						crt.Screen.Send "ping " & PING_PRUEBA & chr(13) 'tiro ping a la LAN
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping " & PING_PRUEBA & vbCrLf
						pingEstatica(indice) = "Ping Estatica:	ping " & PING_PRUEBA & VBTab & "ping " & PING_PRUEBA & vbCrLf
						crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg					
						Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
					end if
					
					do while Salir <> 2
						screenrow = crt.screen.CurrentRow
						readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
						readline = rtrim(readline)
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
						Salir = crt.screen.WaitForStrings (chr(13), "#", "Success ")
						
						'Encontrado = Instr(readline, "Success")
						'if Encontrado <> 0 then
						'	Resultado_pingEstatica(indice) = Mid(readline, 1, 33)
						'	MsgBox Resultado_pingEstatica(indice)
						'end if
						
						Select Case Salir
						Case 3 ' Success
							screenrow = crt.screen.CurrentRow
							crt.screen.WaitForString ")"
							columnaFinal = crt.screen.CurrentColumn - 1
							Resultado_pingEstatica(indice) = crt.Screen.Get(screenrow, 1, screenrow, columnaFinal)
							crt.screen.WaitForString chr(13)
							'MsgBox Resultado_pingEstatica(indice)
						End Select
					loop
					

					
					indice = indice + 1
					if indice = Cant_estaticas then
						Salir = 4
					end if
				loop
				indice = 0
			end if
			end if
			end if
		
			' ahora tengo que imprimir las variables

			file.Write   "---------------------------------------" & vbCrLf
			file.Write   "DATOS Configuracion Actual: " & vbCrLf
			file.Write   "EQUIPO:	" & EQUIPO & vbCrLf
			file.Write   "PORT:	" & PUERTO & vbCrLf
			file.Write   "Subinterface:	" & Subint & vbCrLf
			file.Write   "Subinterface completa:	" & SUBINTERFACE & vbCrLf
			file.Write   "Estado Subinterface:	" & Estado_Subint & vbCrLf
			file.Write   "Trafico input:	" & (Trafico_input/1000000) & " Mbps" & vbCrLf
			file.Write   "Trafico output:	" & (Trafico_output/1000000) & " Mbps" & vbCrLf
			file.Write   "Descripcion:	" & DESCRIPCION & vbCrLf
			file.Write   "Bandwidth:	" & BANDWIDTH & vbCrLf
			file.Write   "Policy input:	" & policy_input & vbCrLf
			file.Write   "Policy output:	" & policy_output & vbCrLf
			file.Write   "VRF:	" & VRF & vbCrLf
			file.Write   "Ip de WAN:	" & ip_WAN & vbCrLf
			file.Write   "Mascara WAN:	" & mascara_WAN & vbCrLf
			file.Write   "WAN+1:	" & NEXTHOP & vbCrLf
			file.Write   "CVLAN:	" & CVLAN & vbCrLf
			file.Write   "RD:	" & RD & vbCrLf
			file.Write   "BGP:	" & BGP & vbCrLf
			file.Write   "BGP neighbor:	" & neighbor_BGP & vbCrLf
			file.Write   "AS:	" & AS_actual & vbCrLf
			file.Write   "Peakflow:	" & PEAKFLOW & vbCrLf
			file.Write   "Descripcion BGP:	" & descripcion_BGP & vbCrLf
			do while indice < Cant_estaticas
				file.Write   "Estatica " & indice & " :	" & Estatica(indice) & vbCrLf
				if SalidaINTERNET(indice) <> "NO TIENE" then
					file.Write   "Salida a INTERNET:	" & SalidaINTERNET(indice) & vbCrLf
				end if
				indice = indice + 1
			loop
			file.Write   "Resultado ping WAN+1:	" & NEXTHOP & " " & Resultado_pingWAN & vbCrLf
			indice = 0
			do while indice < Cant_estaticas
				file.Write   "Resultado Estatica " & indice & ":	" & Estatica(indice) & " " & Resultado_pingEstatica(indice) & vbCrLf
				indice = indice + 1
			loop
			i_redes = 0
			do while i_redes < Cant_redes
				file.Write Redes_aprendidas(i_redes) & vbCrLf
				i_redes = i_redes + 1
			loop
			
			fileoutTabladeDatos.Write   "---------------------------------------" & vbCrLf
			fileoutTabladeDatos.Write   "DATOS Configuracion Actual: " & vbCrLf
			fileoutTabladeDatos.Write   "EQUIPO: " & EQUIPO & vbCrLf
			fileoutTabladeDatos.Write   "PORT: " & PUERTO & vbCrLf
			fileoutTabladeDatos.Write   "Subinterface: " & Subint & vbCrLf
			fileoutTabladeDatos.Write   "Subinterface completa: " & SUBINTERFACE & vbCrLf
			fileoutTabladeDatos.Write   "Estado Subinterface: " & Estado_Subint & vbCrLf
			fileoutTabladeDatos.Write   "Trafico input: " & (Trafico_input/1000000) & " Mbps" & vbCrLf
			fileoutTabladeDatos.Write   "Trafico output: " & (Trafico_output/1000000) & " Mbps" & vbCrLf
			fileoutTabladeDatos.Write   "Descripcion: " & DESCRIPCION & vbCrLf
			fileoutTabladeDatos.Write   "Bandwidth: " & BANDWIDTH & vbCrLf
			fileoutTabladeDatos.Write   "Policy input: " & policy_input & vbCrLf
			fileoutTabladeDatos.Write   "Policy output: " & policy_output & vbCrLf
			fileoutTabladeDatos.Write   "VRF: " & VRF & vbCrLf
			fileoutTabladeDatos.Write   "Ip de WAN: " & ip_WAN & vbCrLf
			fileoutTabladeDatos.Write   "Mascara WAN: " & mascara_WAN & vbCrLf
			fileoutTabladeDatos.Write   "WAN+1: " & NEXTHOP & vbCrLf
			fileoutTabladeDatos.Write   "CVLAN: " & CVLAN & vbCrLf
			fileoutTabladeDatos.Write   "RD: " & RD & vbCrLf
			fileoutTabladeDatos.Write   "BGP: " & BGP & vbCrLf 
			fileoutTabladeDatos.Write   "BGP neighbor: " & neighbor_BGP & vbCrLf
			fileoutTabladeDatos.Write   "AS: " & AS_actual & vbCrLf
			fileoutTabladeDatos.Write   "Peakflow: " & PEAKFLOW & vbCrLf
			fileoutTabladeDatos.Write   "Descripcion BGP: " & descripcion_BGP & vbCrLf
			indice = 0
			do while indice < Cant_estaticas
				fileoutTabladeDatos.Write   "Estatica: " & Estatica(indice) & vbCrLf
				if SalidaINTERNET(indice) <> "NO TIENE" then
					fileoutTabladeDatos.Write   "Salida a INTERNET: " & SalidaINTERNET(indice) & vbCrLf
					'MsgBox "Salida a INTERNET: " & SalidaINTERNET(indice)
				else 
					fileoutTabladeDatos.Write "Salida a INTERNET: " & "NO TIENE" & vbCrLf
				end if
				indice = indice + 1
			loop
			fileoutTabladeDatos.Write   "Resultado ping WAN+1: " & NEXTHOP & " " & Resultado_pingWAN & vbCrLf
			do while indice < Cant_estaticas
				fileoutTabladeDatos.Write   "Resultado Estatica " & indice & ": " & Estatica(indice) & " " & Resultado_pingEstatica(indice) & vbCrLf
				indice = indice + 1
			loop
			
			fileoutTabladeDatos.Write "Tabla de PING:	MSBNG	CX600" & vbCrLf
			if VRF = "NO TIENE" then
				fileoutTabladeDatos.Write "Ping WAN+1:	ping " & NEXTHOP & VBTab & "ping " & NEXTHOP & vbCrLf
			else
				fileoutTabladeDatos.Write "Ping WAN+1:	ping vrf " & VRF & " " & NEXTHOP & VBTab & "ping -vpn-instance " & VRF & " " & NEXTHOP & vbCrLf
			end if
			indice = 0
			do while indice < Cant_estaticas
				fileoutTabladeDatos.Write pingEstatica(indice)
				indice = indice + 1
			loop
			i_redes = 0
			do while i_redes < Cant_redes
				fileoutTabladeDatos.Write Redes_aprendidas(i_redes) & vbCrLf
				i_redes = i_redes + 1
			loop
			
			
			if filedatos.AtEndOfStream = True then
				'crt.Screen.Send "exit" & chr(13)
				'crt.screen.WaitForString("$")
				ESTADO = 7
				funcion_CISCO = ESTADO
				Exit Function
			end if
			'CMUNECAS
			'Siguiente_EQUIPO = filedatos.Read(8) ' leo el equipo
			'RSC1MB
			'Siguiente_EQUIPO = filedatos.Read(6) ' leo el equipo
			'MsgBox "Siguiente_EQUIPO " & Siguiente_EQUIPO
			
			'if (StrComp(Siguiente_EQUIPO,EQUIPO) = 0) then 
				ESTADO = 3
			'else
			'	crt.Screen.Send "exit" & chr(13)
			'	crt.screen.WaitForString("$")
			'	'EQUIPO = filedatos.Read(6) ' leo el equipo
			'	'MsgBox "Equipo " & str
			'	EQUIPO = Siguiente_EQUIPO
			'    crt.Screen.Send "ttelnet " & EQUIPO & Chr(13)
	        '    'file.Write EQUIPO & VBTab
			'	ESTADO = crt.screen.WaitForStrings("Username:", ">", "#", "$", "...")
				'ESTADO = 0
			'end if
			
						
			file.Write "-----------------------------" & vbCrLf
			file.Write "-----------------------------" & vbCrLf
			'ESTADO = 0
			if filedatos.AtEndOfStream = True then ESTADO = 7
			funcion_CISCO = ESTADO
End Function

function encontrarString(linealeida, StringsArray)
	i=0
	
	Length = UBound(StringsArray) 
	For i=1 To Length
		lngPos = Instr(linealeida, StringsArray(i))
		if lngPos > 0 then 'encontró la interface
			'file.Write EQUIPO & " " & SUBINTERFACE & "	" & linealeida & vbCrLf
			'Salir = 1
			'Msgbox linealeida & " " & StringsArray(i)
			encontrarString = i + 1
			exit function
		end if
	Next
	
	if i = Length then ' esto quiere decir que llegue al final del array y no encontré lo que queria
		encontrarString = 0 'asi que devuelvo cero como en el caso de la funcion Instr
	end if
end function





Function SiguienteIP(IP)
	
	'MsgBox "IP " & IP
	lngPos = InstrRev(IP, ".")
	ultimoCARACTER = Mid(IP, lngPos+1, Len(IP))
	'MsgBox "ultimoCARACTER " & ultimoCARACTER
	PING_PRUEBA = Mid(IP, 1, lngPos) & (ultimoCARACTER+1)
	'MsgBox "Original " & IP & vbCrLf & "PING_PRUEBA " & PING_PRUEBA
	
	SiguienteIP = PING_PRUEBA
End Function

Function ping_a_la_NEXTHOP_HUAWEI(ip_WAN, VRF, NEXTHOP, file, EQUIPO, SUBINTERFACE, Equipo_gestor)
	' ahora tengo que tirar ping a la WAN+1
	'MsgBox "ip_WAN " & ip_WAN
	file.Write EQUIPO & " " & SUBINTERFACE & vbCrLf
	if ip_WAN <> "NO TIENE" then
	if VRF <> "NO TIENE" then
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Prueba de PING WAN+1: ping vrf " & VRF & " " & NEXTHOP & vbCrLf
		crt.Screen.Send "ping -vpn-instance " & VRF & " " & NEXTHOP & chr(13) 'tiro ping a la WAN+1
	else
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Prueba de PING WAN+1: ping " & " " & NEXTHOP & vbCrLf
		crt.Screen.Send "ping " & " " & NEXTHOP & chr(13) 'tiro ping a la WAN+1
	end if
		'Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
		'crt.screen.WaitForStrings "ping statistics"  'espera la palabra arg 
		Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
		do while Salir <> 2
			screenrow = crt.screen.CurrentRow
			readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
			readline = rtrim(readline)
			file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
			Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
			Select Case Salir
			Case 3 ' packet loss
				screenrow = crt.screen.CurrentRow
				crt.screen.WaitForString chr(13)
				columnaFinal = crt.screen.CurrentColumn 
				Resultado_pingWAN = crt.Screen.Get(screenrow, 1, screenrow, 100)
				Resultado_pingWAN = trim(Resultado_pingWAN)	
				'crt.screen.WaitForString chr(13)
				'MsgBox "Resultado_pingWAN " & Resultado_pingWAN
			End Select
		loop
		file.Write EQUIPO & " " & SUBINTERFACE & vbCrLf 'solo un enter en el archivo
	end if
	'MsgBox "termino el ping a la WAN+1"
	
	ping_a_la_NEXTHOP_HUAWEI = Resultado_pingWAN
End Function


Function ping_a_las_Estaticas_HUAWEI(Estatica, MASCARA_estatica, ipPING, pingEstatica, Resultado_pingEstatica, indice, ip_WAN, VRF, NEXTHOP, file, EQUIPO, SUBINTERFACE, Equipo_gestor)
	' ahora tengo que tirar ping a las estaticas
	' habria que ver el caso que tiene VRF ese me falta
	
	if Estatica(0) <> "NO TIENE" then
	if ip_WAN <> "NO TIENE" then
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual Prueba de PING estaticas: " & vbCrLf
		'indice = 0
		Salir = 0
		'MsgBox "MASCARA_estatica " & indice & ": " & MASCARA_estatica(indice)
		if VRF <> "NO TIENE" then
			do while Salir <> 4
				'MsgBox "MASCARA_estatica " & MASCARA_estatica(indice) & " " & indice
				if MASCARA_estatica(indice) = "255.255.255.255" then
					crt.Screen.Send "ping -vpn-instance " & VRF & " " & ipPING(indice) & chr(13) 'tiro ping a la /32
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping -vpn-instance " & VRF & " " & ipPING(indice) & vbCrLf
					pingEstatica(indice) = "Ping Estatica:	ping vrf " & VRF & " " & ipPING(indice) & VBTab & "ping -vpn-instance " & VRF & " " & ipPING(indice) & vbCrLf
					'crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg
					Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
				else 
					'Calculo de Siguiente IP 
					'MsgBox "ipPING(indice) " & ipPING(indice) 
					PING_PRUEBA = SiguienteIP(ipPING(indice))
					crt.Screen.Send "ping -vpn-instance " & VRF & " " & PING_PRUEBA & chr(13) 'tiro ping a la LAN
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping -vpn-instance " & VRF & " " & PING_PRUEBA & vbCrLf
					pingEstatica(indice) = "Ping Estatica:	ping vrf " & VRF & " " & PING_PRUEBA & VBTab & "ping -vpn-instance " & VRF & " " & PING_PRUEBA & vbCrLf
					'crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg					
					Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
				end if
					
					do while Salir <> 2
						screenrow = crt.screen.CurrentRow
						readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
						readline = rtrim(readline)
						file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
						Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
						
						'Encontrado = Instr(readline, "Success")
						'if Encontrado <> 0 then
						'	Resultado_pingEstatica(indice) = Mid(readline, 1, 33)
						'	MsgBox Resultado_pingEstatica(indice)
						'end if
						
						Select Case Salir
						Case 3 ' packet loss
							screenrow = crt.screen.CurrentRow
							crt.screen.WaitForString chr(13)
							columnaFinal = crt.screen.CurrentColumn 
							Resultado_pingEstatica(indice) = crt.Screen.Get(screenrow, 1, screenrow, 100)
							Resultado_pingEstatica(indice) = trim(Resultado_pingEstatica(indice))	
						End Select
					loop
					

					
					'indice = indice + 1
					'if indice = Cant_estaticas then
						Salir = 4
					'end if
			loop
		'indice = 0
		else ' en caso de no tener VRF
			do while Salir <> 4
				if MASCARA_estatica(indice) = "255.255.255.255" then
					crt.Screen.Send "ping " & ipPING(indice) & chr(13) 'tiro ping a la /32
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping " & ipPING(indice) & vbCrLf
					pingEstatica(indice) = "Ping Estatica:	ping " & ipPING(indice) & VBTab & "ping " & ipPING(indice) & vbCrLf
					'crt.screen.WaitForStrings PalabrasCLAVE  'espera la palabra arg
					Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
				else 
					'Calculo de Siguiente IP
					'MsgBox ipPING(indice)
					PING_PRUEBA = SiguienteIP(ipPING(indice))
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & "ping " & PING_PRUEBA & vbCrLf
					pingEstatica(indice) = "Ping Estatica:	ping " & PING_PRUEBA & VBTab & "ping " & PING_PRUEBA & vbCrLf
					crt.Screen.Send "ping " & PING_PRUEBA & chr(13) 'tiro ping a la LAN
					crt.screen.WaitForStrings "ping statistics"  'espera la palabra arg 				
					Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
				end if
				
				do while Salir <> 2					
					screenrow = crt.screen.CurrentRow
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
					Salir = crt.screen.WaitForStrings (chr(13), Equipo_gestor, "packet loss")
					
					
					Select Case Salir
						Case 3 '"packet loss"
							screenrow = crt.screen.CurrentRow
							crt.screen.WaitForString chr(13)
							columnaFinal = crt.screen.CurrentColumn
							Resultado_pingEstatica(indice) = crt.Screen.Get(screenrow, 1, screenrow, 100)
							Resultado_pingEstatica(indice) = trim(Resultado_pingEstatica(indice))	
							'MsgBox Resultado_pingEstatica(indice)
							'crt.screen.WaitForString chr(13)
					End Select
				loop
					

					
					'indice = indice + 1
					'if indice = Cant_estaticas then
						Salir = 4
					'end if
				loop
				'indice = 0
			end if
			end if
			end if
	
	ping_a_las_Estaticas_HUAWEI = Resultado_pingEstatica(indice)
	
End Function

			
Function CISCO_mostrar_tabla_arp(file, EQUIPO, SUBINTERFACE, VRF)
	'Veo la tabla de arp
	'sh arp  vrf vpn-gestion-sdh-huawei Te0/2/1/0.1610900016
	
	file.Write EQUIPO & " " & SUBINTERFACE & "	" & vbCrLf
	file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual TABLA ARP " & vbCrLf
	
	if VRF <> "NO TIENE" then
		crt.Screen.Send "sh arp  vrf " & VRF & " " &  SUBINTERFACE  & chr(13) 'muestro la tabla arp
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & "sh arp  vrf " & VRF & " " & SUBINTERFACE & vbCrLf			
	else
		crt.Screen.Send "sh arp "  & SUBINTERFACE  & chr(13) 'muestro la tabla arp
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & "sh arp " & SUBINTERFACE & vbCrLf
	end if
	
	Salir = crt.screen.WaitForStrings (chr(13), "#")
	
			
	'crt.screen.WaitForStrings PalabrasCLAVE   'espera la palabra arg			
	do while Salir <> 2
		screenrow = crt.screen.CurrentRow
		readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
		readline = rtrim(readline)
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
		Salir = crt.screen.WaitForStrings(chr(13), "#")
	loop
	
	CISCO_mostrar_tabla_arp = "listo"
	'Termine de mostrar la tabla arp
End Function

Function CISCO_ver_BGP(file,EQUIPO, SUBINTERFACE, ip_WAN, NEXTHOP, VRF, PalabrasCLAVE)
	' ahora tengo que ver la configuracion del BGP

	'router bgp 7303
	' vrf vpn-gestion-sdh-huawei
	'  rd 7303:646
	'  address-family ipv4 unicast
	'   redistribute connected
	'   redistribute static
	'  !
	
	'router bgp 7303
	'vrf aeroarg-vpn
	'rd 7303:1270
	'address-family ipv4 unicast
	'redistribute connected
	'redistribute static
	'!
	
	'OJO que veo el RD aca en el BGP pero yo el dato lo estoy tomando de la VRF
	' de hecho creo que tomar el RD de aca sería mejor
	
	if ip_WAN <> "NO TIENE" then
		if VRF <> "NO TIENE" then ' SI TIENE VRF hago lo siguiente
			file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual BGP: sh run router bgp 7303 vrf " & VRF & vbCrLf
			crt.Screen.Send "sh run router bgp 7303 vrf " & VRF & chr(13) 'muestro la configuracion del BGP
			crt.screen.WaitForStrings PalabrasCLAVE   'espera la palabra arg			
			Salir = crt.screen.WaitForStrings (chr(13), "#", "--More--", "redistribute connected ", "% No such configuration item(s)")
			do while Salir <> 2
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				Salir = crt.screen.WaitForStrings (chr(13), "#", "--More--", "redistribute connected", "% No such configuration item(s)")
				Select Case Salir
				Case 3 ' --More--
					crt.Screen.Send " " & chr(13) 'muestro la configuracion del BGP
				Case 4 ' redistribute connected
				'	crt.screen.WaitForString "redistribute static"
				'	columnaActual = crt.screen.CurrentColumn 
				'	screenrow = crt.screen.CurrentRow
					crt.screen.WaitForString chr(13)
					'descripcion_BGP = crt.Screen.Get(screenrow, columnaActual, screenrow, 100)
					'descripcion_BGP = trim(descripcion_BGP)
					BGP = "Si tiene"
				Case 5
					BGP = "NO TIENE"
				End Select
			loop
			'else ' pero si NO TIENE VRF no deberia hacer nada porque solo puedo preguntar por el neighbor BGP
				
		end if
	end if
			'MsgBox "termine de leer la configuracion de la BGP"
	CISCO_ver_BGP = BGP
End Function


Function HUAWEI_mostrar_tabla_arp(file, EQUIPO, SUBINTERFACE, VRF)
	'Veo la tabla de arp
	'disp arp vpn-instance argentconec-vpn all | inc 3/1/9.10
	i = 0
	
	crt.Screen.Synchronous = True
	
	For i=1 To Len(SUBINTERFACE)
		Caracter = Mid(SUBINTERFACE,i,1)
		Subint_recortada = Mid(SUBINTERFACE,i,Len(SUBINTERFACE))
		'MsgBox Caracter & " " & IsNumeric(Caracter) & " " & Subint_recortada
		if IsNumeric(Caracter) =  True then
			exit for
		end if
	Next 
	
	file.Write EQUIPO & " " & SUBINTERFACE & "	" & vbCrLf
	file.Write EQUIPO & " " & SUBINTERFACE & "	" & "Config Actual TABLA ARP " & vbCrLf
	
	if VRF <> "NO TIENE" then
		crt.Screen.Send "disp arp int " & SUBINTERFACE & chr(13) 'G3/1/9.10
		'crt.Screen.Send "disp arp vpn-instance " & VRF & " all | inc " & Subint_recortada & chr(13) '3/1/9.10
	else
		crt.Screen.Send "disp arp int " & SUBINTERFACE & chr(13) '3/1/9.10
	end if
	Salir = crt.screen.WaitForStrings (chr(13), ">")
				
	do while Salir <> 2
		screenrow = crt.screen.CurrentRow
		readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
		readline = rtrim(readline)
		file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
		Salir = crt.screen.WaitForStrings(chr(13), ">")
	loop
	
	file.Write EQUIPO & " " & SUBINTERFACE & "	" & vbCrLf
	HUAWEI_mostrar_tabla_arp = "listo"
	'Termine de mostrar la tabla arp
End Function



Function CISCO_estaticas(file,EQUIPO, SUBINTERFACE, ip_WAN, NEXTHOP, VRF, PalabrasCLAVE)
	Dim pingEstatica(50)
	Dim Subint_recortada
	indice = 0
	Salir = 0
	
	if ip_WAN <> "NO TIENE" then
		if VRF <> "NO TIENE" then
			file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Estaticas: sh run router static vrf " & VRF & vbCrLf
			crt.Screen.Send "sh run router static vrf " & VRF & chr(13) 'muestro las estaticas
			crt.screen.WaitForStrings PalabrasCLAVE
			Salir = crt.screen.WaitForStrings("router static", "#", "% No such configuration item(s)")
			
			do while Salir <> 2
				Salir = crt.screen.WaitForStrings(chr(13), "#")
				screenrow = crt.screen.CurrentRow
				readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
				readline = rtrim(readline)
				file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
				
				StringsArray = array(chr(13), "#", SUBINTERFACE, "arg")
				Salir = encontrarString(readline, StringsArray)
				
				'   192.168.52.16/29 TenGigE0/2/1/0.1310180002 192.168.52.4
					
				Select Case Salir
					Case 3 ' SUBINTERFACE
				'		MsgBox readline
				'		columnaActual = crt.screen.CurrentColumn 
				'		screenrow = crt.screen.CurrentRow
				'		crt.screen.WaitForString chr(13)
						Provisirio = readline
						lngPos = Instr(Provisirio, "/")
						Estatica(indice) = Mid(Provisirio, 1, lngPos+2)
						ipPING(indice) = Mid(Estatica(indice), 1, lngPos-1)
						MASCARA_estatica(indice) = Mid(Estatica(indice), lngPos+1, Len(Estatica(indice)))
						Estatica(indice) = trim(Estatica(indice))
				'		'MsgBox "MASCARA_estatica " & indice & ": " & MASCARA_estatica(indice)
				'		MsgBox "Estatica " & indice & " " & Estatica(indice) & " mascara " & MASCARA_estatica(indice)
				'		'MsgBox "ipPING " & indice & ": " & ipPING(indice)
						indice = indice + 1
				End Select
				
					
					
				loop
				Cant_estaticas = indice
				'MsgBox "Cant_estaticas " & Cant_estaticas
				indice = 0
		else
			Subint_recortada = Recortar_SUBINTERFACE(SUBINTERFACE)
			'MsgBox Subint_recortada
				file.Write EQUIPO & " " & SUBINTERFACE & "	Config Actual Estaticas: sh run router static " & " | inc " & Subint_recortada & vbCrLf
				crt.Screen.Send "sh run router static " & " | inc " & Subint_recortada & chr(13) 'muestro las estaticas
				'crt.screen.WaitForString "arg"  'espera la palabra arg				
				'Salir = crt.screen.WaitForStrings (chr(13), "#", NEXTHOP, "arg", NEXTHOP)
				Salir = crt.screen.WaitForStrings(chr(13), "#", Subint_recortada, "arg", Subint_recortada)
				do while Salir <> 2
					'if Salir = 4 or Salir = 3 then crt.screen.WaitForString chr(13)
					screenrow = crt.screen.CurrentRow
					readline = crt.Screen.Get(screenrow, 1, screenrow, 200)
					readline = rtrim(readline)
					file.Write EQUIPO & " " & SUBINTERFACE & "	" & readline & vbCrLf
					'Salir = crt.screen.WaitForStrings(chr(13), "#", NEXTHOP, "arg")
					Salir = crt.screen.WaitForStrings(chr(13), "#", Subint_recortada, "arg")
					Select Case Salir
					Case 3 ' NEXTHOP o Subint
						screenrow = crt.screen.CurrentRow
						crt.screen.WaitForString chr(13)
						'columnaActual = crt.screen.CurrentColumn - 49
						Provisirio = crt.Screen.Get(screenrow, 1, screenrow, 200)
						lngPos = Instr(Provisirio, "/")
						Estatica(indice) = crt.Screen.Get(screenrow, 1, screenrow, lngPos+2)
						ipPING(indice) = Mid(Estatica(indice), 1, lngPos-1)
						MASCARA_estatica(indice) = Mid(Estatica(indice), lngPos+1, Len(Estatica(indice)))
						Estatica(indice) = trim(Estatica(indice))
						'MsgBox "MASCARA_estatica " & indice & ": " & MASCARA_estatica(indice)
						'MsgBox "Estatica " & indice & " " & Estatica(indice) & " mascara " & MASCARA_estatica(indice)
						'MsgBox "ipPING " & indice & ": " & ipPING(indice)
						indice = indice + 1
					End Select
				loop
				Cant_estaticas = indice
				'MsgBox "Cant_estaticas " & Cant_estaticas
				indice = 0
		end if
	end if
	
	CISCO_estaticas = 0

End Function

Function Recortar_SUBINTERFACE(texto)
	
	
	'MsgBox texto
	
	For i=1 To Len(texto)
		Caracter = Mid(texto,i,1)
		Subint_recortada = Mid(texto,i,Len(texto))
		'MsgBox Caracter & " " & IsNumeric(Caracter) & " " & Subint_recortada
		if IsNumeric(Caracter) =  True then
			exit for
		end if
	Next
	
	Recortar_SUBINTERFACE = Subint_recortada
End Function
	 