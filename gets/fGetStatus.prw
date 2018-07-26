#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"




User Function fGetStatus(cStatus)
	local cRetorno := ""
	local cQuery := ""

	cQuery := "SELECT ZZ3_IDMP AS CAMPO "   
	cQuery += "FROM "+RetSQLName("ZZ3")+" ZZ3 " 
	cQuery += "WHERE ZZ3_STATUS = '" + AllTrim(cStatus) +"' "

	MemoWrite("C:\temp\getStatus.sql",cQuery)
	
	if Select("STATUS") > 0
		STATUS->(DbCloseArea())
	endif

	TcQuery cQuery New Alias "STATUS"
	if ! STATUS->(EOF())
		cRetorno := AllTrim(STATUS->CAMPO)
	endif
	STATUS->(DbCloseArea())
return cRetorno