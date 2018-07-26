#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

/*
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  fSincTitulos       บAutor ณDiego Bueno      บ Data ณ   15/06/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Sincroniza Pedidos de Vendas com MeusPedidos               บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Integracao Protheus x MeusPedidos.com.br                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
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
		PutMV("E1_XULTALT",cNewDtMod) // Atuaiza a ultima data/hora de sincronizacao
	endif

	u_GwLog("meuspedidos.log","fSincTitulos: Finalizada sincronizacao dos Titulos Vencidos. Ultima sincronizacao " + GetMV("E1_XULTALT",,"") )

	FreeObj(oTitulos)
Return
