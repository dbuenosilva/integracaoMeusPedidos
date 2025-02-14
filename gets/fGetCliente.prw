#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐�
北篜rograma  fGetCliente   篈utor 矰iego Bueno      � Data �   22/06/18   罕�
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡�
北篋esc.     � Obtem cliente do Protheus conforme ID Meus Pedidos.        罕�
北�          �                                                            罕�
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡�
北篣so       � Integracao Protheus x MeusPedidos.com.br                   罕�
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
*/

#DEFINE ID     1
#DEFINE CODIGO 2

User Function fGetCliente(cId,nOpc)
Local cQuery  := ""
Local cRetorno := ""

Default cId   := ""
Default nOpc  := ID 

if  nOpc  == ID 
	cQuery := "SELECT A1_COD+A1_LOJA AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SA1")+" SA1 " 
	cQuery += "WHERE A1_XIDMPED = '" + AllTrim(cId) +"' "
elseif nOpc  == CODIGO 
	cQuery := "SELECT A1_XIDMPED AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SA1")+" SA1 " 
	cQuery += "WHERE A1_COD+A1_LOJA = '" + AllTrim(cId) +"' "
endif
MemoWrite("C:\temp\getCliente.sql",cQuery)

if Select("CLIENTE") > 0
	CLIENTE->(DbCloseArea())
endif

TcQuery cQuery New Alias "CLIENTE"
if ! CLIENTE->(EOF())
	cRetorno := AllTrim(CLIENTE->CAMPO)
endif
CLIENTE->(DbCloseArea())
		
Return(cRetorno)