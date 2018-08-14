#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincClientes บAutor ณDiego Bueno      บ Data ณ   14/06/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Cadastro de Clientes.                           บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function fSincClientes(lJob)

	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cA1_XULTALT   := ""
	Local cNewDtMod		:= ""
	Local oListaClientes:= nil
	Local oCliente      := Nil
	Local aHttpGet      := {}
	Local aHttpPost     := {}
	Local aHttpPut      := {}		
	Local cId           := ''
	Local lJaTemTelefone:= .F.
	Local lJaTemContatos:= .F.
	Local lInclusao		:= .F.
	Local lAlteracao    := .F.

	Private cURLBase      := ""
	Private cEol	    := chr(13)+chr(10)
	Private cMailResp   := ""
	Private cSGBD       := ""

	Default lJob        := .F.

	If ! lJob  .And. Select("SX2") == 0 // Via JOB
		lJob := .T.
	endif

	if lJob	
		RpcSetType(3)	
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SA1" //USER "Admin" PASSWORD "senha"	
	endif

	u_GwLog("meuspedidos.log","fSincClientes: Iniciando sincronizacao dos clientes...")

	cURLBase      	  := Alltrim( GetMV("MV_XMPCLIE",,"") )
	cA1_XULTALT       := AllTrim(GetMV("A1_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao	
	cMailResp         := AllTrim(GetMV("MV_GWMAILR",," "))
	cMailNewCli       := AllTrim(GetMV("MV_GWMAILC",," "))

	// Obtem lista de clientes que foram criados ou alterados em Meus Pedidos
	// e os incluo/altera no Protheus
	cNewDtMod := fGetNovosClientes()


	// Obtem lista de clientes alterados no Protheus para serem atualizados em Meus Pedidos 
	cQuery += " SELECT A1_COD AS CODIGO, A1_LOJA AS LOJA,"
	//		-- TELFONES	
	cQuery += " CASE WHEN A1_TEL <> ' ' THEN LTRIM(RTRIM(A1_DDD)) + ' ' + A1_TEL ELSE ' ' END AS tel1_numero," 		 				
	cQuery += " A1_XIDFONE AS tel1_id,"		
	cQuery += " CASE WHEN A1_FAX <> ' ' THEN LTRIM(RTRIM(A1_DDD)) + ' ' + A1_FAX ELSE ' ' END AS tel2_numero," 		
	cQuery += " A1_XIDFAX AS tel2_id,"
	cQuery += " CASE WHEN A1_TELEX <> ' ' THEN LTRIM(RTRIM(A1_DDD)) + ' ' + A1_TELEX ELSE ' ' END AS tel3_numero," 		
	cQuery += " A1_XIDTELE AS tel3_id,"				 
	//		-- demais campos	
	cQuery += " A1_CGC AS cnpj," 		
	cQuery += " A1_END AS rua,"	
	cQuery += " A1_COMPLEM AS complemento," 	
	cQuery += " A1_PESSOA AS tipo,"
	cQuery += " ISNULL(X5_DESCSPA,' ') AS segmento_id, 		A1_NOME AS razao_social," 		
	cQuery += " A1_NREDUZ AS nome_fantasia, 		A1_BAIRRO AS bairro, 		A1_MUN AS cidade," 		
	cQuery += " A1_INSCR AS inscricao_estadual,"
	cQuery += " 'Codigo do cliente no ERP: ' + A1_COD + '-' + A1_LOJA + ' - Ger.Financeiro = ' + "
	cQuery += "	CASE WHEN A1_XGFINAN = '1' THEN 'SIM' ELSE 'NAO' END + "
	cQuery += " CASE WHEN A1_XOBS <> ' ' THEN ' - Obs.: ' + LTRIM(RTRIM(A1_XOBS)) ELSE '' END AS observacao, " 
	cQuery += " CASE WHEN A1_ENDENT <> ' ' THEN ' - End.Entrega: ' + LTRIM(RTRIM(A1_ENDENT)) ELSE '' END AS observacao, "				
	cQuery += " A1_XIDMPED AS id, A1_XULTALT AS ultima_alteracao, A1_CEP AS cep,"
	cQuery += " A1_SUFRAMA as suframa, A1_EST AS estado,"
	cQuery += " CASE WHEN LEN(A1_EMAIL) > 5 AND A1_EMAIL LIKE '%@%' AND A1_EMAIL  NOT LIKE '%,%'" 
	cQuery += " AND A1_EMAIL  NOT LIKE '%;%'"
	cQuery += " THEN A1_EMAIL ELSE ' ' END AS emails_email," 
	cQuery += " 'T' as emails_tipo," 		
	cQuery += " A1_XIDMAIL as emails_id,"	  
	cQuery += " CASE WHEN SA1.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido"	 	 
	cQuery += " FROM " + RetSQLName("SA1") + " SA1 " 		
	cQuery += " LEFT JOIN " + RetSQLName("SX5") + "  SX5 ON X5_FILIAL = ' ' AND X5_TABELA = 'T3' " 			 		
	cQuery += " AND A1_SATIV1 = X5_CHAVE AND SX5.D_E_L_E_T_ <> '*' "
	cQuery += " WHERE 	( A1_XULTALT = ' ' OR 	A1_XULTALT > '" + cA1_XULTALT + "'  ) "

	//cQuery += " and 1 = 2  "  

	//cQuery += " AND A1_COD = '000004'  "

	cQuery += " AND A1_TABELA <> ' ' AND A1_VEND <> ' ' "

	cQuery += " GROUP BY A1_COD, A1_LOJA,A1_TEL,A1_DDD,A1_XIDFONE,A1_FAX,A1_XIDFAX, " 
	cQuery += " 	A1_TELEX,A1_XIDTELE,A1_CGC,A1_END,A1_COMPLEM, " 
	cQuery += " SA1.D_E_L_E_T_,A1_PESSOA,X5_DESCSPA,A1_NOME,A1_NREDUZ,A1_BAIRRO,A1_MUN, " 
	cQuery += " A1_INSCR,A1_XOBS,A1_XIDMPED,A1_XULTALT,A1_CEP,A1_SUFRAMA ,A1_EST,A1_EMAIL,A1_XIDMAIL,A1_XGFINAN,A1_ENDENT " 
	cQuery += " ORDER BY A1_COD, A1_LOJA " 

	//	cQuery += "		AND A1_XIDMPED = '2841220' "	 
	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\clientes.txt",cQuery)

	if Select("CLIENTES") > 0
		CLIENTES->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "CLIENTES"

	dbSelectArea("CLIENTES")
	CLIENTES->(dbGoTop())

	While ! CLIENTES->( EOF() )

		lAlteracao := .F.
		lInclusao  := .F.

		if Empty(CLIENTES->ID)
			lInclusao  := .T.
		else // cliente ja existente na APi

			aHttpGet := u_GetJson(cURLBase + "/" +  u_GwTiraGraf(CLIENTES->ID) ) 
			cJson    := aHttpGet[1]
			cRetHead := aHttpGet[2]
			cCodHttp := aHttpGet[3]

			If "200" $ cCodHttp 

				if FWJsonDeserialize( cJson, @oCliente )

					if  Empty(CLIENTES->ULTIMA_ALTERACAO) ;
					.Or. AllTrim(CLIENTES->ULTIMA_ALTERACAO) > AllTrim(oCliente:ultima_alteracao)  

						lAlteracao := .T.

					endif

				else
					cHtml := "fSincClientes: Erro ao processar FWJsonDeserialize do cliente " ;
					+  AllTrim(CLIENTES->CODIGO) + " - " + AllTrim(CLIENTES->razao_social) + " com Json: " + cJson   
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp," ","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
				endif

			else

				// enviar erro por email de falha ao realizar get em cliente que ja existe na api
				cHtml := "fSincClientes: Falha obter o cliente para atualizacao: " +  AllTrim(CLIENTES->CODIGO) + " - " + AllTrim(CLIENTES->razao_social) + " na API"   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp," ","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)																																

			endif

		endif				

		// Inclui ou Altera clientes em Meus Pedidos												
		cJson := '{'	

		// Add ou altera telefones					
		cJson += '        "telefones": [ ' 												
		lJaTemTelefone := .F.
		if ! Empty( CLIENTES->tel1_numero )
			cJson += '            {'
			cJson += '                "numero": "' + u_GwTiraGraf(CLIENTES->tel1_numero) + '",'
			cJson += '                "tipo": "T" '
			if ! Empty ( CLIENTES->tel1_id )
				cJson += '                ,"id": ' + u_GwTiraGraf(CLIENTES->tel1_id) + ''
			endif
			cJson += '            }'
			lJaTemTelefone := .T.
		endif
		if ! Empty( CLIENTES->tel2_numero )
			if lJaTemTelefone
				cJson += ','
			endif
			cJson += '            {'
			cJson += '                "numero": "' + u_GwTiraGraf(CLIENTES->tel2_numero) + '",'
			cJson += '                "tipo": "T" '
			if ! Empty ( CLIENTES->tel2_id )
				cJson += '                ,"id": ' + u_GwTiraGraf(CLIENTES->tel2_id) + ''
			endif
			cJson += '            }'
			lJaTemTelefone := .T.
		endif
		if ! Empty( CLIENTES->tel3_numero )
			if lJaTemTelefone
				cJson += ','
			endif
			cJson += '            {'
			cJson += '                "numero": "' + u_GwTiraGraf(CLIENTES->tel3_numero) + '",'
			cJson += '                "tipo": "T" '
			if ! Empty ( CLIENTES->tel3_id )
				cJson += '                ,"id": ' + u_GwTiraGraf(CLIENTES->tel3_id) + ''
			endif
			cJson += '            }'
			lJaTemTelefone := .T.
		endif

		cJson += '        ],'
		cJson += '        "cnpj": "' + u_GwTiraGraf(CLIENTES->cnpj) + '",'
		cJson += '        "rua": "' + u_GwTiraGraf(CLIENTES->rua) + '",'
		cJson += '        "complemento": "' + u_GwTiraGraf(CLIENTES->complemento) + '",'

		// Inclui ou atualiza os contatos
		cJson += fAddContatos()

		cJson += '        "tipo": "' + u_GwTiraGraf(CLIENTES->tipo) + '",'
		if ! Empty(AllTrim(CLIENTES->segmento_id))
			cJson += '		"segmento_id":' + u_GwTiraGraf(CLIENTES->segmento_id) + ','
		endif
		cJson += '        "razao_social": "' + u_GwTiraGraf(CLIENTES->razao_social) + '",'
		cJson += '        "nome_fantasia": "' + u_GwTiraGraf(CLIENTES->nome_fantasia) + '",'
		cJson += '        "bairro": "' + SubStr(u_GwTiraGraf(CLIENTES->bairro),1,30) + '",'
		cJson += '        "cidade": "' + u_GwTiraGraf(CLIENTES->cidade) + '",'
		cJson += '        "inscricao_estadual": "' + u_GwTiraGraf(CLIENTES->inscricao_estadual) + '",'
		cJson += '        "observacao": "' + u_GwTiraGraf(CLIENTES->observacao) + '",'
		//cJson += '        "id": ' + AllTrim(CLIENTES->id) + ','
		cJson += '        "ultima_alteracao": "' + u_GwTiraGraf(CLIENTES->ultima_alteracao) + '",'
		cJson += '        "cep": "' + u_GwTiraGraf(CLIENTES->cep) + '",'
		cJson += '        "suframa": "' + u_GwTiraGraf(CLIENTES->suframa) + '",'
		cJson += '        "estado": "' + u_GwTiraGraf(CLIENTES->estado) + '",'
		cJson += '        "emails": ['
		if ! Empty(CLIENTES->emails_email)							
			cJson += '            {'
			cJson += '                "email": "' + u_GwTiraGraf(CLIENTES->emails_email) + '",'
			cJson += '                "tipo": "T" '
			if ! Empty(CLIENTES->emails_id)
				cJson += '                ,"id": ' + u_GwTiraGraf(CLIENTES->emails_id) + ''
			endif
			cJson += '       	  }'											
		endif
		cJson += '   ],'
		cJson += '   "excluido": ' + u_GwTiraGraf(CLIENTES->excluido) + ' '
		cJson += '}'

		MemoWrite("C:\temp\clientesParaAlterar.txt",cJson)

		if lAlteracao .And. ! Empty(CLIENTES->ID)

			aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(CLIENTES->ID), cJson)
			cJson    		:= aHttpPut[1]
			cRetHead 		:= aHttpPut[2]
			cCodHttp 		:= aHttpPut[3]
			cId          	:= aHttpPut[4]
			cNewDtMod	    := aHttpPut[5]
			cMsg    		:= aHttpPut[6]

			If "200" $ cCodHttp 		

				IF AllTrim(cNewDtMod) > AllTrim(cA1_XULTALT)
					cA1_XULTALT := cNewDtMod
				Endif

				// Deve-se atualizar tambem registro deletados							
				cQuery := "UPDATE "+RetSQLName("SA1")+" "
				cQuery += " SET A1_XULTALT = '"+cNewDtMod+"' "							
				cQuery += "  WHERE A1_COD = '" + AllTrim(CLIENTES->CODIGO) +"' AND A1_LOJA = '" + AllTrim(CLIENTES->LOJA) +"' "

				If tcsqlexec(cQuery) < 0
					cHtml := "fSincClientes: Falha ao atualizar data ultima alteracao cliente: " +  AllTrim(CLIENTES->CODIGO) + " - " + AllTrim(CLIENTES->razao_social) + " Error: " + tcsqlerror() + ' ' + cQuery
					u_GwLog("meuspedidos.log", cHtml)
					u_GwSendMail(cMailResp," ","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)		
				else
					if ! Empty(cNewDtMod)
						PutMV("A1_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
					endif						
				endif			

			else
				// enviar email falha de inclusao cliente
				cHtml := "fSincClientes:  Erro ao tentar enviar do Protheus para MeusPedidos alteracao do cliente:  " +  AllTrim(CLIENTES->CODIGO) + " - " + AllTrim(CLIENTES->razao_social) + " na API" ;
				+ " Detalhes do Erro: " + cRetHead  + " " + cMsg  
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp," ","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif												

		elseif lInclusao // Inclusao de novo cliente

			// Inclui novo cliente em Meus Pedidos
			aHttpPost		:= u_PostJson(cUrlBase,cJson)
			cJson    		:= aHttpPost[1]
			cRetHead 		:= aHttpPost[2]
			cCodHttp 		:= aHttpPost[3]
			cId          	:= aHttpPost[4]
			cNewDtMod	    := aHttpPost[5]
			cMsg    		:= aHttpPost[6]

			If "201" $ cCodHttp .And. ! Empty(cId)		

				IF AllTrim(cNewDtMod) > AllTrim(cA1_XULTALT)
					cA1_XULTALT := cNewDtMod
				Endif

				DbSelectArea("SA1")
				SA1->(DbSetOrder(1))
				if SA1->(DbSeek(xFilial("SA1") + CLIENTES->CODIGO + CLIENTES->LOJA ))

					RecLock("SA1",.F.)
					SA1->A1_XIDMPED := u_GwTiraGraf(cId) // estava gravando \r
					SA1->A1_XULTALT := cNewDtMod		 				
					SA1->(MsUnlock())
				else

					// Falha ao atualizar cliente, deleta em MeusPedidos e atualiza no Protheus																		
					cQuery := "UPDATE "+RetSQLName("SA1")+" "
					cQuery += " SET A1_XULTALT = '" + cNewDtMod + "', A1_XIDMPED = '" + u_GwTiraGraf(cId) + "' "							
					cQuery += "  WHERE A1_COD = '" + AllTrim(CLIENTES->CODIGO) +"' AND A1_LOJA = '" + AllTrim(CLIENTES->LOJA) +"' "

					If tcsqlexec(cQuery) < 0
						cHtml := "fSincClientes: Falha ao atualizar o campo ID no ERP de cliente incluso: " +  AllTrim(CLIENTES->CODIGO) + " - " + AllTrim(CLIENTES->razao_social) + " "   
						u_GwLog("meuspedidos.log", cHtml)
						u_GwSendMail(cMailResp," ","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
					else
						if ! Empty(cNewDtMod)
							PutMV("A1_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
						endif	
					endif	

					// Deleta em Meus Pedidos												
					//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(CLIENTES->ID), cJson)

				endif

			else

				//				msgInfo("Ops...")
				// enviar email falha de inclusao cliente
				cHtml := "fSincClientes: Erro ao tentar enviar do Protheus para MeusPedidos o cliente: " +  AllTrim(CLIENTES->CODIGO) + " - " + AllTrim(CLIENTES->razao_social) ;
				+ " Detalhes do Erro: " + cRetHead  + " " + cMsg
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp," ","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif

		endif

		// Relacionar a tabela de Preco com o Cliente		
		CLIENTES->( DbSkip() )

	End

	if ! Empty(cNewDtMod)
		PutMV("A1_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincClientes: Finalizada sincronizacao dos clientes. Ultima sincronizacao " + GetMV("A1_XULTALT",,"") )

	FreeObj(oListaClientes)
	FreeObj(oCliente)
	CLIENTES->(DbCloseArea())
Return


/*

fGetNovosClientes - Obtem clientes que foram alterados na API e atualiza no Protheus
Diego Bueno - 30/072018

*/

Static Function fGetNovosClientes()

	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local oListaClientes:= nil
	Local oCliente      := Nil
	Local aHttpGet      := {}
	Local cMailNewCli   := ''
	Local cAssNewCli    := ""
	Local cMsg          := ""
	Local cNewDtMod := GetMV("A1_XULTALT",,"")

	aHttpGet := u_GetJson(cURLBase + "?alterado_apos=" + StrTran(AllTrim(cNewDtMod)," ","%20"))
	cJson    := aHttpGet[1]
	cRetHead := aHttpGet[2]
	cCodHttp := aHttpGet[3]

	If '200' $ cCodHttp .And. FWJsonDeserialize( cJson, @oListaClientes )

		For nI := 1 to Len(oListaClientes)

			oCliente := oListaClientes[nI]

			DbSelectArea("SA1")
			if ! SA1->(DBOrderNickname("IDCLIENTES"))                                                                                                                           
				u_GwLog("meuspedidos.log","fSincClientes: ERRO Indํce IDCLIENTES nใo encontrada na tabela de Clientes (SA1). Reportar ao T.I.")
			elseif ! SA1->(DbSeek( SA1->( cValtoChar(oCliente:id) ),.F.))

				if ! Empty(u_fGetCliente( cValtoChar(oCliente:id),1)) // verifica se este ID ja nao foi deletado no Protheus
					loop
				endif

				u_GwLog("meuspedidos.log","fSincClientes: Realizando a inclusao de novo Cliente " + AllTrim(oCliente:razao_social) + " com ID " + cValtoChar(oCliente:id) )
				RecLock("SA1",.T.)
				SA1->A1_COD    := GETSXENUM("SA1","A1_COD")                                                                                                             
				SA1->A1_LOJA   := "01"
				cAssNewCli := "Novo cliente cadastrado MeusPedidos (" + SA1->A1_COD + "-" + SA1->A1_LOJA + ") " 						
			else 
				u_GwLog("meuspedidos.log","fSincClientes: Realizando a alteracao do Cliente " + SA1->A1_COD + " - " + SA1->A1_LOJA + " " + AllTrim(oCliente:razao_social) ) 						
				RecLock("SA1",.F.)
				cAssNewCli := "Cliente alterado MeusPedidos (" + SA1->A1_COD + "-" + SA1->A1_LOJA + ") "
			endif

			SA1->A1_FILIAL :=  xFilial("SA1")
			SA1->A1_MSBLQL := '1'						
			SA1->A1_NOME   := u_GwTiraGraf(oCliente:razao_social) 			
			SA1->A1_NREDUZ := u_GwTiraGraf(oCliente:nome_fantasia)
			SA1->A1_PESSOA := u_GwTiraGraf(oCliente:tipo)

			if  AllTrim(oCliente:tipo) == "J"							
				SA1->A1_INSCR  := cValToChar(oCliente:inscricao_estadual)
				SA1->A1_SUFRAMA := u_GwTiraGraf(oCliente:suframa)
			elseif AllTrim(oCliente:tipo) == "F"
				//SA1->A1_NREDUZ := u_GwTiraGraf(oCliente:nome_fantasia)
			endif

			SA1->A1_END    := u_GwTiraGraf(oCliente:rua) + "," + u_GwTiraGraf(oCliente:complemento) 
			SA1->A1_EST    := u_GwTiraGraf(oCliente:estado)          						
			SA1->A1_BAIRRO := u_GwTiraGraf(oCliente:bairro)
			SA1->A1_MUN    := u_GwTiraGraf(oCliente:cidade)						
			SA1->A1_PESSOA := u_GwTiraGraf(oCliente:tipo)
			SA1->A1_CEP    := u_GwTiraGraf(oCliente:cep)			
			SA1->A1_XOBS   := u_GwTiraGraf(oCliente:observacao)
			if Type("oCliente") == "O" .And. Type("oCliente:segmento_id") == "N"
				SA1->A1_SATIV1 :=  u_fGetSegmento( cValtoChar(oCliente:segmento_id))
			endif
			SA1->A1_XULTALT := u_GwTiraGraf(oCliente:ultima_alteracao)
			SA1->A1_XIDMPED := cValtoChar(oCliente:id)			
			SA1->A1_XULTATB := ""
			SA1->A1_XULTATV := ""
			SA1->A1_XULTCPG := ""
			SA1->A1_RISCO   := "E"
			SA1->A1_CGC     := u_GwTiraGraf(cValtoChar(oCliente:CNPJ))   
			SA1->A1_CODPAIS := '01058'
			SA1->A1_PAIS    := '105'
			SA1->A1_XPROSPE := 'N'

			For nW := 1 to Len(oCliente:telefones)
				Do Case
					Case nW == 1
					SA1->A1_TEL     := oCliente:telefones[nW]:numero
					SA1->A1_XIDFONE := cValToChar(oCliente:telefones[nW]:id)
					Case nW == 2
					SA1->A1_FAX     := oCliente:telefones[nW]:numero
					SA1->A1_XIDFAX  := cValToChar(oCliente:telefones[nW]:id)
					Case nW == 3
					SA1->A1_TELEX   := oCliente:telefones[nW]:numero
					SA1->A1_XIDTELE := cValToChar(oCliente:telefones[nW]:id)
					OtherWise
					exit
				EndCase
			Next

			If Len(oCliente:emails) >= 1
				SA1->A1_EMAIL   := AllTrim(oCliente:emails[1]:email)
				SA1->A1_XIDMAIL := cValToChar(oCliente:emails[1]:id)
			endif

			SA1->(MsUnlock() )

			cHtml := ""
			cHtml += ""
			cHtml := '<html> '+cEol
			cHtml += '<head> '+cEol
			cHtml += '<meta name=Title content=""> '+cEol
			cHtml += '<meta name=Keywords content=""> '+cEol
			cHtml += '<meta http-equiv=Content-Type content="text/html; charset=macintosh"> '+cEol
			cHtml += '</head> ' + cEol
			cHtml += "<body lang=PT-BR style='tab-interval:36.0pt'> " + cEol
			cHtml += '<div> '+ cEol
			cHtml += '<p>' + cAssNewCli + '</p> ' + cEol
			cHtml += ' ' + cEol
			cHtml += '<p><o:p>&nbsp;</o:p></p> ' + cEol
			cHtml += ' '+cEol
			cHtml += '<p><o:p>&nbsp;</o:p></p> ' + cEol
			cHtml += ' '+cEol
			cHtml += '<p>Cliente ' + AllTrim(SA1->A1_COD) + "-" + AllTrim(SA1->A1_LOJA) + " " + AllTrim(SA1->A1_NOME) + ' bloqueado no Protheus aguardando aprova็ใo!' + cEol			
			cHtml += ' '+cEol
			cHtml += '<p><o:p>&nbsp;</o:p></p> ' + cEol
			cHtml += ' '+cEol
			cHtml += '<p>Informacoes adicionais: ' + u_GwTiraGraf(oCliente:observacao)
			cHtml += '</div> '+cEol
			cHtml += ' '+cEol
			cHtml += '</body> '+cEol
			cHtml += '</html> '+cEol

			confirmsx8()

			u_GwSendMail(cMailNewCli," ",cAssNewCli,cHtml)			

			// Contatos
			For nW := 1 to Len(oCliente:contatos)

				DbSelectArea("SU5")
				if ! SU5->(DBOrderNickname("IDCONTATOS")) 				                                                                                                                          
					u_GwLog("meuspedidos.log","fSincClientes: ERRO Indํce IDCONTATOS nใo encontrada na tabela de Contatos (SU5). Reportar ao T.I.")
				elseif ! SU5->(DbSeek( SU5->( cValtoChar(oCliente:contatos[nW]:id ) ),.F.))
					if oCliente:contatos[nW]:excluido
						loop // nao inclui contato deletado da API
					endif 
					RecLock("SU5",.T.)
					SU5->U5_FILIAL  := xFilial("SU5")					
					SU5->U5_CODCONT := GETSXENUM("SU5","U5_CODCONT")   //NEWNUMCONT()				
					SU5->U5_XIDMPED := cValToChar(oCliente:contatos[nW]:id)

				elseif oCliente:contatos[nW]:excluido
					if AC8->( DbSeek( xFilial("AC8") + SU5->U5_CODCONT + "SA1" + xFilial("SA1") + SA1->A1_COD + SA1->A1_LOJA ))
						RecLock("AC8",.F.)
						AC8->(DbDelete())
						AC8->( DbUnLock() )
					endif

					If  RecLock("SU5",.F.)
						SU5->(DbDelete())
						SU5->( DbUnLock() )						
					EndIf

					loop

				else
					RecLock("SU5",.F.)
				endif	

				SU5->U5_ATIVO   := '1'				
				SU5->U5_CONTAT  := u_GwTiraGraf(oCliente:contatos[nW]:nome)
				SU5->U5_MSBLQL  := '1'
				SU5->U5_SOLICTE := '2'		
				For nZ := 1 to Len(oCliente:contatos[nW]:emails)
					if nZ == 1 
						SU5->U5_EMAIL   := u_GwTiraGraf(oCliente:contatos[nW]:emails[nZ]:email)
						SU5->U5_XIDMAIL	:= cValToChar(oCliente:contatos[nW]:emails[nZ]:id)
					endif
				Next				

				For nY := 1 to Len(oCliente:contatos[nW]:telefones)

					Do Case
						Case nY == 1
						SU5->U5_FONE	:= u_GwTiraGraf(oCliente:contatos[nW]:telefones[nY]:numero)
						SU5->U5_XIDFONE	:= cValToChar(oCliente:contatos[nW]:telefones[nY]:id)
						Case nY == 2
						SU5->U5_CELULAR	:= u_GwTiraGraf(oCliente:contatos[nW]:telefones[nY]:numero)
						SU5->U5_XIDCELU	:= cValToChar(oCliente:contatos[nW]:telefones[nY]:id)
						Case nY == 3
						SU5->U5_FAX		:= u_GwTiraGraf(oCliente:contatos[nW]:telefones[nY]:numero)
						SU5->U5_XIDFAX	:= cValToChar(oCliente:contatos[nW]:telefones[nY]:id)
						Case nY == 4
						SU5->U5_FCOM1	:= u_GwTiraGraf(oCliente:contatos[nW]:telefones[nY]:numero)
						SU5->U5_XIDFCO1	:= cValToChar(oCliente:contatos[nW]:telefones[nY]:id)
						Case nY == 5
						SU5->U5_FCOM2	:= u_GwTiraGraf(oCliente:contatos[nW]:telefones[nY]:numero)
						SU5->U5_XIDFCO2	:= cValToChar(oCliente:contatos[nW]:telefones[nY]:id)
						OtherWise
						exit
					EndCase

				Next
				SU5->(MsUnlock() )
				confirmsx8()
				DbSelectArea("AC8")
				AC8->(DbSetOrder(1))//AC8_FILIAL+AC8_CODCON+AC8_ENTIDA+AC8_FILENT+AC8_CODENT
				if ! AC8->( DbSeek( xFilial("AC8") + SU5->U5_CODCONT + "SA1" + xFilial("SA1") + SA1->A1_COD + SA1->A1_LOJA ))
					RecLock("AC8",.T.)
					AC8->AC8_FILIAL := xFilial("AC8")
					AC8->AC8_CODCON := SU5->U5_CODCONT
					AC8->AC8_ENTIDA := "SA1"
					AC8->AC8_FILENT := xFilial("SA1")
					AC8->AC8_CODENT := SA1->A1_COD + SA1->A1_LOJA
					AC8->(MsUnlock())				
				endif

			Next

			IF AllTrim(oCliente:ultima_alteracao) > AllTrim(cNewDtMod)
				cNewDtMod := oCliente:ultima_alteracao
			Endif

			if ! Empty(cNewDtMod)
				PutMV("A1_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
			endif

		Next

	Else
		u_GwLog("meuspedidos.log","fSincClientes: Erro ao processar Json em FWJsonDeserialize para busca de clientes... "  )	
	Endif

	//2018-07-30 17:33:40
	// add 1s para nao trazer novamente estes clientes
	cNewDtMod := SubStr(cNewDtMod,1,17) + StrZero( Val(SubStr(cNewDtMod,18,2)) + 1 ,2)			

Return(cNewDtMod)



/*

fAddContatos - Adiciona no Json os contatos do cliente
Diego Bueno - 30/072018

*/

Static Function fAddContatos()

	Local cQuery := ''
	Local cJsonContatos := ''

	cJsonContatos += '        "contatos": ['

	// Busca todos contatos deste cliente
	cQuery := " 		SELECT U5_CODCONT AS CONTATO, "			
	cQuery += " 			ISNULL(U5_CONTAT, ' ') AS CON_NOME , " 
	cQuery += " 			ISNULL(U5_XIDMPED, ' ') AS CON_id,  "
	cQuery += " 			CASE WHEN ISNULL(U5_FONE, ' ') <> ' ' THEN LTRIM(RTRIM(ISNULL(U5_DDD, ' '))) +' ' + ISNULL(U5_FONE, ' ') ELSE '' END AS CON_TEL1, " 
	cQuery += " 			ISNULL(U5_XIDFONE, ' ') AS CIDTEL1, "
	cQuery += " 			CASE WHEN ISNULL(U5_CELULAR, ' ') <> ' ' THEN LTRIM(RTRIM(ISNULL(U5_DDD, ' '))) +' ' + ISNULL(U5_CELULAR, ' ') ELSE '' END AS CON_TEL2, " 			 
	cQuery += " 			ISNULL(U5_XIDCELU,' ') AS CIDTEL2, " 
	cQuery += " 			CASE WHEN ISNULL(U5_FAX, ' ') <> ' ' THEN LTRIM(RTRIM(ISNULL(U5_DDD, ' '))) +' ' + ISNULL(U5_FAX, ' ') ELSE '' END AS CON_TEL3, " 			 
	cQuery += " 			ISNULL(U5_XIDFAX, ' ') AS CIDTEL3,  "
	cQuery += " 			CASE WHEN ISNULL(U5_FCOM1, ' ') <> ' ' THEN LTRIM(RTRIM(ISNULL(U5_DDD, ' '))) +' ' + ISNULL(U5_FCOM1, ' ') ELSE '' END AS CON_TEL4, " 			 	
	cQuery += " 			ISNULL(U5_XIDFCO1, ' ') AS CIDTEL4,  "
	cQuery += " 			CASE WHEN ISNULL(U5_FCOM2, ' ') <> ' ' THEN LTRIM(RTRIM(ISNULL(U5_DDD, ' '))) +' ' + ISNULL(U5_FCOM2, ' ') ELSE '' END AS CON_TEL5, " 			 	
	cQuery += " 			ISNULL(U5_XIDFCO2, ' ') AS CIDTEL5, "
	cQuery += " 			CASE WHEN LEN(U5_EMAIL) > 5 AND U5_EMAIL LIKE '%@%' "       		
	cQuery += " 				AND U5_EMAIL NOT LIKE '%,%' AND U5_EMAIL  NOT LIKE '%;%' THEN ISNULL(U5_EMAIL, ' ') ELSE '' END AS CON_emails, "
	cQuery += " 			ISNULL(U5_XIDMAIL, ' ') AS CON_IDMAIL, " 
	cQuery += " 			ISNULL(UM_DESC,	' ') AS CON_cargo, "
	cQuery += " 			CASE WHEN AC8.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS CON_excluido "
	cQuery += " 	 FROM " + RetSQLName("SA1") + " SA1  "
	cQuery += " 	 INNER JOIN " + RetSQLName("AC8") + " AC8 ON AC8_FILENT = A1_FILIAL AND AC8_CODENT = A1_COD + A1_LOJA "
	cQuery += " 		AND AC8_ENTIDA = 'SA1' " // -- AND AC8.D_E_L_E_T_ = SA1.D_E_L_E_T_ "
	cQuery += "      INNER JOIN " + RetSQLName("SU5") + " SU5 ON U5_FILIAL = AC8_FILIAL AND U5_CODCONT = AC8_CODCON "
	cQuery += " 		AND AC8_ENTIDA = 'SA1' " //--AND AC8.D_E_L_E_T_ = SU5.D_E_L_E_T_ 
	cQuery += " 	 LEFT JOIN " + RetSQLName("SUM") + " CARGO ON  UM_CARGO = U5_FUNCAO AND SU5.D_E_L_E_T_ = CARGO.D_E_L_E_T_ "
	cQuery += "WHERE SA1.D_E_L_E_T_ <> '*' AND A1_COD = '" + CLIENTES->CODIGO + "' AND A1_LOJA = '" + CLIENTES->LOJA + "' "
	cQuery += "	GROUP BY U5_CODCONT,U5_CONTAT,U5_DDD, "
	cQuery += "		U5_XIDMPED,U5_FONE,U5_XIDFONE,U5_CELULAR,U5_XIDCELU,U5_FAX,U5_XIDFAX,U5_FCOM1, "
	cQuery += "		U5_XIDFCO1,U5_FCOM2,U5_XIDFCO2,U5_EMAIL,U5_XIDMAIL,UM_DESC,AC8.D_E_L_E_T_ "
	cQuery += "ORDER BY U5_CODCONT "

	MemoWrite("C:\temp\contatos.txt",cQuery)

	if Select("CONTATOS") > 0
		CONTATOS->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "CONTATOS"

	lJaTemContatos := .F.				
	cContAtual := ""

	While ! CONTATOS->(EOF()) 

		if cContAtual <> CONTATOS->CONTATO
			lJaTemTelefone := .F.
			cContAtual := CONTATOS->CONTATO
		endif

		IF lJaTemContatos
			cJsonContatos += ','
		endif
		cJsonContatos += '            {'	//abre contatos
		cJsonContatos += '                "telefones": [ ' // inicializa telefones						

		if ! Empty(CONTATOS->CON_TEL1)								 							

			cJsonContatos += '                {'
			cJsonContatos += '                    "numero": "' + u_GwTiraGraf(CONTATOS->CON_TEL1) + '",'
			cJsonContatos += '                    "tipo": "T" '
			if ! Empty(CONTATOS->CIDTEL1)
				cJsonContatos += '                    ,"id": ' + u_GwTiraGraf(CONTATOS->CIDTEL1) + ' '
			endif
			cJsonContatos += '                } ' 
			lJaTemTelefone := .T.
		endif

		if ! Empty(CONTATOS->CON_TEL2)

			if lJaTemTelefone
				cJsonContatos += ','
			endif
			cJsonContatos += '                {'
			cJsonContatos += '                    "numero": "' + u_GwTiraGraf(CONTATOS->CON_TEL2) + '",'
			cJsonContatos += '                    "tipo": "T" '
			if ! Empty(CONTATOS->CIDTEL2)
				cJsonContatos += '                    ,"id": ' + u_GwTiraGraf(CONTATOS->CIDTEL2) + ' '
			endif
			cJsonContatos += '                } ' 
			lJaTemTelefone := .T.
		endif

		if ! Empty(CONTATOS->CON_TEL3)

			if lJaTemTelefone
				cJsonContatos += ','
			endif
			cJsonContatos += '                {'
			cJsonContatos += '                    "numero": "' + u_GwTiraGraf(CONTATOS->CON_TEL3) + '",'
			cJsonContatos += '                    "tipo": "T" '
			if ! Empty(CONTATOS->CIDTEL3)
				cJsonContatos += '                    ,"id": ' + u_GwTiraGraf(CONTATOS->CIDTEL3) + ' '
			endif
			cJsonContatos += '                } ' 
			lJaTemTelefone := .T.
		endif

		if ! Empty(CONTATOS->CON_TEL4)

			if lJaTemTelefone
				cJsonContatos += ','
			endif
			cJsonContatos += '                {'
			cJsonContatos += '                    "numero": "' + u_GwTiraGraf(CONTATOS->CON_TEL4) + '",'
			cJsonContatos += '                    "tipo": "T" '
			if ! Empty(CONTATOS->CIDTEL4)
				cJsonContatos += '                    ,"id": ' + u_GwTiraGraf(CONTATOS->CIDTEL4) + ' '
			endif
			cJsonContatos += '                } ' 
			lJaTemTelefone := .T.
		endif

		if ! Empty(CONTATOS->CON_TEL5)

			if lJaTemTelefone
				cJsonContatos += ','
			endif
			cJsonContatos += '                {'
			cJsonContatos += '                    "numero": "' + u_GwTiraGraf(CONTATOS->CON_TEL5) + '",'
			cJsonContatos += '                    "tipo": "T" '
			if ! Empty(CONTATOS->CIDTEL5)
				cJsonContatos += '                    ,"id": ' + u_GwTiraGraf(CONTATOS->CIDTEL5) + ' '
			endif
			cJsonContatos += '                } ' 
			lJaTemTelefone := .T.
		endif	

		cJsonContatos += '                ],' // finaliza telefones

		cJsonContatos += '                "cargo": "' + u_GwTiraGraf(CONTATOS->CON_cargo) + '",'
		cJsonContatos += '                "nome": "' + u_GwTiraGraf(CONTATOS->CON_NOME) + '",'
		cJsonContatos += '       		  "emails": ['

		if ! Empty(AllTrim(CONTATOS->CON_emails))								
			cJsonContatos += '            	  {'
			cJsonContatos += '                	"email": "' + u_GwTiraGraf(CONTATOS->CON_emails) + '",'
			cJsonContatos += '                	"tipo": "T" '
			If ! Empty(CONTATOS->CON_IDMAIL)
				cJsonContatos += '                	,"id": ' + u_GwTiraGraf(CONTATOS->CON_IDMAIL) + ''
			endif
			cJsonContatos += '            	  }'
		endif
		cJsonContatos += '        		  ],'

		if ! Empty(CONTATOS->CON_id)
			cJsonContatos += '                "id": ' + u_GwTiraGraf(CONTATOS->CON_id) + ','
		endif
		cJsonContatos += '                "excluido": ' + u_GwTiraGraf(CONTATOS->CON_excluido) + ''
		cJsonContatos += '            }'
		lJaTemContatos := .T.
		CONTATOS->(DbSkip())
	End
	CONTATOS->(DbCloseArea())
	cJsonContatos += '        ],' // Fim Contatos	

Return(cJsonContatos)