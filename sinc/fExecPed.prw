#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

/*__________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Funçào    ¦ fExecPed  ¦ Autor ¦ Joao Elso      ¦ Data ¦ 2018/07/29	  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Fonte do ExecAuto 410 integracao Meus Pedidos			  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ Empadao                                                    ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
*/

User Function fExecPed(oPedido,cNewDtMod)
	Local lRet := .T.
	Local aArea := getArea()
	Local aCabec := {}
	Local aRet := {}
	Local aItens := {}
	local lEscreve := .T.
	local cTpPed := ""
	local cTpOp := ""
	local cGerFin := ""
	local nPosGer := 0

	private cRisco := ""
	PRIVATE lMsErroAuto := .F. 
	Private cMailResp     :=""
	Private cNumMP := ""
	Private dDataEnt := StoD("")

	default oPedido := {}
	default cNewDtMod := ""
	
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))
	
	if Empty(oPedido)
		cLog := "fExecPed: Erro Objeto oPedido retornado vazio de MeusPedidos..."
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		restArea(aArea)
		return {}
	endif

	
	cNumMP := alltrim(cValtoChar(oPedido:NUMERO))
	u_GwLog("meuspedidos.log","fExecPed: Iniciando escrita do Pedido Numero " + cNumMP +" no ERP.")

	//Verificar se o pedido ja esta no sistema.
	lEscreve := fVerInc(cValtoChar(oPedido:ID))

	if !(lEscreve)
		restArea(aArea)
		return{}
	endif

	//Pegar o tipo do pedido VENDA/BONIFICACAO/TROCA/AMOSTRA
	if !Empty(cValtoChar(oPedido:TIPO_PEDIDO_ID))
		cTpPed := alltrim(U_fGetTpPed(alltrim(cValtoChar(oPedido:TIPO_PEDIDO_ID)),1))
	endif

	//Carrega o cGerafin 1-Sim/2-Nao
	cGerFin := fCmpExt(oPedido:EXTRAS,"C5_XGERFIN")
	if alltrim(lower(cGerFin)) == 'sim'
		cGerFin = '1'
	endif
	if alltrim(lower(cGerFin)) == 'nao'
		cGerFin = '2'
	endif

	//Monta Cabeçalho do Pedido
	aCabec := fCab(oPedido,cTpPed,cGerFin)

	if Empty(aCabec)
		cLog := "fExecPed: Erro na geracao do cabecalho do Pedido Numero " + cNumMP + ", aCabec vazio!"
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		restArea(aArea)
		return {}
	endif

	//Pegar o gera financeiro atualizado para montar os tipos de operacao
	nPosGer := aScan(aCabec,{|x| x[1] == "C5_XGERFIN"})
	cGerfin := aCabec[nPosGer][2]


	//Tipo de Operação 15-Orçamento/14-VENDA/06-BONIFICACAO
	if(alltrim(cGerfin) == '1')
		cTpOp := '15'
	elseif cTpPed == "BONIFICACAO"
		cTpOp := '06'
	else
		cTpOp := '14'
	endif

	aRet := fItens(oPedido:ITEMS,cTpOp)

	if Empty(aRet)
		cLog := "fExecPed: Erro na geracao dos itens do Pedido Numero " + cNumMP + ", aRet vazio  !"
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		restArea(aArea)
		return {}
	endif

	If(aRet[2] <> oPedido:TOTAL )
		cLog := "fExecPed: Total do Pedido Numero " + cNumMP + " nao esta igual ao total dos itens."
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		restArea(aArea)
		return {}
	endif

	aItens := aRet[1]

	if Empty(aItens)
		cLog := "fExecPed: itens do Pedido Numero " + cNumMP + " nao carregados, aItens vazio!."
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		restArea(aArea)
		return {}
	endif

	Begin Transaction

		MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, 3) 

		If !lMsErroAuto    

			/*if(alltrim(cRisco) == "E")
			lRet := U_fSetStatusPV(allTrim(cValtoChar(oPedido:ID)),U_fGetStatus("ANALISE"))
			else

			endif*/

			lRet := U_fSetStatusPV(allTrim(cValtoChar(oPedido:ID)),U_fGetStatus("PENDENTE"))

			if  !Empty(cValtoChar(oPedido:ULTIMA_ALTERACAO)) .and. AllTrim(cValtoChar(oPedido:ULTIMA_ALTERACAO)) > AllTrim(cNewDtMod)
				cNewDtMod := oPedido:ULTIMA_ALTERACAO
			endif

			if!(lRet)
			endif
			u_GwLog("meuspedidos.log","fExecPed: Pedido Numero " + cNumMP + " incluido com sucesso.")

		Else

			cPath   := "meuspedidos\"
			cNomeArq  := "pedido_" + AllTrim(cNumMP) + ".txt"    			
			MostraErro(cPath, cNomeArq)//Salva o erro no arquivo e local indicado na funcao 			
			cLog := "fExecPed: Falha ao gravar Pedido Numero: "+ cNumMP + " no Protheus!" 		
			u_GwLog("meuspedidos.log",cLog)
			u_fGravaMeusPedidos( { "fExecPed","","","","","",u_GwTiraGraf(cLog),.F.} )
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog,cPath + cNomeArq)
			DisarmTransaction()
			lRet := .F.
		EndIf 

	End Transaction

	restArea(aArea)
return {lRet,cNewDtMod}

Static Function fCab(oPedido,cTpPed,cGerFin)

	local TempEnt := ""
	local aCab := {}
	local cTpTransp := ""
	local cCondPag := ""
	local cTranFob := alltrim(GetMV("MV_XMPFOB",,""))
	local cNat := ""
	local cDtUlt := ""
	local cId := ""
	local cDtEmi := ""
	local cFormPag := ""

	//local cVNome := ""

	cNumMP := alltrim(cValtoChar(oPedido:NUMERO))
	cOBS := u_GwTiraGraf(oPedido:OBSERVACOES)

	if cTpPed == "BONIFICACAO"
		cNat := alltrim(getMV("MV_XNATB",,"10106"))
		cCondPag := alltrim(getMV("MV_XCONB",,"023"))
		cFormPag := alltrim(getMv("MV_XFORB",,"FID"))
	elseif cTpPed == "AMOSTRA"
		cGerFin := '1'
		cNat := alltrim(getMV("MV_XNATA",,"10107"))
		cCondPag := alltrim(getMV("MV_XCONA",,"248"))
		cFormPag := alltrim(getMv("MV_XFORA",,"CO"))
	elseif cTpPed == "TROCA"
		cGerFin := '1'
		cNat := alltrim(getMV("MV_XNATT",,"DEV./TROCA"))
		cCondPag := alltrim(getMV("MV_XCONT",,"012"))
		cFormPag := alltrim(getMv("MV_XFORT",,"FID"))
	else
		cNat := alltrim(getMV("MV_XNATV",,"10101"))
	endif

	if Empty(cFormPag)
		cFormPag := fGetForm(allTrim(cValtoChar(oPedido:FORMA_PAGAMENTO_ID)))
	endif

	cDtEmi := alltrim(cValtoChar(oPedido:DATA_EMISSAO))

	TempEnt := fCmpExt(oPedido:EXTRAS,"C5_FECENT")
	dDataEnt := StoD(subStr(TempEnt,1,4)+ subStr(TempEnt,6,2) + subStr(TempEnt,9,2))
	if Empty(dDataEnt)

		dDataEnt := StoD(subStr(alltrim(cValtoChar(oPedido:DATA_EMISSAO)),1,4) + subStr(alltrim(cValtoChar(oPedido:DATA_EMISSAO)),6,2) + subStr(alltrim(cValtoChar(oPedido:DATA_EMISSAO)),9,2) )		
		if Empty(dDataEnt)
			cLog := "fExecPed: Erro ao carregar a data de entrega do Pedido " + cNumMP
			u_GwLog("meuspedidos.log",cLog)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
			return {}
		endif
	endif

	cTpTransp := iif(alltrim(cValtoChar(oPedido:TRANSPORTADORA_ID)) $ cTranFob,'F','C')

	if Empty(alltrim(oPedido:ULTIMA_ALTERACAO))
		cLog := "fExecPed: Erro ultima data de alterecao vazia verifique o campo ULTIMA_ALTERACAO do Pedido " + cNumMP
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		return {}
	else
		cDtUlt := alltrim(oPedido:ULTIMA_ALTERACAO)
	endif

	cId := alltrim(cValtoChar(oPedido:ID))

	DbSelectArea("SA3")
	if !SA3->(DbOrderNickname("IDVENDEDOR"))
		cLog := "fExecPed: indice de nickname IDVENDEDOR não encontrado para tabela SA3 para gravar o Pedido " + cNumMP
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		return {}

	elseif SA3->(DbSeek(cValtoChar(oPedido:CRIADOR_ID),.F.))
		cVend := SA3->A3_COD
	else
		//cVNome := U_fGetNoVend(alltrim(cValtoChar(oPedido:CRIADOR_ID)))
		cLog := "fExecPed: Vendedor de Id: "+alltrim(cValtoChar(oPedido:CRIADOR_ID))+" nao encontrado para gravar o Pedido " + cNumMP
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		u_fGravaMeusPedidos( { "fExecPed","","","","","","fExecPed: Vendedor de Id: "+alltrim(cValtoChar(oPedido:CRIADOR_ID))+ " nao encontrado.",.F.} )
		return {}
	endif

	if Empty(cCondPag)
		DbSelectArea("SE4")
		if !SE4->(DbOrderNickname("IDCONDPAG"))
			cLog := "fExecPed: indice de nickname IDCONDPAG não encontrado para tabela SE4 para gravar pedido " + cNumMP
			u_GwLog("meuspedidos.log",cLog)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
			return {}
		elseif SE4->(DbSeek(cValtoChar(oPedido:CONDICAO_PAGAMENTO_ID),.F.))
			cCondPag := SE4->E4_CODIGO
		else
			cLog := "fExecPed: Condicao de pagamento de Id: "+alltrim(cValtoChar(oPedido:CONDICAO_PAGAMENTO_ID))+" nao encontrado para gravar o Pedido " + cNumMP
			u_GwLog("meuspedidos.log",cLog)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		endif
	endif

	DbSelectArea("SA1")
	if ! SA1->(DbOrderNickname("IDCLIENTES"))
		cLog := "fExecPed: indice de nickname IDCLIENTES não encontrado para tabela SA1 para gravar o Pedido " + cNumMP
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		return {}
	elseif SA1->(DbSeek( cValtoChar(oPedido:CLIENTE_ID),.F.))

		if(alltrim(SA1->A1_CGC) <> alltrim(oPedido:CLIENTE_CNPJ))
			cLog := "fExecPed: Cliente de Id: "+alltrim(cValtoChar(oPedido:CLIENTE_ID))+" nao possiu CNPJ igual ao do ERP para gravar o Pedido " + cNumMP		
			u_GwLog("meuspedidos.log",cLog)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
			u_fGravaMeusPedidos( { "fExecPed","","","","","","fExecPed: Cliente de Id: "+alltrim(cValtoChar(oPedido:CLIENTE_ID))+" nao possiu CNPJ igual ao do ERP.",.F.} )
			return {}
		endif
		cRisco := SA1->A1_RISCO
		cClient := SA1->A1_COD
		cXNomCli := SA1->A1_NOME
		cXFantazia := SA1->A1_NREDUZ
		cLoja := SA1->A1_LOJA


		if Empty(cGerFin)
			cGerFin := SA1->A1_XGFINAN
		endif

		cTpCli := SA1->A1_TIPO

		if Empty(cCondPag)
			cCondPag := SA1->A1_CONDPAG
		endif

		if Empty(cFormPag)
			cFormPag := SA1->A1_XFORPG
		endif

		cTabPrc := SA1->A1_TABELA
		cRota:= SA1->A1_REGIAO
		cDesRota:= SA1->A1_XDESCRO
	else
		cLog := "fExecPed: Cliente de Id: "+alltrim(cValtoChar(oPedido:CLIENTE_ID))+" nao encontrado para gravar o Pedido " + cNumMP
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		u_fGravaMeusPedidos( { "fExecPed","","","","","","fExecPed: Cliente de Id: "+alltrim(cValtoChar(oPedido:CLIENTE_ID))+" nao encontrado.",.F.} )
		return {}
	endif

	if Empty(cCondPag)
		cLog := "fExecPed: Condicao de pagamento em branco para gravar o Pedido " + cNumMP	
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		return {}
	endif

	if Empty(cFormPag)
		cLog := "fExecPed: Erro ao carregar a forma de pagamento do pedido " + cNumMP
		u_GwLog("meuspedidos.log",cLog)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
		return {}
	endif

	//aadd(aCab,{"C5_NUM"   ,cNPed,Nil})
	aadd(aCab,{"C5_TIPO" ,"N",Nil})//Inicialmente nao trata devolucao
	aadd(aCab,{"C5_CLIENTE",cClient,Nil})
	aAdd(aCab,{"C5_XNOMCLI",cXNomCli,Nil})
	aAdd(aCab,{"C5_XNONFAN",cXFantazia,Nil})
	aadd(aCab,{"C5_LOJAENT",cLoja,Nil})
	aadd(aCab,{"C5_LOJACLI",cLoja,Nil})
	aAdd(aCab,{"C5_XGERFIN",cGerFin,Nil})
	aAdd(aCab,{"C5_CLIENT ",cClient,Nil})
	aAdd(aCab,{"C5_NATUREZ",cNat,Nil})
	aAdd(aCab,{"C5_TIPOCLI",cTpCli,Nil})
	aAdd(aCab,{"C5_CONDPAG",cCondPag,Nil})
	aAdd(aCab,{"C5_TABELA ",cTabPrc,Nil})
	aAdd(aCab,{"C5_VEND1",cVend,Nil})
	aAdd(aCab,{"C5_TPFRETE",cTpTransp,NIL})
	aAdd(aCab,{"C5_XOBS",cOBS,Nil})
	aAdd(aCab,{"C5_FECENT",dDataEnt,Nil})
	aAdd(aCab,{"C5_XROTA",cRota,Nil})
	aAdd(aCab,{"C5_XDROTA",cDesRota,Nil})
	aAdd(aCab,{"C5_XFORPG",cFormPag,Nil})
	aAdd(aCab,{"C5_XULTALT",cDtUlt,Nil})
	aAdd(aCab,{"C5_XIDMPED",cId,Nil})
	aAdd(aCab,{"C5_XMPDEMI",cDtEmi,Nil})
	aAdd(aCab,{"C5_XNUMMP",cNumMP,Nil})
return aCab

static function fGetForm(cId)
	local cFormPag := ""
	Local cQry := ""
	Local cEol := chr(13)+chr(10)

	cQry := " SELECT SX5.X5_CHAVE, SX5.X5_DESCRI,SX5.X5_DESCSPA " + cEol
	cQry += " FROM "+RetSqlName("SX5")+" SX5 " + cEol
	cQry += " WHERE SX5.D_E_L_E_T_<>'*' AND SX5.X5_TABELA = '24' AND SX5.X5_DESCSPA = '"+cId+"'" + cEol

	If Select("TMP") > 0
		TMP->(DbCloseArea())
	EndIf

	MemoWrite("C:\temp\fGetForm.sql",cQry)

	cQry := ChangeQuery(cQry)

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry), "TMP", .F., .T.)

	If(TMP->(!EoF()) .and. alltrim(TMP->X5_DESCSPA) == cId)
		cFormPag := TMP->X5_CHAVE
	else
		TMP->(DbCloseArea())
		cFormPag := ""
	endif


return cFormPag

static function fItens(Itens,cTpOp)
	local aItens := {}
	local aLinha := {}
	local xCount := 1
	local nItem := 1
	local xTamItem := TamSX3("C6_ITEM")
	local ValTot := 0
	local cItem := ""
	local cProduto := ""
	local QtdVen := 0
	local PrcVen := 0
	local PrUnit := 0
	local Valor :=  0

	for xCount := 1 to len(Itens)
		//Vai escrever linha excluida??
		if (Itens[xCount]:EXCLUIDO)
			LOOP
		endif

		DbSelectArea("SB1")
		if !SB1->(DbOrderNickname("IDPRODUTOS"))
			cLog := "fExecPed: indice de nickname IDPRODUTOS não encontrado para tabela SB1 para gravar o Pedido " + cNumMP
			u_GwLog("meuspedidos.log",cLog)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
			return {}
		elseif SB1->(DbSeek( cValtoChar(Itens[xCount]:PRODUTO_ID),.F.))
			if(alltrim(SB1->B1_COD) <> alltrim(Itens[xCount]:PRODUTO_CODIGO))
				cLog := "fExecPed: Produto de Id: "+alltrim(cValtoChar(Itens[xCount]:PRODUTO_ID))+" nao possiu codigo do produto igual ao do ERP para gravar o Pedido " + cNumMP			
				u_GwLog("meuspedidos.log",cLog)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
				return {}
			endif

			cItem := StrZero(nItem,xTamItem[1])
			cProduto := SB1->B1_COD
			QtdVen := Itens[xCount]:QUANTIDADE
			PrcVen := Itens[xCount]:PRECO_BRUTO
			PrUnit := Itens[xCount]:PRECO_LIQUIDO
			Valor :=  Itens[xCount]:SUBTOTAL

		else
			cLog := "fExecPed: Produto de Id: "+alltrim(cValtoChar(Itens[xCount]:PRODUTO_ID))+" nao encontrado para gravar o Pedido " + cNumMP
			u_GwLog("meuspedidos.log",cLog)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cLog)
			return {}
		endif

		aLinha := {}
		aadd(aLinha,{"C6_ITEM",cItem,Nil})    
		aadd(aLinha,{"C6_PRODUTO",cProduto,Nil})    
		aadd(aLinha,{"C6_QTDVEN",QtdVen,Nil})    
		aadd(aLinha,{"C6_PRCVEN",PrcVen,Nil})    
		aadd(aLinha,{"C6_PRUNIT",PrUnit,Nil})    
		aadd(aLinha,{"C6_VALOR",Valor,Nil})    
		aadd(aLinha,{"C6_OPER",cTpOp,Nil})
		aadd(aLinha,{"C6_ENTREG",dDataEnt,Nil})
		
		nItem += 1
		ValTot += Itens[xCount]:SUBTOTAL
		aAdd(aItens,aLinha)
	next xCount

return {aItens,ValTot}

static function fVerInc(cId)
	local lEscreve := .T.
	local cQuery

	cQuery := "SELECT SC5.C5_XIDMPED, SC5.C5_FILIAL, SC5.C5_NUM," + cEol
	cQuery += "CASE WHEN D_E_L_E_T_ = '*' THEN '.T.' WHEN D_E_L_E_T_ = '' THEN '.F.' END AS DELETADO" + cEol
	cQuery += "FROM SC5010 SC5" + cEol
	cQuery += "WHERE SC5.C5_XIDMPED = '"+cId+"'"

	//MemoWrite("C:\temp\fVerInc.sql",cQuery)

	cQuery := ChangeQuery(cQuery)

	if Select("VERPED") > 0
		VERPED->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "VERPED"

	DbSelectArea("VERPED")
	VERPED->(dbGoTop())

	if (VERPED->(!EoF()))
		lEscreve := .F.
		if(VERPED->DELETADO == '.T.')
			u_GwLog("meuspedidos.log","fExecPed: Pedido de Id:" +alltrim(cId)+ " ja existe no sistema numero :"+alltrim(VERPED->C5_NUM) + " e esta deletado.")
		elseif(VERPED->DELETADO == '.F.')			 	
			u_GwLog("meuspedidos.log","fExecPed: Pedido de Id:" +alltrim(cId)+ " ja existe no sistema numero :"+alltrim(VERPED->C5_NUM))
		endif

	endif

return lEscreve


Static Function fCmpExt(aExtras,cNome)

	local cReturn := ""
	local xCount := 1

	default cNome := ""

	if Empty(cNome)
		u_GwLog("meuspedidos.log","fCmpExt: Erro parametro cNome vazio!")
		return cReturn
	endif

	DbSelectArea("ZZ2")
	ZZ2->(DbSetOrder(1))//ZZ2_NOME

	if ZZ2->(DbSeek(cNome))
		for xCount := 1 to len(aExtras)
			if(alltrim(cValtoChar(aExtras[xCount]:CAMPO_EXTRA_ID)) == alltrim(ZZ2->ZZ2_ID))
				cReturn := cValtoChar(aExtras[xCount]:VALOR)
				EXIT
			endif
		next xCount
	else
		return cReturn
	endif

return cReturn
