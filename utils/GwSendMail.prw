#include "totvs.ch"
#include "PROTHEUS.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ sendMail.prw ³ Autor ³ Diego Bueno       ³ Data ³ 20/04/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Locacao   ³ Gwaya            ³Contato ³ diego@gwaya.com                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Programa genérico para envio de e-mail.                    ³±±
±±³          ³                                      			          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ NIL												          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ NIL                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Aplicacao ³ SIGACOM/SIGAGPE                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Jopy                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Analista Resp.³  Data  ³ Bops ³ Manutencao Efetuada                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³              ³  /  /  ³      ³                                        ³±±
±±³              ³  /  /  ³      ³                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function GwSendMail(cCC,cBcc,cAssunto,cBody,cFile)
local oServer  := Nil
local oMessage := Nil
local nErr     := 0
local cPopAddr  := AllTrim(GetMv('MV_WFPOP3'))    // Endereco do servidor POP3
local cSMTPAddr := AllTrim(GetMv('MV_RELSERV'))  //AllTrim(GetMv('MV_RELSERV'))   // Endereco do servidor SMTP
local cPOPPort  := GetMv("MV_PORPOP3")            // Porta do servidor POP
local cSMTPPort := GetMv("MV_PORSMTP")            // Porta do servidor SMTP
local cUser     := AllTrim(GetMv('MV_RELACNT'))   //  AllTrim(GetMv('MV_RELACNT'))   // Usuario que ira realizar a autenticacao
local cPass     := AllTrim(GetMV("MV_EMSENHA"))   //AllTrim(GetMV('MV_RELAPSW'))   // Senha do usuario
local nSMTPTime := GetMV("MV_RELTIME")            // Timeout SMTP             
local lSSL      := GetMV("MV_RELSSL")             // SSL
Local lTLS		:= GetMV("MV_RELTLS")			  // TLS
Local lAuth     := GetMV("MV_RELAUTH")			 //  Auth?
Local lEnable     := GetMV("MV_GWSENDM",,.T.)			 //  Auth?

Default cFile   := ''

IF lEnable

	nPos := At(":",cSMTPAddr)
	if nPos > 0
		cSMTPAddr := SubStr(cSMTPAddr,1,nPos - 1)
	endif
	
	nPos := At(":",cPopAddr)
	if nPos > 0
		cPopAddr := SubStr(cPopAddr,1,nPos - 1)
	endif
	
	// Instancia um novo TMailManager
	oServer := tMailManager():New()    
	//oServer:set(lAuth)// Usa Auth?
	oServer:setUseSSL(lSSL)// SSL?
	oServer:SetUseTLS(lTLS)// TLS?
	oServer:init(cPopAddr, cSMTPAddr, cUser, cPass, cPOPPort, cSMTPPort)
	
	// Define o Timeout SMTP
	if oServer:SetSMTPTimeout(nSMTPTime) != 0  
		MsgInfo("[ERROR]Falha ao definir timeout","SendMail")  
		return .F.
	endif 
	
	// Conecta ao servidor
	nErr := oServer:smtpConnect()
	if nErr <> 0  
		MsgInfo("[ERROR]Falha ao conectar: " + oServer:getErrorString(nErr),"SendMail")   
		oServer:smtpDisconnect()  
		return .F.
	endif  
	
	// Realiza autenticacao no servidor
	nErr := oServer:smtpAuth(cUser, cPass)
	if nErr <> 0  
		MsgInfo("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr),"SendMail")   
		oServer:smtpDisconnect()  
		return .F.
	
	endif
	
	// Cria uma nova mensagem (TMailMessage)
	oMessage 		  := tMailMessage():new()
	oMessage:clear()
	oMessage:cFrom    := AllTrim(GetMv("MV_RELFROM")) //Indica o endereço de uma conta de e-mail (remetente) para representar o e-mail enviado. Exemplo: usuario@provedor.com.br.
	oMessage:cTo      := AllTrim(GetMv("MV_RELFROM"))//cCC//pra quem vai o email //Indica o endereço de uma conta de e-mail que será utilizada para enviar o respectivo e-mail.
	oMessage:cCC      := cCC //AllTrim(GetMv("MV_RELFROM"))    //Indica o endereço de e-mail, na seção Com Cópia (CC), que receberá a mensagem.
	oMessage:cBCC     := cBcc    //Indica o endereço de e-mail, na seção Cópia Oculta, que receberá a mensagem.
	oMessage:cSubject := cAssunto   //Indica o assunto do e-mail. Caso não seja especificado, o assunto será enviado em branco.
	oMessage:cBody    := cBody    //Indica o conteúdo da mensagem que será enviada.
	if !Empty(cFile) .And. oMessage:AttachFile( cFile ) < 0
		MsgInfo("[ERROR] Falha ao anexar arquivo " + cFile + ":" + oServer:getErrorString(nErr),"SendMail")  
	    return(.F.)
	endif
	
	// Envia a mensagem
	nErr := oMessage:send(oServer)
	
	if nErr <> 0  
		MsgInfo("[ERROR]Falha ao enviar: " + oServer:getErrorString(nErr),"SendMail")  
		oServer:smtpDisconnect()  
		return(.F.)
		
	endif
	
	// Disconecta do Servidor
	oServer:smtpDisconnect()
	
Endif

return(.T.)