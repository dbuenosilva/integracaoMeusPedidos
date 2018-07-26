#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  fSincSegmentosºAutor ³Diego Bueno      º Data ³   14/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Sincroniza Cadastro Segmento de Clientes                   º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Protheus x MeusPedidos.com.br                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function fSincSegmentos(lJob)
	Local cURLBase      := ""
	Local lGetDtime     := ""	
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cX5_XULTALT   := ""
	Local cNewDtMod		:= ""
	Local oSegmento     := nil
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

	u_GwLog("meuspedidos.log","FAT005: Iniciando sincronizacao dos segmento de clientes...")

	cURLBase      := Alltrim( GetMV("MV_XMPSEGM",,"") )
	lGetDtime     := GetMV("MV_XGETDTI",,.F.)	
	cX5_XULTALT   := AllTrim(GetMV("X5_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de segmentos de clientes do Protheus para serem atualizados em Meus Pedidos  
	cQuery += "		SELECT X5_CHAVE, X5_DESCRI as nome, X5_DESCENG as ultima_alteracao, X5_DESCSPA as id, "	 
	cQuery += "			CASE WHEN D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido  "	
	cQuery += "		FROM " + RetSQLName("SX5") + "  SX5 "  
	cQuery += "		WHERE  X5_TABELA = 'T3' AND ( X5_DESCENG = '.' OR X5_DESCENG > '" + cX5_XULTALT + "') " 

	//cQuery := ChangeQuery(cQuery)
	//MemoWrite("C:\temp\SEGMENTOS.txt",cQuery)

	//X5_CHAVE nome                                                                                            id                                                      excluido

	if Select("SEGMENTOS") > 0
		SEGMENTOS->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "SEGMENTOS"

	dbSelectArea("SEGMENTOS")
	SEGMENTOS->(dbGoTop())

	While ! SEGMENTOS->( EOF() )

		if ! Empty(SEGMENTOS->ID) .AND.  SEGMENTOS->ID <> '.'

			if lGetDtime

				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(SEGMENTOS->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @oSegmento )

						if  Empty(SEGMENTOS->ultima_alteracao) .Or. ;
						(AllTrim( SEGMENTOS->ultima_alteracao)) == '.' .Or. ;
						AllTrim(SEGMENTOS->ultima_alteracao) > AllTrim(oSegmento:ultima_alteracao)  

							// Altera segmentos de clientes em Meus Pedidos																		
							cJson := '{ '					
							cJson += '"nome": "' + u_GwTiraGraf(SEGMENTOS->nome) + '", '						
							cJson += '"excluido":' + AllTrim(SEGMENTOS->excluido) + ''
							cJson += '}'

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(SEGMENTOS->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								// Deve-se atualizar tambem registro deletados							
								cQuery := "UPDATE "+RetSQLName("SX5")+" "
								cQuery += " SET X5_DESCENG = '"+cNewDtMod+"' "						
								cQuery += "  WHERE  X5_TABELA = 'T3' AND X5_DESCSPA = '" + AllTrim(SEGMENTOS->ID) +"' "

								If tcsqlexec(cQuery) < 0
									cHtml := "FAT005A: Falha ao atualizar data ultima alteracao segmento: " +  AllTrim(SEGMENTOS->ID) + " - " + AllTrim(SEGMENTOS->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao SEGMENTO
								cHtml := "FAT005A: Falha ao atualizar alteracao do segmento: " +  AllTrim(SEGMENTOS->ID) + " - " + AllTrim(SEGMENTOS->NOME) + " na API"  
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "FAT005A: Erro ao processar FWJsonDeserialize do segmento " ;
						+  AllTrim(SEGMENTOS->id) + " - " + AllTrim(SEGMENTOS->NOME) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em segmentos que ja existe na api
					cHtml := "FAT005A: Falha obter o segmento para atualizacao: " +  AllTrim(SEGMENTOS->id) + " - " + AllTrim(SEGMENTOS->NOME) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)																																
				endif

			else

				// Altera segmentos de clientes em Meus Pedidos																		
				cJson := '{ '					
				cJson += '"nome": "' + u_GwTiraGraf(SEGMENTOS->nome) + '", '						
				cJson += '"excluido":' + AllTrim(SEGMENTOS->excluido) + ''
				cJson += '}'

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(SEGMENTOS->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If "200" $ cCodHttp 		

					// Deve-se atualizar tambem registro deletados							
					cQuery := "UPDATE "+RetSQLName("SX5")+" "
					cQuery += " SET X5_DESCENG = '"+cNewDtMod+"' "						
					cQuery += "  WHERE  X5_TABELA = 'T3' AND X5_DESCSPA = '" + AllTrim(SEGMENTOS->ID) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "FAT005A: Falha ao atualizar data ultima alteracao segmento: " +  AllTrim(SEGMENTOS->ID) + " - " + AllTrim(SEGMENTOS->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao SEGMENTO
					cHtml := "FAT005A: Falha ao atualizar alteracao do segmento: " +  AllTrim(SEGMENTOS->ID) + " - " + AllTrim(SEGMENTOS->NOME) + " na API"  
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif												


			endif

		else

			cJson := '{ '
			cJson += '"ultima_alteracao":"' + AllTrim(SEGMENTOS->ULTIMA_ALTERACAO) + '",'
			cJson += '"excluido":' + AllTrim(SEGMENTOS->excluido) + ','
			//			cJson += '"id": ' + u_GwTiraGraf(SEGMENTOS->id) + ' '
			cJson += '"nome": "' + u_GwTiraGraf(SEGMENTOS->nome) + '" ' 
			cJson += '}'

			// Inclui novo SEGMENTO em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If "201" $ cCodHttp .And. ! Empty(cId)		

				cQuery := "UPDATE "+RetSQLName("SX5")+" "  
				cQuery += " SET X5_DESCENG = '" + cNewDtMod + "', X5_DESCSPA = '" + u_GwTiraGraf(cId) + "' "							
				cQuery += "  WHERE  X5_TABELA = 'T3' AND  X5_DESCRI = '" + AllTrim(SEGMENTOS->nome) +"' " 

				If tcsqlexec(cQuery) < 0
					cHtml := "FAT005A: Falha ao atualizar o campo ID no ERP de segmento incluso: " +  AllTrim(SEGMENTOS->id) + " - " + AllTrim(SEGMENTOS->NOME) + " "   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif	

				// Deleta em Meus Pedidos												
				//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(SEGMENTOS->ID), cJson)

			else
				// enviar email falha de inclusao segmento
				cHtml := "FAT005A: Erro ao processar retorno da inclusao de segmento: " +  AllTrim(SEGMENTOS->id) + " - " + AllTrim(SEGMENTOS->NOME)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		SEGMENTOS->( DbSkip() )

	End

	if ! Empty(cNewDtMod)
		PutMV("X5_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","FAT005: Finalizada sincronizacao dos segmentos de cliente. Ultima sincronizacao " + GetMV("X5_XULTALT",,"") )
	SEGMENTOS->(DbCloseArea())
	FreeObj(oSegmento)
Return
