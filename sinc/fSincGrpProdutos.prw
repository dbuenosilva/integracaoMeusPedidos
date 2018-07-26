#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  fSincGrpProdutos       ºAutor ³Diego Bueno      º Data ³   22/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Sincroniza Cadastro de Categoria de Produtos               º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Protheus x MeusPedidos.com.br                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function fSincGrpProdutos(lJob)
	Local cURLBase      := ""
	Local lGetDtime		:= ""	
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cBM_XULTALT   := ""
	Local cNewDtMod		:= ""
	Local ocategProd    := nil
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
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SBM" //USER "Admin" PASSWORD "senha"	
	endif

	u_GwLog("meuspedidos.log","fSincGrpProdutos: Iniciando sincronizacao das Categorias de Produtos...")
	cURLBase      := Alltrim( GetMV("MV_XMPCATE",,"") )
	lGetDtime	  := GetMV("MV_XGETDTI",,.F.)	
	cBM_XULTALT   := AllTrim(GetMV("BM_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de categorias de produtos do Protheus para serem atualizados em Meus Pedidos  
	cQuery += "	 SELECT BM_GRUPO as codigo, " 
	cQuery += "	 BM_DESC as nome, " 
	cQuery += "	 BM_XIDMPED as id, " 
	cQuery += "	 BM_XULTALT as ultima_alteracao,"
	cQuery += "	 ' ' as categoria_pai_id," 
	cQuery += "	 CASE WHEN D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido"   
	cQuery += "	 FROM SBM010 WHERE BM_XLIBVEN = 'S'  " 
	cQuery += "	 AND (BM_XULTALT = ' ' OR BM_XULTALT > '" + cBM_XULTALT + "') " 

	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\categProd.txt",cQuery)

	//X5_CHAVE nome                                                                                            id                                                      excluido

	if Select("categProd") > 0
		categProd->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "categProd"

	dbSelectArea("categProd")
	categProd->(dbGoTop())

	While ! categProd->( EOF() )

		if ! Empty(categProd->ID)

			if lGetDtime

				aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(categProd->ID) ) 
				cJson    := aHttpGet[1]
				cRetHead := aHttpGet[2]
				cCodHttp := aHttpGet[3]

				If "200" $ cCodHttp 

					if FWJsonDeserialize( cJson, @ocategProd )

						if  Empty(categProd->ultima_alteracao) ;
						.Or. AllTrim(categProd->ultima_alteracao) > AllTrim(ocategProd:ultima_alteracao)  

							// Altera categProd em Meus Pedidos																		
							cJson := '{ '					
							cJson += '"nome": "' + u_GwTiraGraf(categProd->nome) + '", '						
							cJson += '"excluido":' + AllTrim(categProd->excluido) + ''
							cJson += '}'

							aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(categProd->ID), cJson)
							cJson    		:= aHttpPut[1]
							cRetHead 		:= aHttpPut[2]
							cCodHttp 		:= aHttpPut[3]
							cId          	:= aHttpPut[4]
							cNewDtMod	    := aHttpPut[5]

							If "200" $ cCodHttp 		

								// Deve-se atualizar tambem registro deletados							
								cQuery := "UPDATE "+RetSQLName("SBM")+" "
								cQuery += " SET BM_XULTALT = '"+cNewDtMod+"' "						
								cQuery += "  WHERE BM_GRUPO = '" + AllTrim(categProd->CODIGO) +"' "

								If tcsqlexec(cQuery) < 0
									cHtml := "fSincGrpProdutosA: Falha ao atualizar data ultima alteracao da Categoria de Produto: " +  AllTrim(categProd->CODIGO) + " - " + AllTrim(categProd->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
									u_GwLog("meuspedidos.log", cHtml)
									u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
								endif			

							else
								// enviar email falha de inclusao Categoria de Produtos
								cHtml := "fSincGrpProdutosA: Falha ao atualizar alteracao da Categoria de Produto: " +  AllTrim(categProd->CODIGO) + " - " + AllTrim(categProd->NOME) + " na API"  
								u_GwLog("meuspedidos.log", cHtml)
								u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
							endif												

						endif

					else
						cHtml := "fSincGrpProdutosA: Erro ao processar FWJsonDeserialize da Categoria de Produto " ;
						+  AllTrim(categProd->CODIGO) + " - " + AllTrim(categProd->NOME) + " com Json: " + cJson   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
					endif

				else
					// enviar erro por email de falha ao realizar get em categorias que ja existe na api
					cHtml := "fSincGrpProdutosA: Falha obter a Categoria de Produto para atualizacao: " +  AllTrim(categProd->CODIGO) + " - " + AllTrim(categProd->NOME) + " na API"   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)																																
				endif


			else

				// Altera categProd em Meus Pedidos																		
				cJson := '{ '					
				cJson += '"nome": "' + u_GwTiraGraf(categProd->nome) + '", '						
				cJson += '"excluido":' + AllTrim(categProd->excluido) + ''
				cJson += '}'

				aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(categProd->ID), cJson)
				cJson    		:= aHttpPut[1]
				cRetHead 		:= aHttpPut[2]
				cCodHttp 		:= aHttpPut[3]
				cId          	:= aHttpPut[4]
				cNewDtMod	    := aHttpPut[5]

				If "200" $ cCodHttp 		

					// Deve-se atualizar tambem registro deletados							
					cQuery := "UPDATE "+RetSQLName("SBM")+" "
					cQuery += " SET BM_XULTALT = '"+cNewDtMod+"' "						
					cQuery += "  WHERE BM_GRUPO = '" + AllTrim(categProd->CODIGO) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincGrpProdutosA: Falha ao atualizar data ultima alteracao da Categoria de Produto: " +  AllTrim(categProd->CODIGO) + " - " + AllTrim(categProd->NOME) + " Error: " + tcsqlerror() + ' ' + cQuery
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)									
					endif			

				else
					// enviar email falha de inclusao Categoria de Produtos
					cHtml := "fSincGrpProdutosA: Falha ao atualizar alteracao da Categoria de Produto: " +  AllTrim(categProd->CODIGO) + " - " + AllTrim(categProd->NOME) + " na API"  
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif												

			endif

		else

			cJson := '{ '
			//	cJson += '"ultima_alteracao":"' + AllTrim(categProd->ULTIMA_ALTERACAO) + '",'
			cJson += '"excluido":' + AllTrim(categProd->excluido) + ','
			//			cJson += '"id": ' + u_GwTiraGraf(categProd->id) + ' '
			cJson += '"nome": "' + u_GwTiraGraf(categProd->nome) + '" ' 
			cJson += '}'

			// Inclui nova Categoria de Produtos em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]

			If "201" $ cCodHttp .And. ! Empty(cId)		

				cQuery := "UPDATE "+RetSQLName("SBM")+" "  							
				cQuery += " SET BM_XULTALT = '"+cNewDtMod + "', BM_XIDMPED = '" + u_GwTiraGraf(cId) + "' "						
				cQuery += "  WHERE BM_GRUPO = '" + AllTrim(categProd->CODIGO) +"' "

				If tcsqlexec(cQuery) < 0
					cHtml := "fSincGrpProdutosA: Falha ao atualizar o campo ID no ERP da Categoria de Produto inclusa: " +  AllTrim(categProd->id) + " - " + AllTrim(categProd->NOME) + " "   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
				endif	

				// Deleta em Meus Pedidos												
				//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(categProd->ID), cJson)

			else
				// enviar email falha de inclusao categoria de produtos
				cHtml := "fSincGrpProdutosA: Erro ao processar retorno da inclusao da Categoria de Produto: " +  AllTrim(categProd->id) + " - " + AllTrim(categProd->NOME)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif

		endif	 		

		categProd->( DbSkip() )

	End

	if ! Empty(cNewDtMod)
		PutMV("BM_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincGrpProdutos: Finalizada sincronizacao das Categorias de Produtos. Ultima sincronizacao " + GetMV("BM_XULTALT",,"") )
	categProd->(DbCloseArea())
	FreeObj(ocategProd)
Return

