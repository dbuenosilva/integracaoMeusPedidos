#INCLUDE "TOTVS.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ PostJson ³ Autor ³ Diego Bueno           ³ Data ³ 12/06/18 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Locacao   ³ GWAYA            ³Contato ³ diego@gwaya.com                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Realiza HttpPost em WebService MeusPedidos.                ³±±
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

User Function PostJson(cUrlBase,cJson)
	Local cUrlRoot := AllTrim(GetMV("MV_XMPURLB",,""))
	Local nTimeOut := GetMV("MV_XTIMEOU",,120)
	Local lGetDtime:= GetMV("MV_XGETDTI",,.F.)
	Local aHeader  := {}
	Local cHeadRet := ""
	Local cHttpCod := ""
	Local sPostRet := " { } " 
	Local cNewID   := "" 
	Local cParam   := ""
	Local cCompany_Token    := AllTrim(GetMV("MV_XMPCOTK",,""))
	Local cApplicationToken := AllTrim(GetMV("MV_XMPAPTK",,""))
	Local cHeaderRet := ''
	Local cDateRet   := ''
	Local oRestClient
	Local oRegistro
	Local cMsg    := ""
	Local cEOL 	  := CHR(13) + CHR(10)

	Default cUrlBase := ""
	Default cJson    := ""    

	if Empty(cUrlBase)
		u_GwLog("meuspedidos.log","PostJson: Falha de comunicacao com API, URL Base vazia " +  cUrlRoot + cUrlBase)   
	endif

	///******************************************************* //
	// Montagem do Header para o HTTPost                       //      
	///******************************************************* // 
	aHeader := {}
	Aadd(aHeader, "ApplicationToken: " + cApplicationToken)
	Aadd(aHeader, "CompanyToken: " + cCompany_Token)
	Aadd(aHeader, "Content-Type: application/json" ) /* application/x-www-form-urlencoded" */ 

	///******************************************************* //
	// Montagem do HTTPost                                      //      
	///******************************************************* // 
	oRestClient := FWRest():New(cUrlRoot + cUrlBase)
	oRestClient:SetPostParams(cJson)
	oRestClient:setPath("")
	oRestClient:Post(aHeader)	

	sPostRet    := EnCodeUtf8(AllTrim(oRestClient:GetResult()))
	cHeaderRet  := oRestClient:ORESPONSEH:CREASON
	cHttpCod    := oRestClient:ORESPONSEH:CSTATUSCODE

	// Tratamento Throttling
	if cHttpCod == "429" //TOO MANY REQUESTS

		u_GwLog("meuspedidos.log","PostJson: API bloqueou conexoes por Throttling... ")

		if FWJsonDeserialize(sPostRet, @oRegistro ) .And. Type( "oRegistro:tempo_ate_permitir_novamente") == "N"						
			sleep(oRegistro:tempo_ate_permitir_novamente * 1000)
		endif

		nTentativas    := 0
		While cHttpCod == "429" .And. nTentativas <= GetMV("MV_XTHROTT",,10)

			oRestClient:Post(aHeader)	

			sPostRet    := EnCodeUtf8(AllTrim(oRestClient:GetResult()))
			cHeaderRet  := oRestClient:ORESPONSEH:CREASON
			cHttpCod    := oRestClient:ORESPONSEH:CSTATUSCODE

			if FWJsonDeserialize(sPostRet, @oRegistro ) .And. Type( "oRegistro:tempo_ate_permitir_novamente") == "N"						
				sleep(oRegistro:tempo_ate_permitir_novamente * 1000)
			endif
			
			nTentativas++
		End

		u_GwLog("meuspedidos.log","PostJson: API liberou novas conexoes devido ocorrencia de Throttling... ")

	endif

	if cHttpCod == "201" .Or. cHttpCod == "200"  	

		u_GwLog("meuspedidos.log","PostJson: Ok! " + cJson)

		cNewID := ""        

		For _y:= 1 to len(oRestClient:oResponseH:aHeaderFields)
			if alltrim(oRestClient:oResponseH:aHeaderFields[_y][1]) == "MeusPedidosID"
				if ! Empty(oRestClient:oResponseH:aHeaderFields[_y][2])
					cNewID := alltrim(oRestClient:oResponseH:aHeaderFields[_y][2])
				endif
			endif

			if Empty(cDateRet) .And. alltrim(oRestClient:oResponseH:aHeaderFields[_y][1]) == "Date" //"Wed, 13 Jun 2018 14:03:14 GMT\r"
				if ! Empty(oRestClient:oResponseH:aHeaderFields[_y][2])
					cDateRet := alltrim(oRestClient:oResponseH:aHeaderFields[_y][2])						
					cDateRet := u_GwSubDTime(cDateRet,'3.0')// converte hora GMT retornada para GMT-3
				endif
			endif            

			if lGetDtime .And. ! Empty(cNewID) 

				//Obtem data de alteracao do registro
				if FWJsonDeserialize( u_GetJson( cUrlBase + "/" + AllTrim(cNewID) )[1] , @oRegistro ) ;
				.And. Type( "oRegistro") == "O" .And. Type( "oRegistro:ultima_alteracao"  ) == "C"
					cDateRet := AllTrim(oRegistro:ultima_alteracao)
				else
					u_GwLog("meuspedidos.log","PostJson: Falha em obter ultima_alteracao, sera assumido datatime retorno do HttPost " )						
				endif
			endif	

			if ! Empty(cNewID) .And. ! Empty(cDateRet)
				exit
			endif
		next

		if ! Empty(cNewID)  .Or.  cHttpCod == "200"
			u_GwLog("meuspedidos.log","PostJson: HttpCode => " + cHttpCod )
			u_GwLog("meuspedidos.log","PostJson: Message  => " + cHeaderRet )	  
			u_GwLog("meuspedidos.log","PostJson: Body     => " + sPostRet)
		endif

	Else
		cMsg := "PostJson: Falha de comunicacao com API, resposta inválida do HttpPost " + cUrlRoot + cUrlBase + cEOL + cEOL ;
			+ " Erro Retornado: " + sPostRet + cEOL + cEOL //;
			//+ " Json Enviado: " + cJson
					
		u_fGravaMeusPedidos( { "PostJson", cHttpCod, u_GwTiraGraf(sPostRet),u_GwTiraGraf(cHeaderRet),cNewID,cDateRet,u_GwTiraGraf(cMsg),.F.} )
		
		u_GwLog("meuspedidos.log", cMsg + ;
		" HttpCode: " + iif ( Valtype(cHttpCod) == "C",cHttpCod,"" ) + ;
		" Error: " + iif ( Valtype(cHeaderRet) == "C",cHeaderRet,"" ) + ;
		" Result: " + iif ( Valtype(sPostRet) == "C", sPostRet,"" ) )
		sPostRet := " { } "

	EndIf

	FreeObj(oRestClient)
	FreeObj(oRegistro)

Return( { IIF (sPostRet == "C", sPostRet,"" ), iif ( Valtype(cHeaderRet) == "C", cHeaderRet,"" ),  iif ( Valtype(cHttpCod) == "C", cHttpCod,"" ), iif ( Valtype(cNewID) == "C", cNewID,"" ), iif ( Valtype(cDateRet) == "C", cDateRet,"" ) , iif ( Valtype(cMsg) == "C", cMsg,"" ) }  )
