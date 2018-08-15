#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincCCondPgto    บAutor ณDiego Buenoบ Data ณ   21/06/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Cond.Pagto x Clientes com MeusPedidos           บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function fSincCCondPgto(lJob)
	Local cURLBase      := ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cA1_XULTCPG   := ""
	Local cNewDtMod		:= ""
	Local aHttpPost     := {}		
	//Local cId           := '' este nao tem ID e nem delete

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

	u_GwLog("meuspedidos.log","fSincCliCondPgto: Iniciando sincronizacao das Cond.Pagto x Clientes")
	
	cURLBase      := Alltrim( GetMV("MV_XMPA1E4",,"") )
	cA1_XULTCPG   := AllTrim(GetMV("A1_XULTCPG",,"")) // Obtem a ultima data/hora de sincronizacao	
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de Item da Tabela de precos do Protheus para serem atualizados em Meus Pedidos  
	cQuery += " 	 SELECT A1_COD AS CODIGO, "
	cQuery += " 		A1_LOJA AS LOJA, "
	cQuery += " 		E4_XIDMPED AS condicoes_pagamento_liberadas, " 			
	cQuery += " 		A1_XULTCPG AS ultima_alteracao,  "
	cQuery += " 		A1_XIDMPED cliente_id, "
	cQuery += " 		CASE WHEN SA1.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido "  
	cQuery += " 	FROM " + RetSQLName("SA1") + " SA1 "
	cQuery += " 	INNER JOIN " + RetSQLName("SE4") + " SE4 ON E4_FILIAL = '" + xFilial('SE4') + "' " 
	cQuery += " 		AND A1_FILIAL = '" + xFilial('SA1') + "' AND A1_COND = E4_CODIGO "
	cQuery += " 		AND SA1.D_E_L_E_T_ = SE4.D_E_L_E_T_ "
	cQuery += " 	WHERE E4_XIDMPED <> ' ' AND A1_XIDMPED <> ' ' " 
	cQuery += " 		AND (A1_XULTCPG = ' ' OR A1_XULTCPG > '" + cA1_XULTCPG + "') " 

	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\CONDCLI.txt",cQuery)

	if Select("CONDCLI") > 0
		CONDCLI->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "CONDCLI"

	dbSelectArea("CONDCLI")
	CONDCLI->(dbGoTop())

	While ! CONDCLI->( EOF() )

		cJson := '{'
		cJson += '	"cliente_id": ' + AllTrim(CONDCLI->cliente_id) + ','
		cJson += '  "condicoes_pagamento_liberadas": [ ' + AllTrim(CONDCLI->condicoes_pagamento_liberadas) + ' ]'			 
		cJson += '}'							

		MemoWrite("C:\temp\CONDCLI.json",cJson)

		// Inclui nova Item da Tabela em Meus Pedidos
		aHttpPost		:= u_PostJson(cUrlBase,cJson)
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]

		If "200" $ cCodHttp 	

			cQuery := "UPDATE "+RetSQLName("SA1")+" "
			cQuery += " SET A1_XULTCPG = '"+cNewDtMod+"' "						
			cQuery += "  WHERE A1_COD = '" + CONDCLI->codigo + "' AND A1_LOJA =  '" + CONDCLI->loja + "' "   

			If tcsqlexec(cQuery) < 0
				cHtml := "fSincCliCondPgto: Falha ao atualizar data no ERP da Vendedor x Cliente: " +  AllTrim(CONDCLI->codigo) + " - " + AllTrim(CONDCLI->LOJA) + " "   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif	

			// Deleta em Meus Pedidos												
			//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABITENS->ID), cJson)

		else
			// enviar email falha de inclusao Vendedor x Cliente
			cHtml := "fSincCliCondPgto: Erro ao processar retorno da atualizacao da Cond.Pagto x Cliente: " +  AllTrim(CONDCLI->codigo) + " - " + AllTrim(CONDCLI->loja)
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
		endif

		CONDCLI->( DbSkip() )

	End


	if ! Empty(cNewDtMod)
		PutMV("A1_XULTCPG",u_fValidTime(cNewDtMod)) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincCliCondPgto: Finalizada sincronizacao das Cond.Pagto X Clientes. Ultima sincronizacao " + GetMV("A1_XULTCPG",,"") )
	CONDCLI->( DbCloseArea() )

Return
