#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"


#DEFINE ID     1
#DEFINE CODIGO 2

User Function fGetTPrc(cId,nOpc)
Local cQuery  := ""
Local cRetorno := ""

Default cId   := ""
Default nOpc  := ID 

if  nOpc  == ID 
	cQuery := "SELECT DA0_CODTAB AS CAMPO "   
	cQuery += "FROM "+RetSQLName("DA0")+" DA0 " 
	cQuery += "WHERE DA0_XIDMPE = '" + AllTrim(cId) +"' "
elseif nOpc  == CODIGO 
	cQuery := "SELECT DA0_XIDMPE AS CAMPO "   
	cQuery += "FROM "+RetSQLName("DA0")+" DA0 " 
	cQuery += "WHERE DA0_CODTAB = '" + AllTrim(cId) +"' "
endif
MemoWrite("C:\temp\getTbPrc.sql",cQuery)

if Select("TBPRC") > 0
	TBPRC->(DbCloseArea())
endif

TcQuery cQuery New Alias "TBPRC"
if ! TBPRC->(EOF())
	cRetorno := AllTrim(TBPRC->CAMPO)
endif
TBPRC->(DbCloseArea())
		
Return(cRetorno)