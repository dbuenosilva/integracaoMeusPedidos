#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"


#DEFINE ID     1
#DEFINE CODIGO 2

User Function fGetProd(cId,nOpc)
Local cQuery  := ""
Local cRetorno := ""

Default cId   := ""
Default nOpc  := ID 

if  nOpc  == ID 
	cQuery := "SELECT SB1.B1_COD AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SB1")+" SB1 " 
	cQuery += "WHERE A1_XIDMPED = '" + AllTrim(cId) +"' "
elseif nOpc  == CODIGO 
	cQuery := "SELECT SB1.B1_XIDMPED AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SB1")+" SB1 " 
	cQuery += "WHERE SB1.B1_COD = '" + AllTrim(cId) +"' "
endif
MemoWrite("C:\temp\getCliente.sql",cQuery)

if Select("PROD") > 0
	PROD->(DbCloseArea())
endif

TcQuery cQuery New Alias "PROD"
if ! PROD->(EOF())
	cRetorno := AllTrim(PROD->CAMPO)
endif
PROD->(DbCloseArea())
		
Return(cRetorno)