#INCLUDE "TOTVS.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ GetJson ³ Autor ³ Diego Bueno            ³ Data ³ 12/06/18 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Locacao   ³ GWAYA            ³Contato ³ diego@gwaya.com                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Realiza HttpGet em WebService MeusPedidos.                 ³±±
±±³          ³                                      			          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ NIL                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ NIL                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Aplicacao ³ SIGAFAT                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Integracao Protheus x MeusPedidos                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Analista Resp.³  Data  ³ Bops ³ Manutencao Efetuada                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³              ³  /  /  ³      ³                                        ³±±
±±³              ³  /  /  ³      ³                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function GetJson(cUrlBase)
	Local cUrlRoot := AllTrim(GetMV("MV_XMPURLB",,""))
	Local nTimeOut := GetMV("MV_XTIMEOU",,120)
	Local aHeader  := {}
	Local cHeadRet := ""
	Local cHttpCod := ""
	Local sGetRet  := " { } "  
	Local cParam   := ""
	Local cCompany_Token    := AllTrim(GetMV("MV_XMPCOTK",,""))
	Local cApplicationToken := AllTrim(GetMV("MV_XMPAPTK",,""))
	Local cHeaderRet := ''
	Local oRestClient
	Local oRegistro
	Local nTentativas := 0

	Default cUrlBase := ""

	if Empty(cUrlBase)
		u_GwLog("meuspedidos.log","GetJson: Falha de comunicacao com API, URL Base vazia " +  cUrlRoot + cUrlBase)   
	endif

	///******************************************************* //
	// Montagem do Header para o HTTGet                       //      
	///******************************************************* // 
	aHeader := {}
	Aadd(aHeader, "ApplicationToken: " + cApplicationToken)
	Aadd(aHeader, "CompanyToken: " + cCompany_Token)
	Aadd(aHeader, "Content-Type: application/json" ) /* application/x-www-form-urlencoded" */ 
	//Aadd(aHeader, "CompanyToken: 3cd63eae-423d-11e8-9079-4648aa0f2037")
	//Aadd(aHeader, "Content-Type: application/json" ) /* application/x-www-form-urlencoded" */ 

	///******************************************************* //
	// Montagem do HTTGet                                      //      
	///******************************************************* // 
	oRestClient := FWRest():New(cUrlRoot + cUrlBase)
	oRestClient:setPath("")
	oRestClient:Get(aHeader) 
	sGetRet     := EnCodeUtf8(fGTiraGraf(AllTrim(oRestClient:GetResult())))
	cHeaderRet  := oRestClient:ORESPONSEH:CREASON
	cHttpCod    := oRestClient:ORESPONSEH:CSTATUSCODE

	// Tratamento Throttling
	if cHttpCod == "429" //TOO MANY REQUESTS

		u_GwLog("meuspedidos.log","GetJson: API bloqueou conexoes por Throttling... ")

		if FWJsonDeserialize(sGetRet, @oRegistro ) .And.  Type( "oRegistro:tempo_ate_permitir_novamente" ) == "N"						
			sleep(oRegistro:tempo_ate_permitir_novamente * 1000)
		endif

		nTentativas    := 0
		While cHttpCod == "429" .And. nTentativas <= GetMV("MV_XTHROTT",,10)

			oRestClient:Get(aHeader)	

			sGetRet     := EnCodeUtf8(u_GwTiraGraf(AllTrim(oRestClient:GetResult())))
			cHeaderRet  := oRestClient:ORESPONSEH:CREASON
			cHttpCod    := oRestClient:ORESPONSEH:CSTATUSCODE

			if FWJsonDeserialize(sGetRet, @oRegistro ) .And. Type( "oRegistro:tempo_ate_permitir_novamente" ) == "N"						
				sleep(oRegistro:tempo_ate_permitir_novamente * 1000)
			endif

			nTentativas++
		End

		u_GwLog("meuspedidos.log","GetJson: API liberou novas conexoes devido ocorrencia de Throttling... ")

	endif

	if cHttpCod == "200"		
		u_GwLog("meuspedidos.log","GetJson: HttpCode => " + cHttpCod )
		u_GwLog("meuspedidos.log","GetJson: Message  => " + cHeaderRet )	  
		u_GwLog("meuspedidos.log","GetJson: Body     => "  + sGetRet)
	Else
		cMsg := "GetJson: Falha de comunicacao com API, resposta inválida do HttpGet " + cUrlRoot + cUrlBase

		u_fGravaMeusPedidos( { "GetJson", cHttpCod, sGetRet,cHeaderRet,"","",cMsg,.F.} )

		u_GwLog("meuspedidos.log",cMsg + ;	
		" HttpCode: " + iif ( Valtype(cHttpCod) == "C",cHttpCod,"" ) + ;
		" Error: " + iif ( Valtype(cHeaderRet) == "C",cHeaderRet,"" ) + ;
		" Result: " + iif ( Valtype(sGetRet) == "C", sGetRet,"" ) )	
		sGetRet := " { } "    
	EndIf

	FreeObj(oRestClient)
	FreeObj(oRegistro)
Return( { iif ( Valtype(sGetRet) == "C", sGetRet,"" ), iif ( Valtype(cHeaderRet) == "C",cHeaderRet,"" ), iif ( Valtype(cHttpCod) == "C",cHttpCod,"" ) }  )

static function fGTiraGraf(sOrig)
	local sRet 	  := ""  
	Default sOrig := "" 
	
	sRet := DecodeUtf8(sOrig)
	
	sRet := strtran (sRet, "·", " ")
	sRet := strtran (sRet, "È", "E")
	sRet := strtran (sRet, "Ì", "I")
	sRet := strtran (sRet, "Û", "U")
	// sRet := strtran (sRet, "?", " ")
	sRet := sTRTRAN (sRet, "¡", "i")
	sRet := sTRTRAN (sRet, "…", " ")
	sRet := sTRTRAN (sRet, "Õ", "O")
	sRet := sTRTRAN (sRet, "”", " ")
	sRet := sTRTRAN (sRet, "/", "-")
	sRet := strtran (sRet, "„", " ")
	sRet := sTRTRAN (sRet, "’", " ")
	sRet := strtran (sRet, "‚", " ")
	sRet := strtran (sRet, "Í", "i")
	sRet := strtran (sRet, "Ó", "o")
	sRet := strtran (sRet, "Ù", "o")
	sRet := strtran (sRet, "°", " ")
	sRet := sTRTRAN (sRet, "¬", " ")
	sRet := sTRTRAN (sRet, "Œ", " ")
	sRet := sTRTRAN (sRet, "‘", " ")
	sRet := sTRTRAN (sRet, "€", " ")
	sRet := strtran (sRet, "Á", "A")
	sRet := strtran (sRet, "«", " ")
	sRet := strtran (sRet, "‡", " ")
	sRet := strtran (sRet, "¿", " ")
	//   sRet := strtran (sRet, "?", ".")
	sRet := strtran (sRet, "™", " ")
//	sRet := strtran (sRet, "'", " ")// Aspas simples
//	sRet := strtran (sRet, chr(39), " ") // Aspas simples
//	sRet := strtran (sRet, '"', " ")// Aspas duplas
//	sRet := strtran (sRet, chr(34), " ")// Aspas duplas           
	sRet := strtran (sRet,"\t", " ")    // TAB
	sRet := strtran (sRet,"\u0009", " ")  //TAB   
	sRet := strtran (sRet, chr(13) + chr(10), " ") // EOL        
	sRet := strtran (sRet,"\n", " ")  // EOL
	sRet := strtran (sRet,"\r", " ")// EOL  
	sRet := strtran (sRet,chr(96), " ")//	crase `   

	// Demais caractes ASCII
	/*
	sRet := strtran (sRet, chr(0), " ")//	NUL (null)	==> limpa a string
	*/
	sRet := strtran (sRet, chr(1), " ")//	SOH (start of heading)
	sRet := strtran (sRet, chr(2), " ")// STX (start of text)	
	sRet := strtran (sRet, chr(3), " ")//	ETX (end of text)	
	sRet := strtran (sRet, chr(4), " ")//	EOT (end of transmission)	
	sRet := strtran (sRet, chr(5), " ")//	ENQ (enquiry)	
	sRet := strtran (sRet, chr(6), " ")//	ACK (acknowledge)	
	sRet := strtran (sRet, chr(7), " ")//	BEL (bel)	
	sRet := strtran (sRet, chr(8), " ")//	BS (backspace)	
	sRet := strtran (sRet, chr(9), " ")//	TAB (horizontal tab)	
	sRet := strtran (sRet, chr(10), " ")// LF (NL line feed, new line)	
	sRet := strtran (sRet, chr(11), " ")// VT (verticle tab)	
	sRet := strtran (sRet, chr(12), " ")// FF (NP form feed, new page)	
	sRet := strtran (sRet, chr(13), " ")// CR (carriage return)	
	sRet := strtran (sRet, chr(14), " ")// SO (shift out)	
	sRet := strtran (sRet, chr(15), " ")// SI (shift in)	
	sRet := strtran (sRet, chr(16), " ")// DLE (data link exchange)	
	sRet := strtran (sRet, chr(17), " ")// DC1 (device control 1)	
	sRet := strtran (sRet, chr(18), " ")// DC2 (device control 2)	
	sRet := strtran (sRet, chr(19), " ")// DC3 (device control 3)	
	sRet := strtran (sRet, chr(20), " ")// DC4 (device control 4)	
	sRet := strtran (sRet, chr(21), " ")// NAK (negitive acknowledge)	
	sRet := strtran (sRet, chr(22), " ")// SYN (synchronous idle)	
	sRet := strtran (sRet, chr(23), " ")// ETB (end of trans. block)
	sRet := strtran (sRet, chr(24), " ")// CAN (cancel)	
	sRet := strtran (sRet, chr(25), " ")// EM (end of medium)	
	sRet := strtran (sRet, chr(26), " ")// SUB (substitute)
	sRet := strtran (sRet, chr(27), " ")// ESC (escape)	
	sRet := strtran (sRet, chr(28), " ")// FS (file separator)	
	sRet := strtran (sRet, chr(29), " ")// GS (group separator)	
	sRet := strtran (sRet, chr(30), " ")// RS (record separator)	
	sRet := strtran (sRet, chr(31), " ")// US (unit separator)   

	sRet := AllTrim(EnCodeUtf8(NoAcento(sRet))) 

return(sRet)