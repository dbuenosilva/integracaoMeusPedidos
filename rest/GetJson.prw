#INCLUDE "TOTVS.CH"

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � GetJson � Autor � Diego Bueno            � Data � 12/06/18 ���
�������������������������������������������������������������������������Ĵ��
���Locacao   � GWAYA            �Contato � diego@gwaya.com                ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Realiza HttpGet em WebService MeusPedidos.                 ���
���          �                                      			          ���
�������������������������������������������������������������������������Ĵ��
���Parametros� NIL                                                        ���
�������������������������������������������������������������������������Ĵ��
���Retorno   � NIL                                                        ���
�������������������������������������������������������������������������Ĵ��
���Aplicacao � SIGAFAT                                                    ���
�������������������������������������������������������������������������Ĵ��
���Uso       � Integracao Protheus x MeusPedidos                          ���
�������������������������������������������������������������������������Ĵ��
���Analista Resp.�  Data  � Bops � Manutencao Efetuada                    ���
�������������������������������������������������������������������������Ĵ��
���              �  /  /  �      �                                        ���
���              �  /  /  �      �                                        ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/

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
	sGetRet     := EnCodeUtf8(u_GwTiraGraf(AllTrim(oRestClient:GetResult())))
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
		cMsg := "GetJson: Falha de comunicacao com API, resposta inv�lida do HttpGet " + cUrlRoot + cUrlBase

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