#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  fSincCondicoesPgto  ºAutor ³Diego Buenoº Data ³   15/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Sincroniza Condicoes de Pagamentos com MeusPedidos         º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Protheus x MeusPedidos.com.br                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function fSincCondicoesPgto(lJob)
	Local cURLBase      := ""
	Local lGetDtime     := ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cE4_XULTAL    := ""
	Local cNewDtMod		:= ""
	Local oCondicao     := nil
	Local aHttpGet      := {}
	Local aHttpPost     := {}
	Local aHttpPut      := {}		
	Local cId           := ''

	Private cEol	    := chr(13)+chr(10)
	Private cMailResp   := ""
	Private cSGBD       := ""

	Default lJob        := .F.

	If ! lJob  .And. Select("SX2") == 0 // Via JOB
		lJob := .T.
	endif

	if lJob	
		RpcSetType(3)	
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SX5" //USER "Admin" PASSWORD "senha"	
	endif

	u_GwLog("meuspedidos.log","fSincCondicoesPgto: Iniciando sincronizacao das Condicoes de Pagamento...")

	cURLBase      := Alltrim( GetMV("MV_XMPCOND",,"") )
	lGetDtime     := GetMV("MV_XGETDTI",,.F.)
	cE4_XULTAL    := AllTrim(GetMV("E4_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de tabela de precos do Protheus para serem atualizados em Meus Pedidos  
	cQuery := " SELECT E4_CODIGO AS CODIGO, " 
	cQuery += "	E4_XIDMPED AS id, "
	cQuery += "	E4_DESCRI as nome, "
	cQuery += "	'0' AS valor_minimo, " 
	cQuery += "	E4_XULTALT AS ultima_alteracao, "
	cQuery += "	CASE WHEN SE4.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido " 		
	cQuery += " FROM " + RetSQLName("SE4") + " SE4 " 	
	cQuery += " WHERE (E4_XULTALT = ' ' OR E4_XULTALT > '" + cE4_XULTAL + "') "
	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\condicao.txt",cQuery)

	if Select("CONDICAO") > 0
		CONDICAO->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "CONDICAO"

	dbSelectArea("CONDICAO")
	CONDICAO->(dbGoTop())

	While ! CONDICAO->( EOF() )

		if ! Empty(CONDICAO->ID)

			if lGetDtime

				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(CONDICAO->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @oCondicao )

						if  Empty(CONDICAO->ultima_alteracao) ;
						.Or. AllTrim(CONDICAO->ultima_alteracao) > AllTrim(oCondicao:ultima_alteracao)  

							// Altera cabecalho das tabelas de precos em Meus Pedidos																		
							cJson := '{'
							//cJson := '        "id": ' + AllTrim(TABCAB->ID),
							cJson += '        "nome": "' + u_GwTiraGraf(CONDICAO->nome) + '",'
							cJson += '        "valor_minimo": 0 ,' 			
							//cJson += '        "ultima_alteracao": "' + AllTrim(CONDICAO->ULTIMA_ALTERACAO) + '",'
							cJson += '        "excluido": ' + AllTrim(CONDICAO->excluido) + ' '			
							cJson += '}'	

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(CONDICAO->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								If tcsqlexec(cQuery) < 0
									cHtml := "fSincCondicoesPgto: Falha ao atualizar data ultima alteracao da Condicao de Pagamento: " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(CONDICAO->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao cabec tabela
								cHtml := "fSincCondicoesPgto: Falha ao atualizar alteracao da Condicao de Pagamento: " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(CONDICAO->NOME) + " na API" 
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "fSincCondicoesPgto: Erro ao processar FWJsonDeserialize do Cabecalho da Tabela de Preco " ;
						+  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(CONDICAO->NOME) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em tabelas que ja existe na api
					cHtml := "fSincCondicoesPgto: Falha obter o Condicao para atualizacao: " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(condicao->NOME) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)																																
				endif

			else

				// Altera cabecalho das tabelas de precos em Meus Pedidos																		
				cJson := '{'
				//cJson := '        "id": ' + AllTrim(TABCAB->ID),
				cJson += '        "nome": "' + u_GwTiraGraf(CONDICAO->nome) + '",'
				cJson += '        "valor_minimo": 0 ,' 			
				//cJson += '        "ultima_alteracao": "' + AllTrim(CONDICAO->ULTIMA_ALTERACAO) + '",'
				cJson += '        "excluido": ' + AllTrim(CONDICAO->excluido) + ' '			
				cJson += '}'	

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(CONDICAO->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If "200" $ cCodHttp 		

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincCondicoesPgto: Falha ao atualizar data ultima alteracao da Condicao de Pagamento: " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(CONDICAO->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao cabec tabela
					cHtml := "fSincCondicoesPgto: Falha ao atualizar alteracao da Condicao de Pagamento: " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(CONDICAO->NOME) + " na API" 
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif	


			endif
		else

			cJson := '{'
			//cJson := '        "id": ' + AllTrim(TABCAB->ID),
			cJson += '        "nome": "' + u_GwTiraGraf(CONDICAO->nome) + '",'
			cJson += '        "valor_minimo": 0 ,' 			
			cJson += '        "ultima_alteracao": "' + AllTrim(CONDICAO->ULTIMA_ALTERACAO) + '",'
			cJson += '        "excluido": ' + AllTrim(CONDICAO->excluido) + ' '			
			cJson += '}'	

			MemoWrite("C:\temp\condicao.json",cJson)

			// Inclui nova tabela em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If "201" $ cCodHttp .And. ! Empty(cId)		

				cQuery := "UPDATE "+RetSQLName("SE4")+" "
				cQuery += " SET E4_XULTALT = '" + cNewDtMod + "' , E4_XIDMPED = '" + u_GwTiraGraf(cId) + "'								
				cQuery += "  WHERE E4_CODIGO = '" + CONDICAO->CODIGO + "' "  

				If tcsqlexec(cQuery) < 0
					cHtml := "fSincCondicoesPgto: Falha ao atualizar o campo ID no ERP da Condicao de Pagamento inclusa:  " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(condicao->NOME) + " "   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif	

				// Deleta em Meus Pedidos												
				//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABCAB->ID), cJson)

			else
				// enviar email falha de inclusao tabela de preco
				cHtml := "fSincCondicoesPgto: Erro ao processar retorno da inclusao da Condicao de Pagamento:  " +  AllTrim(CONDICAO->CODIGO) + " - " + AllTrim(condicao->NOME) + " "    
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		CONDICAO->( DbSkip() )

	End

	if ! Empty(cNewDtMod)
		PutMV("E4_XULTALT",u_fValidTime(cNewDtMod)) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincCondicoesPgto: Finalizada sincronizacao das Condicoes de Pagamento. Ultima sincronizacao " + GetMV("E4_XULTALT",,"") )
	CONDICAO->( DbCloseArea() )
	FreeObj(oCondicao)
Return
