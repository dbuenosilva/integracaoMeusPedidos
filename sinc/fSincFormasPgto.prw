#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  fSincFormasPgto ºAutor ³Diego Bueno    º Data ³   22/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Sincroniza Cadastro de Formas de Pagamentos                º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Protheus x MeusPedidos.com.br                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function fSincFormasPgto(lJob)
	Local cURLBase      := ""
	Local lGetDtime     := ""	
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cX5_XULTFOR   := ""
	Local cNewDtMod		:= ""
	Local oFormas       := nil
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

	u_GwLog("meuspedidos.log","fSincFormasPgto: Iniciando sincronizacao das Formas de Pagamentos...")
	cURLBase      := Alltrim( GetMV("MV_XMPFORM",,"") )
	lGetDtime     := GetMV("MV_XGETDTI",,.F.)	
	cX5_XULTFOR   := AllTrim(GetMV("X5_XULTFOR",,"")) // Obtem a ultima data/hora de sincronizacao	
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de Formas de clientes do Protheus para serem atualizados em Meus Pedidos  
	cQuery += "		SELECT X5_CHAVE, X5_DESCRI as nome, X5_DESCENG as ultima_alteracao, X5_DESCSPA as id, "	 
	cQuery += "			CASE WHEN D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido  "	
	cQuery += "		FROM " + RetSQLName("SX5") + "  SX5 "  
	cQuery += "		WHERE  X5_TABELA = '24' AND (X5_DESCENG = '.' OR X5_DESCENG > '" + cX5_XULTFOR + "') " 

	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\Formas.txt",cQuery)

	//X5_CHAVE nome                                                                                            id                                                      excluido

	if Select("Formas") > 0
		Formas->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "Formas"

	dbSelectArea("Formas")
	Formas->(dbGoTop())

	While ! Formas->( EOF() )

		if ! Empty(Formas->ID) .And. Formas->ID <> '.' 

			if lGetDtime

				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(Formas->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @oFormas )

						if  Empty(Formas->ultima_alteracao) .Or.  AllTrim(Formas->ultima_alteracao) == '.' ;
						.Or. AllTrim(Formas->ultima_alteracao) > AllTrim(oFormas:ultima_alteracao)  

							// Altera Formas em Meus Pedidos																		
							cJson := '{ '					
							cJson += '"nome": "' + u_GwTiraGraf(Formas->nome) + '", '						
							cJson += '"excluido":' + AllTrim(Formas->excluido) + ''
							cJson += '}'

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(Formas->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								// Deve-se atualizar tambem registro deletados							
								cQuery := "UPDATE "+RetSQLName("SX5")+" "
								cQuery += " SET X5_DESCENG = '"+cNewDtMod+"' "						
								cQuery += "  WHERE  X5_TABELA = '24' AND X5_DESCSPA = '" + AllTrim(Formas->ID) +"' "

								If tcsqlexec(cQuery) < 0
									cHtml := "fSincFormasPgto: Falha ao atualizar data ultima alteracao da Forma de Pagamento: " +  AllTrim(Formas->ID) + " - " + AllTrim(Formas->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao Formas
								cHtml := "fSincFormasPgto: Falha ao atualizar alteracao dA Forma de Pagamento: " +  AllTrim(Formas->ID) + " - " + AllTrim(Formas->NOME) + " na API"  
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "fSincFormasPgto: Erro ao processar FWJsonDeserialize dA Formas dA Pagamento " ;
						+  AllTrim(Formas->id) + " - " + AllTrim(Formas->NOME) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em Formas que ja existe na api
					cHtml := "fSincFormasPgto: Falha obter A Forma de Pagamento para atualizacao: " +  AllTrim(Formas->id) + " - " + AllTrim(Formas->NOME) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)																																
				endif
			else
				// Altera Formas em Meus Pedidos																		
				cJson := '{ '					
				cJson += '"nome": "' + u_GwTiraGraf(Formas->nome) + '", '						
				cJson += '"excluido":' + AllTrim(Formas->excluido) + ''
				cJson += '}'

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(Formas->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If "200" $ cCodHttp 		

					// Deve-se atualizar tambem registro deletados							
					cQuery := "UPDATE "+RetSQLName("SX5")+" "
					cQuery += " SET X5_DESCENG = '"+cNewDtMod+"' "						
					cQuery += "  WHERE  X5_TABELA = '24' AND X5_DESCSPA = '" + AllTrim(Formas->ID) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincFormasPgto: Falha ao atualizar data ultima alteracao da Forma de Pagamento: " +  AllTrim(Formas->ID) + " - " + AllTrim(Formas->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao Formas
					cHtml := "fSincFormasPgto: Falha ao atualizar alteracao dA Forma de Pagamento: " +  AllTrim(Formas->ID) + " - " + AllTrim(Formas->NOME) + " na API"  
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif												

			endif
		else

			cJson := '{ '
			//	cJson += '"ultima_alteracao":"' + AllTrim(Formas->ULTIMA_ALTERACAO) + '",'
			cJson += '"excluido":' + AllTrim(Formas->excluido) + ','
			//			cJson += '"id": ' + u_GwTiraGraf(Formas->id) + ' '
			cJson += '"nome": "' + u_GwTiraGraf(Formas->nome) + '" ' 
			cJson += '}'

			// Inclui nova Forma em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If "201" $ cCodHttp .And. ! Empty(cId)		

				cQuery := "UPDATE "+RetSQLName("SX5")+" "  
				cQuery += " SET X5_DESCENG = '" + cNewDtMod + "', X5_DESCSPA = '" + u_GwTiraGraf(cId) + "' "							
				cQuery += "  WHERE  X5_TABELA = '24' AND  X5_DESCRI = '" + AllTrim(Formas->nome) +"' " 

				If tcsqlexec(cQuery) < 0
					cHtml := "fSincFormasPgto: Falha ao atualizar o campo ID no ERP da Forma de Pagamento inclusa: " +  AllTrim(Formas->id) + " - " + AllTrim(Formas->NOME) + " "   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif	

				// Deleta em Meus Pedidos												
				//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(Formas->ID), cJson)

			else
				// enviar email falha de inclusao Forma
				cHtml := "fSincFormasPgto: Erro ao processar retorno da inclusao da Forma de Pagamento: " +  AllTrim(Formas->id) + " - " + AllTrim(Formas->NOME)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		Formas->( DbSkip() )

	End

	if ! Empty(cNewDtMod)
		PutMV("X5_XULTFOR",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincFormasPgto: Finalizada sincronizacao da Formas de Pagamento. Ultima sincronizacao " + GetMV("X5_XULTFOR",,"") )
	Formas->(DbCloseArea())
	FreeObj(oFormas)
Return