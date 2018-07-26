#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

#DEFINE ID     1
#DEFINE CODIGO 2

user Function fGetVend(cId,nOpc)
	Local cQuery  := ""
	Local cRetorno := ""
	Local cUrlBase := alltrim(getMv("MV_XUSR",,))
	
	if  nOpc  == ID 
		cQuery := "SELECT SA3.A3_COD AS CAMPO "   
		cQuery += "FROM "+RetSQLName("SA3")+" SA3 " 
		cQuery += "WHERE SA3.A3_XIDMPED = '" + AllTrim(cId) +"' "
	elseif nOpc  == CODIGO 
		cQuery := "SELECT SA3.A3_XIDMPED AS CAMPO "   
		cQuery += "FROM "+RetSQLName("SA3")+" SA3 " 
		cQuery += "WHERE SA3.A3_COD = '" + AllTrim(cId) +"' "
	endif

	MemoWrite("C:\temp\getVend.sql",cQuery)

	if Select("VEND") > 0
		VEND->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "VEND"
	

	if ! VEND->(EOF())
		cRetorno := AllTrim(VEND->CAMPO)
	endif


	VEND->(DbCloseArea())

Return(cRetorno)
