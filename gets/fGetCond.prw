#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"


#DEFINE ID     1
#DEFINE CODIGO 2

User Function fGetCond(cId,nOpc)
Local cQuery  := ""
Local cRetorno := ""

Default cId   := ""
Default nOpc  := ID 

if  nOpc  == ID 
	cQuery := "SELECT E4_CODIGO AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SE4")+" SE4 " 
	cQuery += "WHERE E4_XIDMPED = '" + AllTrim(cId) +"' "
elseif nOpc  == CODIGO 
	cQuery := "SELECT E4_XIDMPED AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SE4")+" SE4 " 
	cQuery += "WHERE E4_CODIGO = '" + AllTrim(cId) +"' "
endif
MemoWrite("C:\temp\getCond.sql",cQuery)

if Select("COND") > 0
	COND->(DbCloseArea())
endif

TcQuery cQuery New Alias "COND"
if ! COND->(EOF())
	cRetorno := AllTrim(COND->CAMPO)
endif
COND->(DbCloseArea())
		
Return(cRetorno)