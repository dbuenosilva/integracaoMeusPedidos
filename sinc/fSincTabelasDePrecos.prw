#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincTabelasDePrecos บAutor ณDiego Bueno บ Data ณ 15/06/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Tabelas de Precos com MeusPedidos               บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function fSincTabelasDePrecos(lJob)
	Local cURLBase      := ""
	Local lGetDtime		:= ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cDA0_XULTAL   := ""
	Local cNewDtMod		:= ""
	Local oTabCab       := nil
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

	u_GwLog("meuspedidos.log","FAT005: Iniciando sincronizacao das Tabelas de Precos...")

	cURLBase      := Alltrim( GetMV("MV_XMPTABE",,"") )
	lGetDtime	  := GetMV("MV_XGETDTI",,.F.)
	cDA0_XULTAL   := AllTrim(GetMV("DA0_XULTAL",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de tabela de precos do Protheus para serem atualizados em Meus Pedidos  
	cQuery += "	SELECT DA0_CODTAB as CODIGO, 'null' as acrescimo, "
	cQuery += "			'P' as tipo, "
	cQuery += "			DA0_DESCRI as nome, "
	cQuery += "			DA0_XULTAL as ultima_alteracao, "
	cQuery += "			CASE WHEN DA0.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido, "
	cQuery += "			DA0_XIDMPE as id, "
	cQuery += "			'null' as desconto "
	cQuery += "	FROM " + RetSQLName("DA0") + "  DA0		
	cQuery += "		WHERE DA0_ATIVO <> '2' AND (DA0_XULTAL = ' ' OR DA0_XULTAL > '" + cDA0_XULTAL + "')  

	cQuery += "	        AND  DA0_CODTAB >= '159' " // somentes as novas tabelas 

	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\TABCAB.txt",cQuery)

	if Select("TABCAB") > 0
		TABCAB->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "TABCAB"

	dbSelectArea("TABCAB")
	TABCAB->(dbGoTop())

	While ! TABCAB->( EOF() )

		if ! Empty(TABCAB->ID)

			if lGetDtime

				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(TABCAB->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @oTabCab )

						if  Empty(TABCAB->ultima_alteracao) ;
						.Or. AllTrim(TABCAB->ultima_alteracao) > AllTrim(oTabCab:ultima_alteracao)  

							// Altera cabecalho das tabelas de precos em Meus Pedidos																		
							cJson := '{'					
							cJson += '        "acrescimo": null,'
							cJson += '        "tipo": "P",'
							cJson += '        "nome": "' + u_GwTiraGraf(TABCAB->nome) + '",'
							cJson += '        "ultima_alteracao": "' + AllTrim(TABCAB->ULTIMA_ALTERACAO) + '",'
							cJson += '        "excluido": ' + AllTrim(TABCAB->excluido) + ','
							//cJson := '        "id": ' + AllTrim(TABCAB->ID),
							cJson += '        "desconto": null' 
							cJson += '}'

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABCAB->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								// Deve-se atualizar tambem registro deletados							
								cQuery := "UPDATE "+RetSQLName("DA0")+" "
								cQuery += " SET DA0_XULTAL = '"+cNewDtMod+"' "						
								cQuery += "  WHERE DA0_XIDMPE = '" + AllTrim(TABCAB->ID) +"' "

								If tcsqlexec(cQuery) < 0
									cHtml := "fSincItens: Falha ao atualizar data ultima alteracao do Cabecalho da Tabela de Preco: " +  AllTrim(TABCAB->ID) + " - " + AllTrim(TABCAB->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao cabec tabela
								cHtml := "fSincItens: Falha ao atualizar alteracao do Cabecalho da Tabela de Preco: " +  AllTrim(TABCAB->ID) + " - " + AllTrim(TABCAB->NOME) + " na API"  
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "fSincItens: Erro ao processar FWJsonDeserialize do Cabecalho da Tabela de Preco " ;
						+  AllTrim(TABCAB->id) + " - " + AllTrim(TABCAB->NOME) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em tabelas que ja existe na api
					cHtml := "fSincItens: Falha obter o Cabecalho da Tabela de Preco para atualizacao: " +  AllTrim(TABCAB->id) + " - " + AllTrim(TABCAB->NOME) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)																																
				endif

			else

				// Altera cabecalho das tabelas de precos em Meus Pedidos																		
				cJson := '{'					
				cJson += '        "acrescimo": null,'
				cJson += '        "tipo": "P",'
				cJson += '        "nome": "' + u_GwTiraGraf(TABCAB->nome) + '",'
				cJson += '        "ultima_alteracao": "' + AllTrim(TABCAB->ULTIMA_ALTERACAO) + '",'
				cJson += '        "excluido": ' + AllTrim(TABCAB->excluido) + ','
				//cJson := '        "id": ' + AllTrim(TABCAB->ID),
				cJson += '        "desconto": null' 
				cJson += '}'

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABCAB->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If cCodHttp $ "200/201"		

					// Deve-se atualizar tambem registro deletados							
					cQuery := "UPDATE "+RetSQLName("DA0")+" "
					cQuery += " SET DA0_XULTAL = '"+cNewDtMod+"' "						
					cQuery += "  WHERE DA0_XIDMPE = '" + AllTrim(TABCAB->ID) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincItens: Falha ao atualizar data ultima alteracao do Cabecalho da Tabela de Preco: " +  AllTrim(TABCAB->ID) + " - " + AllTrim(TABCAB->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao cabec tabela
					cHtml := "fSincItens: Falha ao atualizar alteracao do Cabecalho da Tabela de Preco: " +  AllTrim(TABCAB->ID) + " - " + AllTrim(TABCAB->NOME) + " na API"  
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
				endif												


			endif

		else

			cJson := '{'					
			cJson += '        "acrescimo": null,'
			cJson += '        "tipo": "P",'
			cJson += '        "nome": "' + u_GwTiraGraf(TABCAB->nome) + '",'
			cJson += '        "ultima_alteracao": "' + AllTrim(TABCAB->ULTIMA_ALTERACAO) + '",'
			cJson += '        "excluido": ' + AllTrim(TABCAB->excluido) + ','
			//cJson := '        "id": ' + AllTrim(TABCAB->ID),
			cJson += '        "desconto": null' 
			cJson += '}'	

			MemoWrite("C:\temp\tabelacab.json",cJson)

			// Inclui nova tabela em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If  cCodHttp $ "200/201" .And. ! Empty(cId)		

				cQuery := "UPDATE "+RetSQLName("DA0")+" "
				cQuery += " SET DA0_XULTAL = '"+cNewDtMod+"', DA0_XIDMPE = '" + u_GwTiraGraf(cId) + "' 					
				cQuery += "  WHERE DA0_CODTAB = '" + TABCAB->CODIGO + "' "  

				If tcsqlexec(cQuery) < 0
					cHtml := "fSincItens: Falha ao atualizar o campo ID no ERP do Cabecalho da Tabela de Preco incluso: " +  AllTrim(TABCAB->id) + " - " + AllTrim(TABCAB->NOME) + " "   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
				endif	

				// Deleta em Meus Pedidos												
				//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABCAB->ID), cJson)

			else
				// enviar email falha de inclusao tabela de preco
				cHtml := "fSincItens: Erro ao processar retorno da inclusao do Cabecalho da Tabela de Preco: " +  AllTrim(TABCAB->id) + " - " + AllTrim(TABCAB->NOME)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		TABCAB->( DbSkip() )

	End

	if ! Empty(cNewDtMod)
		PutMV("DA0_XULTAL",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","FAT005: Finalizada sincronizacao dos Cabecalhos das Tabelas de Preco. Ultima sincronizacao " + GetMV("DA0_XULTAL",,"") )
	TABCAB->( DbCloseArea() )
	FreeObj(oTabCab)
	
	// Sincroniza Itens das tabelas
	u_fSincItens(lJob)
	
Return



/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincItens       บAutor ณDiego Bueno      บ Data ณ   15/06/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Itens das Itens das de Precos com MeusPedidos   บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function fSincItens(lJob)
	Local cURLBase      := Alltrim( GetMV("MV_XMPTABP",,"") )
	Local lGetDtime		:= GetMV("MV_XGETDTI",,.F.)	
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cDA1_XULTAL   := AllTrim(GetMV("DA1_XULTAL",,"")) // Obtem a ultima data/hora de sincronizacao
	Local cNewDtMod		:= ""
	Local oTABITENS     := nil
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

	u_GwLog("meuspedidos.log","FAT005: Iniciando sincronizacao dos Itens das Tabelas de Precos...")
	cMailResp         := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de Item da Tabela de precos do Protheus para serem atualizados em Meus Pedidos  
	cQuery += "	SELECT DA1_CODTAB as codigo, DA0_XIDMPE as tabela_id, "
	cQuery += "				DA1_XULTAL as ultima_alteracao, "
	cQuery += "				DA1_PRCVEN as preco, "
	cQuery += "				DA1_CODPRO as codProduto, " 	
	cQuery += "				B1_XIDMPED as produto_id, "
	cQuery += "				DA1_XIDMPE as id, "
	cQuery += "				CASE WHEN DA0.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido "
	cQuery += "		FROM " + RetSQLName("DA1") + " DA1 "
	cQuery += "		INNER JOIN " + RetSQLName("DA0") + " DA0 ON DA0_FILIAL = DA1_FILIAL "
	cQuery += "			AND DA0_CODTAB = DA1_CODTAB "
	cQuery += "			AND DA0.D_E_L_E_T_ = DA1.D_E_L_E_T_ "
	cQuery += "		INNER JOIN " + RetSQLName("SB1") + " SB1 ON B1_FILIAL = '" + xFilial("SB1")+ "' "
	cQuery += "			AND SB1.B1_COD = DA1.DA1_CODPRO "
	cQuery += "			AND SB1.D_E_L_E_T_ = DA1.D_E_L_E_T_ "
	cQuery += "		WHERE DA0_ATIVO <> '2' AND DA1_PRCVEN > 0 AND DA0_XIDMPE <> ' ' AND B1_XIDMPED <> ' ' "
	cQuery += "			AND  (DA1_XULTAL = ' ' OR DA1_XULTAL > '" + cDA1_XULTAL + "') "
	cQuery += "	        AND  DA0_CODTAB >= '159' " // somentes as novas tabelas
	cQuery += " GROUP BY DA1_CODTAB, DA0_XIDMPE, DA1_XULTAL, DA1_PRCVEN,"	
	cQuery += "	B1_XIDMPED,DA1_XIDMPE,DA0.D_E_L_E_T_, DA1_CODPRO "
	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\TABITENSITENS.txt",cQuery)

	if Select("TABITENS") > 0
		TABITENS->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "TABITENS"
	TcSetField("TABITENS","preco","N",17,2)

	dbSelectArea("TABITENS")
	TABITENS->(dbGoTop())

	While ! TABITENS->( EOF() )

		if ! Empty(TABITENS->ID)

			if lGetDtime
				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(TABITENS->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @oTABITENS )

						if  Empty(TABITENS->ultima_alteracao) ;
						.Or. AllTrim(TABITENS->ultima_alteracao) > AllTrim(oTABITENS:ultima_alteracao)  

							// Altera cabecalho das Itens das de precos em Meus Pedidos																		
							cJson := '{'						
							cJson += '"tabela_id":' + u_GwTiraGraf(TABITENS->tabela_id) +','
							cJson += '        "ultima_alteracao": "' + AllTrim(TABITENS->ULTIMA_ALTERACAO) + '",'
							cJson += '        "preco": ' + AllTrim(Str(TABITENS->preco)) + ','
							cJson += '        "produto_id": ' + u_GwTiraGraf(TABITENS->produto_id) +','
							//cJson += '        "id": 'u_GwTiraGraf(TABITENS->ID)', '
							cJson += '        "excluido": ' + AllTrim(TABITENS->excluido) 
							cJson += '}'						

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABITENS->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								// Deve-se atualizar tambem registro deletados							
								cQuery := "UPDATE "+RetSQLName("DA1")+" "
								cQuery += " SET DA1_XULTAL = '"+cNewDtMod+"' "						
								cQuery += "  WHERE DA1_XIDMPE = '" + AllTrim(TABITENS->ID) +"' "
								cQuery += "  	AND DA1_CODTAB = '" + TABITENS->codigo + "' AND DA1_CODPRO =  '" + TABITENS->codProduto + "' "

								If tcsqlexec(cQuery) < 0
									cHtml := "fSincItens: Falha ao atualizar data ultima alteracao do Item da Tabela de Preco: " +  AllTrim(TABITENS->ID) + " - " + AllTrim(TABITENS->produto_id) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao cabec Item da Tabela
								cHtml := "fSincItens: Falha ao atualizar alteracao do Item da Tabela de Preco: " +  AllTrim(TABITENS->ID) + " - " + AllTrim(TABITENS->produto_id) + " na API"  
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "fSincItens: Erro ao processar FWJsonDeserialize do Item da Tabela de Preco " ;
						+  AllTrim(TABITENS->id) + " - " + AllTrim(TABITENS->produto_id) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em Itens das que ja existe na api
					cHtml := "fSincItens: Falha obter o Item da Tabela de Preco para atualizacao: " +  AllTrim(TABITENS->id) + " - " + AllTrim(TABITENS->produto_id) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)																																
				endif

			else

				// Altera cabecalho das Itens das de precos em Meus Pedidos																		
				cJson := '{'						
				cJson += '"tabela_id":' + u_GwTiraGraf(TABITENS->tabela_id) +','
				cJson += '        "ultima_alteracao": "' + AllTrim(TABITENS->ULTIMA_ALTERACAO) + '",'
				cJson += '        "preco": ' + AllTrim(Str(TABITENS->preco)) + ','
				cJson += '        "produto_id": ' + u_GwTiraGraf(TABITENS->produto_id) +','
				//cJson += '        "id": 'u_GwTiraGraf(TABITENS->ID)', '
				cJson += '        "excluido": ' + AllTrim(TABITENS->excluido) 
				cJson += '}'						

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABITENS->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If "200" $ cCodHttp 		

					// Deve-se atualizar tambem registro deletados							
					cQuery := "UPDATE "+RetSQLName("DA1")+" "
					cQuery += " SET DA1_XULTAL = '"+cNewDtMod+"' "						
					cQuery += "  WHERE DA1_XIDMPE = '" + AllTrim(TABITENS->ID) +"' "
					cQuery += "  	AND DA1_CODTAB = '" + TABITENS->codigo + "' AND DA1_CODPRO =  '" + TABITENS->codProduto + "' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincItens: Falha ao atualizar data ultima alteracao do Item da Tabela de Preco: " +  AllTrim(TABITENS->ID) + " - " + AllTrim(TABITENS->produto_id) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao cabec Item da Tabela
					cHtml := "fSincItens: Falha ao atualizar alteracao do Item da Tabela de Preco: " +  AllTrim(TABITENS->ID) + " - " + AllTrim(TABITENS->produto_id) + " na API"  
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
				endif

			endif

		else

			cJson := '{'						
			cJson += '"tabela_id":' + u_GwTiraGraf(TABITENS->tabela_id) +','
			cJson += '        "ultima_alteracao": "' + AllTrim(TABITENS->ULTIMA_ALTERACAO) + '",'
			cJson += '        "preco": ' + AllTrim(Str(TABITENS->preco)) + ','
			cJson += '        "produto_id": ' + u_GwTiraGraf(TABITENS->produto_id) +','
			//cJson += '        "id": 'u_GwTiraGraf(TABITENS->ID)', '
			cJson += '        "excluido": ' + AllTrim(TABITENS->excluido) 
			cJson += '}'	

			MemoWrite("C:\temp\ItemTabela.json",cJson)

			// Inclui nova Item da Tabela em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If cCodHttp $ "200/201".And. ! Empty(cId)		

				cQuery := "UPDATE "+RetSQLName("DA1")+" "
				cQuery += " SET DA1_XULTAL = '"+cNewDtMod+"', DA1_XIDMPE = '" + u_GwTiraGraf(cId) + "'						
				cQuery += "  WHERE DA1_CODTAB = '" + TABITENS->codigo + "' AND DA1_CODPRO =  '" + TABITENS->codProduto + "' "   

				If tcsqlexec(cQuery) < 0
					cHtml := "fSincItens: Falha ao atualizar o campo ID no ERP do Item da Tabela de Preco incluso: " +  AllTrim(TABITENS->codigo) + " - " + AllTrim(TABITENS->produto_id) + " "   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
				endif	

				// Deleta em Meus Pedidos												
				//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABITENS->ID), cJson)

			else
				// enviar email falha de inclusao Item da Tabela de preco
				cHtml := "fSincItens: Erro ao processar retorno da inclusao do Cabecalho da Item da Tabela de Preco: " +  AllTrim(TABITENS->codigo) + " - " + AllTrim(TABITENS->produto_id)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		TABITENS->( DbSkip() )

	End



	if ! Empty(cNewDtMod)
		PutMV("DA1_XULTAL",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","FAT005: Finalizada sincronizacao dos Itens das Tabelas de Preco. Ultima sincronizacao " + GetMV("DA1_XULTAL",,"") )
	TABITENS->( DbCloseArea() )
	FreeObj(oTABITENS)
Return
