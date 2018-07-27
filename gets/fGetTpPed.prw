#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

#DEFINE ID     1
#DEFINE CODIGO 2

user function fGetTpPed(cId,nOpc)
	Local cRetorno := ""
	Local cQuery := ""

	if  nOpc  == ID 
		cQuery := "SELECT ZZ4.ZZ4_TIPO AS CAMPO "   
		cQuery += "FROM "+RetSQLName("ZZ4")+" ZZ4 " 
		cQuery += "WHERE ZZ4.ZZ4_ID = '" + AllTrim(cId) +"' "
	elseif nOpc  == CODIGO 
		cQuery := "SELECT ZZ4.ZZ4_ID AS CAMPO "   
		cQuery += "FROM "+RetSQLName("ZZ4")+" ZZ4 " 
		cQuery += "WHERE ZZ4.ZZ4_TIPO = '" + AllTrim(cId) +"' "
	endif

	if Select("TPPED") > 0
		TPPED->(DbCloseArea())
	endif


	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "TPPED"

	if ! TPPED->(EOF())
		cRetorno := AllTrim(TPPED->CAMPO)
	endif

	TPPED->(DbCloseArea())
return cRetorno
