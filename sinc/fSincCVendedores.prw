#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincCVendedores       บAutor ณDiego Bueno      บ Data ณ   18/06/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Vendedores x Clientes com MeusPedidos           บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function fSincCVendedores(lJob)
	Local cURLBase      := ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cA1_XULTAV    := ""
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

	u_GwLog("meuspedidos.log","fSincCVendedores: Iniciando sincronizacao das Tabelas de Precos x Clientes")
	cURLBase      := Alltrim( GetMV("MV_XMPA1A3",,"") )
	cA1_XULTAV    := AllTrim(GetMV("A1_XULTATV",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))


	

	// Obtem lista de Item da Tabela de precos do Protheus para serem atualizados em Meus Pedidos  
	cQuery += " SELECT  A3_COD AS VENDEDOR, " 
	cQuery += "	A1_COD AS codigo, " 
	cQuery += "	A1_LOJA AS LOJA, "	
	cQuery += "	A3_XIDMPED AS usuario_id, "
	cQuery += "	A1_XIDMPED AS cliente_id, "
	cQuery += "	'true' as liberado "
	cQuery += " FROM " + RetSQLName("SA3") + " SA3 "
	cQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 ON A1_FILIAL = A3_FILIAL "
	cQuery += "	AND A1_VEND = A3_COD "
	cQuery += "	AND SA1.D_E_L_E_T_ = SA3.D_E_L_E_T_ "
	cQuery += " WHERE A1_XIDMPED <> ' ' AND A3_XIDMPED <> ' ' "
	cQuery += "		AND (A1_XULTATV = ' ' OR A1_XULTATV > '" + cA1_XULTAV + "') "
	//cQuery := ChangeQuery(cQuery)
	MemoWrite("C:\temp\TABVEND.txt",cQuery)

	if Select("TABVEND") > 0
		TABVEND->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "TABVEND"

	dbSelectArea("TABVEND")
	TABVEND->(dbGoTop())

	While ! TABVEND->( EOF() )
		
		lRet := u_fLimpaVend(AllTrim(TABVEND->cliente_id))
		
		cJson := '{'
		cJson += '	"cliente_id": ' + AllTrim(TABVEND->cliente_id) + ',' 
		cJson += '	"usuario_id": ' + AllTrim(TABVEND->usuario_id) + ','
		cJson += '	"liberado": true'
		cJson += '}'							

		MemoWrite("C:\temp\tabVEND.json",cJson)

		// Inclui nova Item da Tabela em Meus Pedidos
		aHttpPost		:= u_PostJson(cUrlBase ,cJson)
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]

		If "200" $ cCodHttp 	

			cQuery := "UPDATE "+RetSQLName("SA1")+" "
			cQuery += " SET A1_XULTATV = '"+cNewDtMod+"' "						
			cQuery += "  WHERE A1_COD = '" + TABVEND->codigo + "' AND A1_LOJA =  '" + TABVEND->loja + "' "   

			If tcsqlexec(cQuery) < 0
				cHtml := "fSincCVendedoresA: Falha ao atualizar data no ERP do Vendedor x Cliente: " +  AllTrim(TABVEND->codigo) + " - " + AllTrim(TABVEND->LOJA) + " "   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
			endif	

			// Deleta em Meus Pedidos												
			//aHttpPut		:= u_PutJson(cUrlBase + "/" +  u_GwTiraGraf(TABITENS->ID), cJson)

		else
			// enviar email falha de inclusao Vendedor x Cliente
			cHtml := "fSincCVendedoresA: Erro ao processar retorno da atualizacao do Vendedor x Cliente: " +  AllTrim(TABVEND->codigo) + " - " + AllTrim(TABVEND->loja)
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsist๊ncia na integra็ใo MeusPedidos x Protheus",cHtml)
		endif
		
		TABVEND->( DbSkip() )

	End


	if ! Empty(cNewDtMod)
		PutMV("A1_XULTATV",u_fValidTime(cNewDtMod)) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincCVendedores: Finalizada sincronizacao dos Vendedores x Clientes. Ultima sincronizacao " + GetMV("A1_XULTATV",,"") )
	TABVEND->( DbCloseArea() )
	
Return
