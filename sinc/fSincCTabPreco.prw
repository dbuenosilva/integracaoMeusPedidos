#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐�
北篜rograma  fSincCTabPreco 篈utor 矰iego       Data �   15/06/18   罕�
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡�
北篋esc.     � Sincroniza Tabelas de Precos x Clientes com MeusPedidos    罕�
北�          �                                                            罕�
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡�
北篣so       � Integracao Protheus x MeusPedidos.com.br                   罕�
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
*/

User Function fSincCTabPreco(lJob)
	Local cURLBase      := ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cA1_XULTAB    := ""
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

	u_GwLog("meuspedidos.log","fSincCTabPreco: Iniciando sincronizacao das Tabelas de Precos x Clientes")

	cURLBase      := Alltrim( GetMV("MV_XMPTABC",,"") )
	cA1_XULTAB    := AllTrim(GetMV("A1_XULTABE",,"")) // Obtem a ultima data/hora de sincronizacao	
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))

	// Obtem lista de Item da Tabela de precos do Protheus para serem atualizados em Meus Pedidos  
	cQuery += "		SELECT A1_COD AS CODIGO," 
	cQuery += "		   A1_LOJA AS LOJA,"
	cQuery += "		   A1_XIDMPED AS cliente_id,"	
	cQuery += "		   DA0_XIDMPE AS tabelas_liberadas,"
	cQuery += "	       CASE WHEN SA1.D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido "
	cQuery += "	FROM " + RetSQLName("SA1") + " SA1 "
	cQuery += "	INNER JOIN " + RetSQLName("DA0") + " DA0 ON DA0_FILIAL = A1_FILIAL "
	cQuery += "		AND DA0_CODTAB = A1_TABELA "
	cQuery += "		AND SA1.D_E_L_E_T_ = DA0.D_E_L_E_T_ "
	cQuery += "	WHERE DA0.DA0_XIDMPE <> ' ' "
	cQuery += "		AND SA1.A1_XIDMPED <> ' ' "
	cQuery += "		AND (A1_XULTATB = ' ' OR A1_XULTATB > '" + cA1_XULTAB + "') "
	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\TABCLI.txt",cQuery)

	if Select("TABCLI") > 0
		TABCLI->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "TABCLI"

	dbSelectArea("TABCLI")
	TABCLI->(dbGoTop())

	While ! TABCLI->( EOF() )

		cJson := '{'
		cJson += '    "cliente_id": "' + AllTrim(TABCLI->cliente_id) + '",'
		cJson += '    "tabelas_liberadas": [ ' + AllTrim(TABCLI->tabelas_liberadas) + ' ]'
		cJson += '}'							

		MemoWrite("C:\temp\tabCli.json",cJson)

		// Inclui nova Item da Tabela em Meus Pedidos
		aHttpPost		:= u_PostJson(cUrlBase,cJson)
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]

		If "200" $ cCodHttp 	

			cQuery := "UPDATE "+RetSQLName("SA1")+" "
			cQuery += " SET A1_XULTATB = '"+cNewDtMod+"' "						
			cQuery += "  WHERE A1_COD = '" + TABCLI->codigo + "' AND A1_LOJA =  '" + TABCLI->loja + "' "   

			If tcsqlexec(cQuery) < 0
				cHtml := "fSincCTabPreco: Falha ao atualizar data no ERP da Tabela de Preco x Cliente: " +  AllTrim(TABCLI->codigo) + " - " + AllTrim(TABCLI->LOJA) + " "   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsist阯cia na integra玢o MeusPedidos x Protheus",cHtml)
			endif	

			// Deleta em Meus Pedidos												
			//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABITENS->ID), cJson)

		else
			// enviar email falha de inclusao Item da Tabela de preco
			cHtml := "fSincCTabPreco: Erro ao processar retorno da atualizacao da Tabela de Preco x Cliente: " +  AllTrim(TABCLI->codigo) + " - " + AllTrim(TABCLI->loja)   
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsist阯cia na integra玢o MeusPedidos x Protheus",cHtml)
		endif


		TABCLI->( DbSkip() )

	End


	if ! Empty(cNewDtMod)
		PutMV("A1_XULTABE",u_fValidTime(cNewDtMod)) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincCTabPreco: Finalizada sincronizacao das Tabelas de Preco X Clientes. Ultima sincronizacao " + GetMV("A1_XULTABE",,"") )
	TABCLI->( DbCloseArea() )

Return
