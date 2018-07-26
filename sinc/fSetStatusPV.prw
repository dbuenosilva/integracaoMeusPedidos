#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

/*__________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Funçào    ¦ fSetStatusPV  ¦ Autor ¦ Joao Elso      ¦ Data ¦ 2018/07/01 ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Fonte para atualizar o status do pedido Meus Pedidos		  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ Empadao                                                    ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
*/

User Function fSetStatusPV(cIdPedido,nStatus)
	Local cURLBase      := Alltrim( GetMV("MV_XMPPED",,"") )
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cNewDtMod		:= ""
	Local lRet := .T.
	Local aHttpPost     := {}
	Local cId           := ''
	local cAnotacao := ""

	Private cMailResp   := ""

	Default cIdPedido   := ""
	Default nStatus := ""

	u_GwLog("meuspedidos.log","fSetStatusPV: Iniciando sincronizacao dos status do pedidos ...")
	cMailResp         := AllTrim(GetMV("MV_GWMAILR",,""))

	if Empty(nStatus)
		u_GwLog("meuspedidos.log","fSetStatusPV: Erro status incorreto.")
		return .F.
	else
		cJson := '{ '
		cJson += '"status_id":' + nStatus + ','
		cJson += '"anotacao": "' + cAnotacao +'"'
		cJson += '}'
	endif

	// Atualiza o Status do pedido nos Meus Pedidos
	aHttpPost		:= u_PostJson(cURLBase + '/' + cIdPedido +'/status' ,cJson)
	cJson    		:= aHttpPost[1]
	cRetHead 		:= aHttpPost[2]
	cCodHttp 		:= aHttpPost[3]
	cId          	:= aHttpPost[4]
	cNewDtMod	    := aHttpPost[5]

	If  cCodHttp $ "201/200"

	else
		// enviar email falha de alteração de pedido
		cHtml := "fSetStatusPV: Erro ao processar retorno da alteração do status do Pedido Id: " +   AllTrim(cIdPedido) +  "." 
		u_GwLog("meuspedidos.log", cHtml)
		u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
	endif

	u_GwLog("meuspedidos.log","fSetStatusPV: Finalizada Atualizão de Status do pedido Id :" + AllTrim(cIdPedido) +  ".")
Return lRet

