#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"



User function PostUxC(gwClienteId, gwUsuarioId, gwLiberado)
local lRet := .F.
Local cURLBase      := Alltrim( GetMV("MV_XMPA1A3",,"") )
Local aHttpPost     := {}	
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local cId := ""
	Local cNewDtMod := ""
	
cJson += '{'
cJson += '"cliente_id":' + alltrim(cValtoChar(gwClienteId))+","
cJson += '"usuario_id":' + alltrim(cValtoChar(gwUsuarioId))+","
cJson += '"liberado":' + alltrim(gwLiberado)
cJson += '}'

aHttpPost		:= u_PostJson(cURLBase,cJson)
		cJson    		:= aHttpPost[1]
		cRetHead 		:= aHttpPost[2]
		cCodHttp 		:= aHttpPost[3]
		cId          	:= aHttpPost[4]
		cNewDtMod	    := aHttpPost[5]
		
		If "200" $ cCodHttp 	
			lRet := .T.
		endif
		
		
return lRet