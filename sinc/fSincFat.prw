#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

User Function fSincFat(lJob)
	local cQuery := ""
	local cEol	    := chr(13)+chr(10)
	local cNewDtMod := ""
	
	Private CMAILRESP := ""
	
	Default lJob        := .F.

	If ! lJob  .And. Select("SX2") == 0 // Via JOB
		lJob := .T.
	endif

	if lJob	
		RpcSetType(3)	
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SF2" //USER "Admin" PASSWORD "senha"	
	endif

	cQuery += "SELECT SC5.C5_XIDMPED,SF2.F2_FILIAL,SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA,SF2.F2_EMISSAO, SF2.F2_XIDMPFA, SF2.F2_XULTALT," + cEol
	cQuery += "CASE WHEN SF2.D_E_L_E_T_ = '*' THEN '.T.' WHEN SF2.D_E_L_E_T_ = '' THEN  '.F.' END AS DELETADO"  + cEol
	cQuery += "FROM SF2010 SF2" + cEol
	cQuery += "INNER JOIN SD2010 SD2 ON SD2.D2_FILIAL = SF2.F2_FILIAL AND SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_CLIENTE = SF2.F2_CLIENTE AND SD2.D2_LOJA = SF2.F2_LOJA" + cEol
	cQuery += "INNER JOIN SC5010 SC5 ON SC5.C5_FILIAL = SF2.F2_FILIAL AND SC5.C5_NUM = SD2.D2_PEDIDO" + cEol
	cQuery += "WHERE SC5.C5_XIDMPED <> '' AND SC5.C5_XULTALT <> '' AND SF2.F2_XULTALT = '' " + cEol
	cQuery += "GROUP BY SC5.C5_XIDMPED,SF2.F2_FILIAL,SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA,SF2.F2_EMISSAO, SF2.F2_XIDMPFA, SF2.F2_XULTALT,SF2.D_E_L_E_T_" + cEol

	MemoWrite("C:\temp\fSincFat.sql",cQuery)

	cQuery := ChangeQuery(cQuery)

	cMailResp  := AllTrim(GetMV("MV_GWMAILR",,""))

	if Select("SFAT") > 0
		SFAT->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "SFAT"

	DbSelectArea("SFAT")
	SFAT->(dbGoTop())

	While (SFAT->(!EoF()))
		cNewDtMod := fProcFat(SFAT->C5_XIDMPED,SFAT->F2_FILIAL,SFAT->F2_DOC,SFAT->F2_SERIE,SFAT->F2_CLIENTE,SFAT->F2_LOJA,SFAT->F2_EMISSAO,SFAT->F2_XIDMPFA,SFAT->F2_XULTALT,SFAT->DELETADO)
		SFAT->(DbSkip())
	enddo

	if ! Empty(cNewDtMod)
		PutMV("MV_XULTFAT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincFat: Finalizada sincronizacao dos Faturamentos. Ultima sincronizacao " + GetMV("MV_XULTFAT",,"") )
	SFAT->( DbCloseArea() )

return

static function fProcFat(cIdPedido,Filial,cDoc,cSerie,cCliente,cLoja,cEmissao,cIdFat,cDtAlt,cDelet)

	local aArea := getArea()

	local cURLBase :=  Alltrim( GetMV("MV_XMPFAT",,"") )
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cNewDtMod		:= ""
	Local cId           := ""

	//Variaveis inclusao
	local cData := ""
	local cVal := round(0,2)
	local ValFat := 0

	default cIdPedido := ""
	default Filial := ""	
	default	cDoc := ""
	default	cSerie := ""
	default	cCliente := ""
	default	cLoja := ""
	default cEmissao := ""
	default cIdFat := ""
	default cDtAlt := ""
	default cDelet := ""

	if Empty(cIdPedido) .or. Empty(Filial) .or. Empty(cDoc) .or. Empty(cSerie) .or. Empty(cCliente) .or. Empty(cLoja) .or. Empty(cEmissao) .or. Empty(cDelet)
		return .F.
	endif

	//Inlcusão de faturamento, F2_XIDMPFA vazio e D_E_L_E_T_ vazio
	if Empty(cIdFat) .and. cDelet == '.F.'

		DbSelectArea("SD2")
		SD2->( DbSetOrder(3) )//D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, R_E_C_N_O_, D_E_L_E_T_
		SD2->( dbGoTop() )
		
		if SD2->(DbSeek(Filial+cDoc+cSerie+cCliente+cLoja))
			while(SD2->(!EoF()) .and. SD2->(D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA) == (Filial+cDoc+cSerie+cCliente+cLoja) )
				ValFat += SD2->D2_TOTAL + SD2->D2_VALIPI
				SD2->(DbSkip())
			enddo
		endif

		//cEmissao := DtoS(cEmissao)
		cData := SubStr(cEmissao,1,4)+'-'+SubStr(cEmissao,5,2)+'-'+ SubStr(cEmissao,7,2)
		cVal := cValtoChar(round(ValFat,2))

		cJson := '{ '
		cJson += '"pedido_id": ' + alltrim(cIdPedido) + ','
		cJson += '"valor_faturado":  ' + cVal + ','
		cJson += '"data_faturamento":"' +cData+ '",'
		cJson += '"numero_nf": "' +alltrim(cSerie)+ ' ' + alltrim(cDoc)+'"' 
		cJson += '}'

		aHttpPost		:= u_PostJson(cURLBase,cJson)
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]

		If  cCodHttp $ "201/200"

			cQuery := "UPDATE "+RetSQLName("SC5")+" "  							
			cQuery += " SET C5_XULTALT = '"+cNewDtMod + "' "						
			cQuery += "  WHERE C5_XIDMPED = '" + AllTrim(cIdPedido) +"' "

			If tcsqlexec(cQuery) < 0
				cHtml := "fFatPed: Falha ao atualizar o campo C5_XULTALT no ERP pedido Id: " +  AllTrim(cIdPedido) +  "."   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif	

			cQuery := "UPDATE "+RetSQLName("SF2")+" "  											
			cQuery += "  SET F2_XIDMPFA = '" + AllTrim(U_GwTiraGraf(cId)) +"', F2_XULTALT = '"+alltrim(cNewDtMod) +"' "
			cQuery += "WHERE F2_FILIAL = '"+alltrim(Filial)+"' AND F2_DOC = '"+alltrim(cDoc)+"' AND F2_SERIE ='"+alltrim(cSerie)+"' AND F2_CLIENTE = '"+alltrim(cCliente)+"' AND F2_LOJA = '"+alltrim(cLoja)+"'" 		

			MemoWrite("C:\temp\fFatPed.sql",cQuery)

			If tcsqlexec(cQuery) < 0
				cHtml := "fSincFat: Falha ao atualizar o campo F2_XIDMPFAT no ERP pedido Id: " +  AllTrim(cIdPedido) +  ". Faturamento Id : "+alltrim(cId)   
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
			endif

		else
			// enviar email falha de alteração de pedido
			cHtml := "fSincFat: Erro ao processar retorno da alteração do faturamento do Pedido Id: " +   AllTrim(cIdPedido) +  " documento: " + alltrim(cSerie) + " " + alltrim(cDoc) 
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif


		u_GwLog("meuspedidos.log","fSincFat: Finalizada Faturamento do pedido Id :" + AllTrim(cIdPedido) +  " faturamento id: "+alltrim(cId))

	endif

	//Exclusão de faturamento, F2_XIDMPFA vazio e D_E_L_E_T_ *
	if !Empty(cIdFat) .and. cDelet == '.T.'

		cJson := '{'
		cJson += '"excluido":true'
		cJson += '}'

		aHttpPut		:= u_PutJson(cURLBase + "/" +  alltrim(cIdFat), cJson)
		cJson    		:= aHttpPut[1]
		cRetHead 		:= aHttpPut[2]
		cCodHttp 		:= aHttpPut[3]
		cId          	:= aHttpPut[4]
		cNewDtMod	    := aHttpPut[5]

		If cCodHttp $ "200/201"

			// Deve-se atualizar tambem registro deletados
			cQuery := "UPDATE "+RetSQLName("SF2")+" "
			cQuery += " SET F2_XULTALT  = '"+alltrim(cNewDtMod)+"' "
			cQuery += "WHERE F2_XIDMPFA = '"+alltrim(cIdFat)+"'"

			If tcsqlexec(cQuery) < 0

				cHtml := "fSincFat: Falha ao atualizar data ultima alteracao exclusao faturamento id: " +  AllTrim(cIdFat) 
				u_GwLog("meuspedidos.log", cHtml)
				u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)

			endif
		else
			// enviar email falha de inclusao cliente
			cHtml := "fSincFat: Falha ao atualizar exclusao do faturamento id: " +alltrim(cIdFat)+" na API"
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif

		u_GwLog("meuspedidos.log","fSincFat: Finalizada exclusão do faturamento do pedido Id :" + AllTrim(cIdPedido) +  " Faturamento Id :"+ alltrim(cIdFat))

	endif
	restArea(aArea)
return cNewDtMod