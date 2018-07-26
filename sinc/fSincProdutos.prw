#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincProdutos       บAutor ณDiego Bueno      บ Data ณ   29/05/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Cadastro de Produtos.                           บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function fSincProdutos(lJob)
	Local cURLBase      := ""
	Local lGetDtime     := ""	
	Local cQuery 	 	:= ""
	Local aProdutos   	:= {}
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cB1_XULTALT   := ""
	Local cNewDtMod		:= ""
	Local oListaProdutos:= nil
	Local oProduto      := nil
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
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SB1" //USER "Admin" PASSWORD "senha"	
	endif

	cURLBase      := Alltrim( GetMV("MV_XMPPROD",,"") )
	lGetDtime     := GetMV("MV_XGETDTI",,.F.)	
	cB1_XULTALT   := AllTrim(GetMV("B1_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao

	u_GwLog("meuspedidos.log","FAT005: Iniciando sincronizacao dos produtos...")
	cMailResp         := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de produtos do Protheus para serem atualizados em Meus Pedidos 
	cQuery += " SELECT RTRIM(LTRIM(B1_COD)) AS CODIGO,  " 
	cQuery += " RTRIM(LTRIM(B1_DESC)) AS NOME, "  
	cQuery += " 'P' AS TIPO_IPI, " 
	cQuery += " '0.0' AS PRECO_TABELA, " 
	cQuery += " 'null' AS IPI, " 
	cQuery += " 'null' AS COMISSAO, " 
	cQuery += " CASE WHEN SB1.D_E_L_E_T_ = '*' THEN 'true' ELSE 'false' END AS EXCLUIDO, " 
	cQuery += " LTRIM(RTRIM(B1_XIDMPED)) AS ID, " 
	cQuery += " RTRIM(LTRIM(B1_UM)) AS UNIDADE, " 
	cQuery += " B1_PESBRU AS PESO_BRUTO, " 
	cQuery += " 'null' AS PRECO_MINIMO, " 
	cQuery += " '0' AS MOEDA, " 
	cQuery += " 'null' AS SALDO_ESTOQUE, " 
	cQuery += " '' AS OBSERVACOES, " 
	cQuery += " '1.0' AS MULTIPO, " 
	cQuery += " RTRIM(LTRIM(B1_XULTALT)) AS ULTIMA_ALTERACAO, " 
	cQuery += " 'null' AS ST, " 
	cQuery += " ISNULL(BM_XIDMPED,' ') AS CATEGORIA_ID, "	
	cQuery += " CASE WHEN B1_MSBLQL <> '1' THEN 'true' ELSE 'false' END ATIVO " 		    
	cQuery += " FROM " + RetSQLName("SB1") + " SB1 "
	cQuery += " INNER JOIN " + RetSQLName("SBM") + " SBM ON BM_FILIAL = B1_FILIAL "	 
	cQuery += "  AND BM_GRUPO = B1_GRUPO AND SBM.D_E_L_E_T_ <> '*' "
	cQuery += " WHERE BM_XLIBVEN = 'S'  " //SB1.D_E_L_E_T_ <> '*' deletados devem ser sincronizados 
	cQuery += " AND ( B1_XULTALT = ' ' OR B1_XULTALT > '" + cB1_XULTALT + "' )  " 

	//cQuery := ChangeQuery(cQuery)
	//MemoWrite("C:\temp\produtos.txt",cQuery)

	if Select("PRODUTOS") > 0
		PRODUTOS->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "PRODUTOS"
	TcSetField("PRODUTOS","PESO_BRUTO","N",17,2)

	dbSelectArea("PRODUTOS")
	PRODUTOS->(dbGoTop())

	While ! PRODUTOS->( EOF() )

		if ! Empty(PRODUTOS->ID)

			if lGetDtime

				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(PRODUTOS->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @oProduto )

						if  Empty(PRODUTOS->ULTIMA_ALTERACAO) ;
						.Or. AllTrim(PRODUTOS->ULTIMA_ALTERACAO) > AllTrim(oProduto:ultima_alteracao)  

							// Altera produtos em Meus Pedidos												
							cJson := '{'
							cJson += '"tipo_ipi":"' + AllTrim(PRODUTOS->TIPO_IPI) + '",'
							cJson += '"preco_tabela":' + AllTrim(PRODUTOS->PRECO_TABELA) + ','
							cJson += '"ipi":' + AllTrim(PRODUTOS->IPI) + ','
							cJson += '"comissao":' + AllTrim(PRODUTOS->COMISSAO) + ','
							cJson += '"excluido":' + AllTrim(PRODUTOS->EXCLUIDO) + ','
							cJson += '"id":'  + AllTrim(PRODUTOS->ID) + ','
							cJson += '"nome":"' + u_GwTiraGraf(PRODUTOS->NOME) + '",'
							cJson += '"unidade":"' + AllTrim(PRODUTOS->UNIDADE) + '",'
							cJson += '"peso_bruto":' + AllTrim(Str(PRODUTOS->PESO_BRUTO)) + ','
							cJson += '"preco_minimo":' + AllTrim(PRODUTOS->PRECO_MINIMO) + ','
							cJson += '"moeda":"' + AllTrim(PRODUTOS->MOEDA) + '",'
							cJson += '"saldo_estoque":' + AllTrim(PRODUTOS->SALDO_ESTOQUE) + ','
							cJson += '"observacoes":"' + u_GwTiraGraf(PRODUTOS->OBSERVACOES) + '",'
							cJson += '"multiplo":' + AllTrim(PRODUTOS->MULTIPO) + ','
							cJson += '"ultima_alteracao":"' + AllTrim(PRODUTOS->ULTIMA_ALTERACAO) + '",'
							cJson += '"st":' + AllTrim(PRODUTOS->ST) + ','
							cJson += '"codigo":"' + AllTrim(PRODUTOS->CODIGO) + '",'
							cJson += '"categoria_id":"' + AllTrim(PRODUTOS->CATEGORIA_ID) + '",'						
							cJson += '"ativo":' + AllTrim(PRODUTOS->ATIVO)
							cJson += '}'

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(PRODUTOS->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								// Deve-se atualizar tambem registro deletados							
								cQuery := "UPDATE "+RetSQLName("SB1")+" "
								cQuery += " SET B1_XULTALT = '"+cNewDtMod+"' "							
								cQuery += "  WHERE B1_COD = '" + AllTrim(PRODUTOS->CODIGO) +"' "

								If tcsqlexec(cQuery) < 0
									cHtml := "fSincProdutos: Falha ao atualizar data ultima alteracao produto: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao produto
								cHtml := "fSincProdutos: Falha ao atualizar alteracao do produto: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " na API"  
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "fSincProdutos: Erro ao processar FWJsonDeserialize do produto " ;
						+  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em produto que ja existe na api
					cHtml := "fSincProdutos: Falha obter o produto para atualizacao: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)																																
				endif

			else


				// Altera produtos em Meus Pedidos												
				cJson := '{'
				cJson += '"tipo_ipi":"' + AllTrim(PRODUTOS->TIPO_IPI) + '",'
				cJson += '"preco_tabela":' + AllTrim(PRODUTOS->PRECO_TABELA) + ','
				cJson += '"ipi":' + AllTrim(PRODUTOS->IPI) + ','
				cJson += '"comissao":' + AllTrim(PRODUTOS->COMISSAO) + ','
				cJson += '"excluido":' + AllTrim(PRODUTOS->EXCLUIDO) + ','
				cJson += '"id":'  + AllTrim(PRODUTOS->ID) + ','
				cJson += '"nome":"' + u_GwTiraGraf(PRODUTOS->NOME) + '",'
				cJson += '"unidade":"' + AllTrim(PRODUTOS->UNIDADE) + '",'
				cJson += '"peso_bruto":' + AllTrim(Str(PRODUTOS->PESO_BRUTO)) + ','
				cJson += '"preco_minimo":' + AllTrim(PRODUTOS->PRECO_MINIMO) + ','
				cJson += '"moeda":"' + AllTrim(PRODUTOS->MOEDA) + '",'
				cJson += '"saldo_estoque":' + AllTrim(PRODUTOS->SALDO_ESTOQUE) + ','
				cJson += '"observacoes":"' + u_GwTiraGraf(PRODUTOS->OBSERVACOES) + '",'
				cJson += '"multiplo":' + AllTrim(PRODUTOS->MULTIPO) + ','
				cJson += '"ultima_alteracao":"' + AllTrim(PRODUTOS->ULTIMA_ALTERACAO) + '",'
				cJson += '"st":' + AllTrim(PRODUTOS->ST) + ','
				cJson += '"codigo":"' + AllTrim(PRODUTOS->CODIGO) + '",'
				cJson += '"categoria_id":"' + AllTrim(PRODUTOS->CATEGORIA_ID) + '",'						
				cJson += '"ativo":' + AllTrim(PRODUTOS->ATIVO)
				cJson += '}'

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(PRODUTOS->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If "200" $ cCodHttp 		

					// Deve-se atualizar tambem registro deletados							
					cQuery := "UPDATE "+RetSQLName("SB1")+" "
					cQuery += " SET B1_XULTALT = '"+cNewDtMod+"' "							
					cQuery += "  WHERE B1_COD = '" + AllTrim(PRODUTOS->CODIGO) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincProdutos: Falha ao atualizar data ultima alteracao produto: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao produto
					cHtml := "fSincProdutos: Falha ao atualizar alteracao do produto: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " na API"  
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
				endif												

			endif

		else

			cJson := '{'
			cJson += '"tipo_ipi":"' + AllTrim(PRODUTOS->TIPO_IPI) + '",'
			cJson += '"preco_tabela":' + AllTrim(PRODUTOS->PRECO_TABELA) + ','
			cJson += '"ipi":' + AllTrim(PRODUTOS->IPI) + ','
			cJson += '"comissao":' + AllTrim(PRODUTOS->COMISSAO) + ','
			cJson += '"excluido":' + AllTrim(PRODUTOS->EXCLUIDO) + ','
			//			cJson += '"id":'  ','
			cJson += '"nome":"' + u_GwTiraGraf(PRODUTOS->NOME) + '",'
			cJson += '"unidade":"' + AllTrim(PRODUTOS->UNIDADE) + '",'
			cJson += '"peso_bruto":' + AllTrim(Str(PRODUTOS->PESO_BRUTO)) + ','
			cJson += '"preco_minimo":' + AllTrim(PRODUTOS->PRECO_MINIMO) + ','
			cJson += '"moeda":"' + AllTrim(PRODUTOS->MOEDA) + '",'
			cJson += '"saldo_estoque":' + AllTrim(PRODUTOS->SALDO_ESTOQUE) + ','
			cJson += '"observacoes":"' + u_GwTiraGraf(PRODUTOS->OBSERVACOES) + '",'
			cJson += '"multiplo":' + AllTrim(PRODUTOS->MULTIPO) + ','
			cJson += '"ultima_alteracao":"' + AllTrim(PRODUTOS->ULTIMA_ALTERACAO) + '",'
			cJson += '"st":' + AllTrim(PRODUTOS->ST) + ','
			cJson += '"codigo":"' + AllTrim(PRODUTOS->CODIGO) + '",'
			cJson += '"categoria_id":"' + AllTrim(PRODUTOS->CATEGORIA_ID) + '",'			
			cJson += '"ativo":' + AllTrim(PRODUTOS->ATIVO)
			cJson += '}'

			//MemoWrite("C:\temp\produtosParaIncluir.txt",cJson)

			// Inclui novo produto em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If "201" $ cCodHttp .And. ! Empty(cId)		

				DbSelectArea("SB1")
				SB1->(DbSetOrder(1))
				if SB1->(DbSeek(xFilial("SB1") + PRODUTOS->CODIGO ))

					RecLock("SB1",.F.)
					SB1->B1_XIDMPED := u_GwTiraGraf(cId) // estava gravando \r
					SB1->B1_XULTALT := cNewDtMod		 				
					SB1->(MsUnlock())
				else

					// Falha ao atualizar produto, deleta em MeusPedidos e atualiza no Protheus																		
					cQuery := "UPDATE "+RetSQLName("SB1")+" "
					cQuery += " SET B1_XULTALT = '" + cNewDtMod + "', B1_XIDMPED = '" + u_GwTiraGraf(cId) + "' "							
					cQuery += "  WHERE B1_COD = '" + AllTrim(PRODUTOS->CODIGO) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincProdutos: Falha ao atualizar o campo ID no ERP de produto incluso: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME) + " "   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
					endif	

					// Deleta em Meus Pedidos												
					//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(PRODUTOS->ID), cJson)

				endif

			else
				// enviar email falha de inclusao produto
				cHtml := "fSincProdutos: Erro ao processar retorno da inclusao de produto: " +  AllTrim(PRODUTOS->CODIGO) + " - " + AllTrim(PRODUTOS->NOME)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		PRODUTOS->( DbSkip() )

	End

	/*
	aHttpGet := u_GetJson(cURLBase)

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1))

	If '200' $ cCodHttp .And. FWJsonDeserialize( cJson, @oListaProdutos )

	For nI := 1 to Len(oListaProdutos)

	if SB1->(DbSeek( xFilial("SB1") + oListaProdutos[nI]:codigo  )) 

	if AllTrim(SB1->B1_XULTALT) > AllTrim(oListaProdutos[nI]:ultima_alteracao)

	// Atualiza em MeusPedidos
	u_GwLog("meuspedidos.log","FAT005: Produto " + oListaProdutos[nI]:codigo + " alterado no ERP em " ;
	+ AllTrim(SB1->B1_XULTALT) + " mas nao sincronizacao. Ultima sincronizacao com API " ;
	+ AllTrim(oListaProdutos[nI]:ultima_alteracao ) ) 				

	endif

	else

	// Bloqueia em Meus Pedidos

	endif


	Next

	Else
	u_GwLog("meuspedidos.log","FAT005: Erro ao processar Json em FWJsonDeserialize ')	
	Endif		

	*/

	if ! Empty(cNewDtMod)
		PutMV("B1_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","FAT005: Finalizada sincronizacao dos produtos. Ultima sincronizacao " + GetMV("B1_XULTALT",,"") )

	PRODUTOS->(DbCloseArea())
	FreeObj(oProduto)
	FreeObj(oListaProdutos)
Return
