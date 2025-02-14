#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐�
北篜rograma  fSincTitulos       篈utor 矰iego Bueno      � Data �   15/06/18   罕�
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡�
北篋esc.     � Sincroniza Pedidos de Vendas com MeusPedidos               罕�
北�          �                                                            罕�
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡�
北篣so       � Integracao Protheus x MeusPedidos.com.br                   罕�
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
*/
User Function fSincTitulos(lJob)
	Local cURLBase      := ""
	Local cQuery 	 	:= ""
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cE1_XULTAL    := ""
	Local cNewDtMod		:= ""
	Local oTitulos       := nil
	Local aHttpGet      := {}
	Local aHttpPost     := {}
	Local aHttpPut      := {}		
	Local cId           := ''
	Local lRet := .T.
	Private cEol	    := chr(13)+chr(10)
	Private cMailResp   := ""
	Private cSGBD       := ""

	Default lJob        := .F.

	If ! lJob  .And. Select("SX2") == 0 // Via JOB
		lJob := .T.
	endif

	if lJob	
		RpcSetType(3)	
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" TABLES "SE1" //USER "Admin" PASSWORD "senha"	
	endif

	u_GwLog("meuspedidos.log","fSincTitulos: Iniciando sincronizacao dos titulos vencidos..")
	cURLBase      := Alltrim( GetMV("MV_XMPPEDI",,"") )	
	cE1_XULTAL    := AllTrim(GetMV("E1_XULTALT",,"")) // Obtem a ultima data/hora de sincronizacao
	cMailResp         := AllTrim(GetMV("MV_GWMAILR",,""))
	//MsgInfo(" alterado_apos=" + StrTran(AllTrim(GetMV("C5_XULTALT",,""))," ","%20"))

	if ! Empty(cNewDtMod)
		PutMV("E1_XULTALT",u_fValidTime(cNewDtMod)) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincTitulos: Finalizada sincronizacao dos Titulos Vencidos. Ultima sincronizacao " + GetMV("E1_XULTALT",,"") )

	FreeObj(oTitulos)
Return
