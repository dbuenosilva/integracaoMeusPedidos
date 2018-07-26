#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"




User Function fGetCmpEx(cNome)
	local cRetorno := ""
	local cQuery := ""

	cQuery := "SELECT ZZ2_ID AS CAMPO "   
	cQuery += "FROM "+RetSQLName("ZZ2")+" ZZ2 " 
	cQuery += "WHERE ZZ2_NOME = '" + AllTrim(cNome) +"' "

	MemoWrite("C:\temp\getCmpEx.sql",cQuery)
	
	if Select("CMPEX") > 0
		STATUS->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "CMPEX"
	if ! CMPEX->(EOF())
		cRetorno := AllTrim(CMPEX->CAMPO)
	endif
	CMPEX->(DbCloseArea())
return cRetorno