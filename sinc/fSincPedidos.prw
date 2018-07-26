#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  fSincPedidos       ºAutor ³Diego Bueno      º Data ³   15/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Sincroniza Pedidos de Vendas com MeusPedidos               º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Protheus x MeusPedidos.com.br                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function fSincPedidos(lJob)
	Local cURLBase      := ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cC5_XULTAL    := ""
	Local cNewDtMod		:= ""
	Local oPedido       := nil
	Local aHttpGet      := {}
	Local aHttpPost     := {}
	Local aHttpPut      := {}		
	Local cId           := ''
	Local aRet := {}
	Local xCount := 1
	Local aArea := getArea()
	Private cEol	    := chr(13)+chr(10)
	Private cMailResp   := ""

	Default lJob        := .F.

	If ! lJob  .And. Select("SX2") == 0 // Via JOB
		lJob := .T.
	endif

	if lJob	
		RpcSetType(3)	
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SC5" //USER "Admin" PASSWORD "senha"	
	endif

	u_GwLog("meuspedidos.log","fSincPedidos: Iniciando sincronizacao dos Pedidos de Vendas..")

	cURLBase      := Alltrim( GetMV("MV_XMPPEDI",,"") )
	cC5_XULTAL    := AllTrim(GetMV("C5_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp         := AllTrim(GetMV("MV_GWMAILR",,""))

	//MemoWrite("C:\temp\urlGetPedidos.txt",cURLBase+"&alterado_apos=" + StrTran(cC5_XULTAL," ","%20"))

	aHttpGet := u_GetJson(cURLBase+"&alterado_apos=" + StrTran(cC5_XULTAL," ","%20"))
	
	cJson    := aHttpGet[1]
	cRetHead := aHttpGet[2]
	cCodHttp := aHttpGet[3]

	If "200" $ cCodHttp 

		if FWJsonDeserialize( cJson, @oPedido )

			for	xCount := 1 to Len(oPedido)
				aRet := U_fExecPed(oPedido[xCount],cNewDtMod)
			next xCount

			if Empty(aRet)

			else
				cNewDtMod := aRet[2]
			endif

		else
			cHtml := "fSincPedidosA: Erro ao processar FWJsonDeserialize do Pedido de Vendas " ;
			+ " com Json: " + cJson   
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif
		
	endif

	if ! Empty(cNewDtMod)
		PutMV("C5_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincPedidos: Finalizada sincronizacao dos Pedidos. Ultima sincronizacao " + GetMV("C5_XULTALT",,"") )

	cQuery := "SELECT SC5.C5_XIDMPED, SC5.C5_FILIAL, SC5.C5_NUM, SC5.C5_CLIENTE,SC5.C5_LOJACLI,SC5.C5_XMPDEMI,SC5.C5_VEND1,SC5.C5_CONDPAG,SC5.C5_XULTALT, SC5.C5_TPFRETE, SC5.C5_FECENT, SC5.C5_XGERFIN, C5_TABELA,C5_MENNOTA ,SC5.C5_EMISSAO," + cEol
	cQuery += "CASE WHEN D_E_L_E_T_ = '*' THEN '.T.' WHEN D_E_L_E_T_ = '' THEN '.F.' END AS DELETADO" + cEol
	cQuery += "FROM SC5010 SC5" + cEol
	cQuery += ""
	cQuery += "WHERE C5_XULTALT = ''"

	MemoWrite("C:\temp\fSincPedidos.sql",cQuery)

	cQuery := ChangeQuery(cQuery)

	if Select("SINCPED") > 0
		SINCPED->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "SINCPED"

	DbSelectArea("SINCPED")
	SINCPED->(dbGoTop())

	While (SINCPED->(! EoF()))
		cNewDtMod := fProcPed(SINCPED->C5_XIDMPED,SINCPED->C5_FILIAL,SINCPED->C5_NUM,SINCPED->C5_CLIENTE,SINCPED->C5_LOJACLI,SINCPED->C5_XMPDEMI,SINCPED->C5_VEND1,SINCPED->C5_CONDPAG,SINCPED->C5_XULTALT,SINCPED->DELETADO,SINCPED->C5_TPFRETE,SINCPED->C5_FECENT,SINCPED->C5_XGERFIN,SINCPED->C5_TABELA,SINCPED->C5_MENNOTA,SINCPED->C5_EMISSAO)
		SINCPED->(DbSkip())
	enddo

	if ! Empty(cNewDtMod)
		PutMV("C5_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif
	
	u_GwLog("meuspedidos.log","fSincPedidos: Finalizada sincronizacao dos Pedidos de Vendas. Atualizado C5_XULTALT para " + AllTrim(GetMV("C5_XULTALT",,"")))
	
	FreeObj(oPedido)
	restArea(aArea)
Return

static function fProcPed(cIdPedido,Filial,cNum,cCliente,cLoja,cDtEmi, cVend,cCondPag,cDtUlt,cDelet,cTpFre,cDtEnt,cGerFin,cTab,cObs,cEmi)

	local cNewDtMod := ""
	local cURLBase  := alltrim( GetMV("MV_XMPPED",,"") )
	local cURLCanc  := alltrim(GetMV("MV_XMPCPE"))
	local lEnviaPC  := GetMV("MV_XMPENVP",,.F.)

	//Se não tem ID dos meus pedidos e não está deletado, INCLUSÃO nos Meus Pedidos
	if lEnviaPC .And. Empty(cIdPEdido) .and. cDelet = '.F.'

		cJson := fMontaJson(Filial,cNum,cCliente,cLoja,cDtEmi, cVend,cCondPag,cDtUlt,cDelet,cTpFre,cDtEnt,cGerFin,cTab,cObs,cEmi,1)
		if Empty(cJson)
		else
			MemoWrite("C:\temp\cJsonI.txt",cJson)
		endif

		aHttpPost		:= u_PostJson(cURLBase ,cJson)
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]

		If  cCodHttp $ "201/200"

			cQuery := "UPDATE "+RetSQLName("SC5")+" "  							
			cQuery += " SET C5_XULTALT = '" + cNewDtMod + "', C5_XIDMPED = '"+alltrim(U_GwTiraGraf(cId))+"' "						
			cQuery += "  WHERE C5_FILIAL = '"+AllTrim(Filial)+"'AND C5_NUM = '" + AllTrim(cNum) +"' "

			If tcsqlexec(cQuery) < 0
				cHtml := "fSincPedidos: Falha ao atualizar o campo C5_XULTALT no ERP Pedido de Id: " +  AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif	

			U_fSetStatusPV(cId,"198")

		else
			// enviar email falha de alteração de pedido
			cHtml := "fSincPedidos: Erro ao processar retorno da Inclusão do Pedido de Id: " +   AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum) 
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif

		u_GwLog("meuspedidos.log","fSincPedidos: Finalizada Inclusão do Pedido de Id :" + AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum) )
	endif

	//Se tem ID do Meus Pedidos e não está deletado ALTERAÇÃO
	if ! Empty(cIdPEdido) .and. cDelet = '.F.'

		cJson := fMontaJson(Filial,cNum,cCliente,cLoja,cDtEmi, cVend,cCondPag,cDtUlt,cDelet,cTpFre,cDtEnt,cGerFin,cTab,cObs,cEmi,2)

		MemoWrite("C:\temp\cJson.txt",cJson)

		aHttpPut		:= u_PutJson(cURLBase + "/" +  alltrim(cIdPEdido), cJson)
		cJson    		:= aHttpPut[1]
		cRetHead 		:= aHttpPut[2]
		cCodHttp 		:= aHttpPut[3]
		cId          	:= aHttpPut[4]
		cNewDtMod	    := aHttpPut[5]

		If cCodHttp $ "200/201"

			// Deve-se atualizar tambem registro deletados
			cQuery := "UPDATE "+RetSQLName("SC5")+" "
			cQuery += " SET C5_XULTALT  = '"+alltrim(cNewDtMod)+"' "
			cQuery += "WHERE C5_XIDMPED = '"+alltrim(cIdPEdido)+"'"

			If tcsqlexec(cQuery) < 0

				cHtml := "fSincPedidos: Falha ao atualizar o campo C5_XULTALT no ERP Pedido de Id: " +  AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum) 
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)

			endif
		else
			// enviar email falha de inclusao cliente
			cHtml := "fSincPedidos: Erro ao processar retorno do Alteração do Pedido de Id: " +   AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum)
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif

		u_GwLog("meuspedidos.log","fSincPedidos: Finalizada Alteração do Pedido de Id :" + AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum) )

	endif

	//Se tem ID do Meus Pedidos e está deletado CANCELAR
	if ! Empty(cIdPEdido) .and. cDelet = '.T.'

		aHttpPost		:= u_PostJson(cURLCanc + '/' + alltrim(cIdPedido))
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]

		If cCodHttp $ "201/200"

			cQuery := "UPDATE "+RetSQLName("SC5")+" "  							
			cQuery += " SET C5_XULTALT = '"+cNewDtMod + "' "						
			cQuery += "  WHERE C5_XIDMPED = '" + AllTrim(cIdPedido) +"' "

			If tcsqlexec(cQuery) < 0
				cHtml := "fSincPedidos: Falha ao atualizar o campo C5_XULTALT no ERP Pedido de Id: " +  AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum)    
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif	

		else
			// enviar email falha de alteração de pedido
			cHtml := "fSincPedidos: Erro ao processar retorno do cancelamento do Pedido de Id: " +   AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum)
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif

		u_GwLog("meuspedidos.log","fSincPedidos: Finalizada Cancelamento do Pedido de Id :" + AllTrim(cIdPedido) +  "e numero: " + AllTrim(cNum) )

	endif

return cNewDtMod

Static Function fMontaJson(Filial,cNum,cCliente,cLoja,cDtEmi, cVend,cCondPag,cDtUlt,cDelet,cTpFre,cDtEnt,cGerFin,cTab,cObsPed,cEmi,cNOp)

	local cJson := ""
	local cTranFob := alltrim(GetMV("MV_XMPFOB",,""))
	local cTranCIF := alltrim(GetMV("MV_XMPCIF",,""))
	local cCliId := ""  		//cliente_id
	//local cDtEmissao := ""		//data_emissao 			//Criar campo customizado
	local cContId := ""			//contato_id 			//Não mandar
	local cTransId := ""		//transportadora_id 	//Olhar o tipo C5_TPFRETE (SE (C) SENÃO (F))
	local cEndId :=""			//endereco_entrega_id 	//Não mandar
	local cCriaId := ""			//criador_id			
	local cCondId := ""			//condicao_pagamento_id	
	//local cCondPag :=""			//condicao_pagamento	//E4_DESC informar somente se não tiver o campo condicao_pagamento_id	
	local cTpPedId :=""			//tipo_pedido_id		//Tratar tes 50  Bonificação, 51 Amostra e 52 Troca  (C6_OPER = 14 OU 15 É VENDA, 7 OU R OU W OU 16 É BONIFICAÇÃO, 27 AMOSTRA, 6  TROCA) OUTRO DA ERRO
	local cObs := ""			//observacoes			//
	//14 GERFIN = N
	//15 GER FIN = S
	local cExtras := ""			//extras
	local cItens := ""			//itens

	default cNOp := ""

	if Empty(cNOp)
	endif

	cCliId := U_fGetCliente(cCliente+cLoja,2)

	if Empty(cCliId)
		// Erro
	endif

	if(cNOp == 1)
		cDtEmissao := substr(cEmi,1,4) +"-"+ substr(cEmi,5,2) +"-"+ substr(cEmi,7,2)
	endif

	cContId := "null"	
	cTransId := iif(alltrim(cTpFre) == 'F', cTranFob,cTranCIF)
	cEndId := "null"
	cCriaId := U_fGetVend(cVend,2)
	cCondId := U_fGetCond(cCondPag,2)
	//cCondPag := 
	cTpPedId := U_fGetTpPed(Filial,cNum)
	cObs :=  alltrim(cObsPed)

	cExtras := fMontaExtras(cDtEnt,cGerFin)
	cItens := fMontaItens(Filial,cNum,cTab)
	if(Empty(cItens))
		return ""
	endif

	cJson := "{"
	cJson += '"cliente_id":'+cCliId+','
	if(cNOp == 1)
		cJson += '"data_emissao":"'+cDtEmissao+'",'
	endif
	cJson += '"contato_id":'+cContId+','
	cJson += '"transportadora_id":'+cTransId+','
	cJson += '"endereco_entrega_id":'+ cEndId+','
	cJson += '"criador_id":'+cCriaId+','
	cJson += '"condicao_pagamento_id":'+cCondId+','
	//cJson += '"condicao_pagamento":"'++'"'
	cJson += '"tipo_pedido_id":'+cTpPedId+','
	cJson += '"observacoes":"'+cObs+'",'

	cJson += '"extras":'+cExtras+','
	cJson += '"itens":'+cItens
	cJson += '}'

return cJson

static function fMontaExtras(cDtEnt,cGerFin)
	local cExtras := ""

	cGerFin := iif(cGerFin == '1', 'Sim', 'Nao')

	cExtras := '['
	cExtras += '{"id":'+U_fGetCmpEx("C5_FECENT")+',"valor":"'+substr(cDtEnt,1,4) + '-'+substr(cDtEnt,5,2) +'-'+substr(cDtEnt,7,2) +'"},'		//Data de Entrega
	cExtras += '{"id":'+U_fGetCmpEx("C5_XGERFIN")+',"valor":"'+cGerFin+'"}'			//Gera Financeiro
	cExtras += ']'

return cExtras

static function fMontaItens(Filial,cNum,cTab)

	local cItens := ""
	local cQry := ""

	local lVirgula := .F.

	local cProdId := ""			//produto_id
	local cTabId := "" 			//tabela_preco_id	 //DA0 X ID C5_TAB
	local cQuant := "" 			//quantidade
	//	local cQtdGra := ""			//quantidade_grades //nÃO PASSAR
	local cPrcBru := ""			//preco_bruto	//C6_PRUNIT
	local cDesc := ""			//descontos	//C6_VALDESC(ipi)
	local cPrcLiq := ""			//preco_liquido // C6_PRCVEN
	local cMoeda := ""			//moeda // 0 PARA REAL
	local cCotMoe:= ""			//cotacao_moeda //1 
	local cObs := ""			//observacoes
	//local cIpi := "" 			//ipi IF(TES CACL IPI -> ALQ B1, C6_VALOR*ALI/QUANT)
	//local cTpIpi := ""			//tipo_ipi VALOR
	local cSt := ""				//st 0
	local cPrcMin := ""			//preco_minimo //C6_VALUNIT

	cTabId := u_fGetTPrc(cTab,2)
	cMoeda := alltrim(cValtoChar(0))
	cCotMoe := alltrim(cValtoChar(1))

	cQry := "SELECT SC6.C6_PRODUTO,SC6.C6_QTDVEN,SC6.C6_PRUNIT,SC6.C6_VALOR, SC6.C6_VALDESC,SC6.C6_PRCVEN "
	cQry += "FROM " +RetSqlName("SC6")+ " SC6 "
	cQry += "WHERE SC6.D_E_L_E_T_ <> '*' AND SC6.C6_FILIAL = '"+Filial+"' AND SC6.C6_NUM = '"+cNum+"' "

	MemoWrite("C:\temp\fMontaItens.sql",cQry)

	cQry := ChangeQuery(cQry)

	if Select("ITENS") > 0
		ITENS->(DbCloseArea())
	endif

	TcQuery cQry New Alias "ITENS"

	cItens := '['

	lVirgula := .F.
	while ITENS->(!EoF())

		if(lVirgula)
			cItens += ','
		endif

		cProdId := U_fGetProd(ITENS->C6_PRODUTO,2)

		if Empty(cProdId)
		endif
		cQuant := alltrim(cValtoChar(ITENS->C6_QTDVEN))
		cPrcBru := alltrim(cValtoChar(ITENS->C6_PRUNIT))
		cDesc := alltrim(cValtoChar(iif(Empty(ITENS->C6_VALDESC),"",ITENS->C6_VALDESC)))
		cPrcLiq := alltrim(cValtoChar(ITENS->C6_PRCVEN))
		cObs := ""
		//cIpi := alltrim(cValtoChar(0))
		//cTpIpi := "V"
		cSt := alltrim(cValtoChar(0))
		cPrcMin := alltrim(cValtoChar(ITENS->C6_PRCVEN))
		/*
		DbSelectArea("SF4")
		SF4->(DbSetOrder(1))//F4_FILIAL, F4_CODIGO, R_E_C_N_O_, D_E_L_E_T_
		if SF4->(DbSeek(xFilial("SF4")+ITENS->C6_TES))
		if(SF4->F4_IPI = 'S')
		cIpi := 
		endif
		else
		cIpi := 0
		endif


		*/

		cItens += '{'
		cItens += '"produto_id":'+cProdId+','
		cItens += '"tabela_preco_id":'+cTabId+','
		cItens += '"quantidade":'+cQuant+','
		cItens += '"preco_bruto":'+cPrcBru+','
		cItens += '"descontos":['+cDesc+'],'
		cItens += '"preco_liquido":'+cPrcLiq+','
		cItens += '"moeda":' +cMoeda+','
		cItens += '"cotacao_moeda":' +cCotMoe+','
		cItens += '"observacoes":"'+cObs+'",'
		//cItens += '"ipi:"' + cIpi +','
		//cItens += '"tipo_ipi":"' +cTpIpi+'",'
		cItens += '"st":' + cSt +','
		cItens += '"preco_minimo":' +cPrcMin
		cItens += '}'

		if!(lVirgula)
			lVirgula := .T.
		endif
		ITENS->(DbSkip())
	enddo
	cItens += ']'

	MemoWrite("C:\temp\cItens.sql",cItens)


return cItens