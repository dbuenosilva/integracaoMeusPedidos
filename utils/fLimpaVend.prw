#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

user function fLimpaVend(gwClienteId)
	local lRet := .T.
	local cURLBase := GetMV("MV_XMPCXU",,"/api/v1/usuarios_clientes/cliente")
	Local aHttpGet      := {}
	Local cJson         := ""
	Local cRetHead      := ""
	Local cCodHttp      := ""
	Local oUsuario := nil
	Local xCount := 1
	Local cMailResp     := AllTrim(GetMV("MV_GWMAILR",,""))
	
	if empty(cURLBase)
		return .F.
	endif

	aHttpGet := u_GetJson(cURLBase + "/"+alltrim(gwClienteId)+"/")

	cJson    := aHttpGet[1]
	cRetHead := aHttpGet[2]
	cCodHttp := aHttpGet[3]

	If "200" $ cCodHttp 
		if FWJsonDeserialize( cJson, @oUsuario )
			for	xCount := 1 to Len(oUsuario)
				if oUsuario[xCount]:LIBERADO
					lRet := U_PostUxC(oUsuario[xCount]:CLIENTE_ID, oUsuario[xCount]:USUARIO_ID, 'false')
				endif
			next xCount
			
			else
			cHtml := "fLimpaVend: Erro ao processar FWJsonDeserialize dos Usuário" ;
			+ " com Json: " + cJson   
			u_GwLog("meuspedidos.log", cHtml)
			u_GwSendMail(cMailResp,"","Inconsistência na integração MeusPedidos x Protheus",cHtml)
		endif
	endif
return lRet