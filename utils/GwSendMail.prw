#include "totvs.ch"
#include "PROTHEUS.CH"

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � sendMail.prw � Autor � Diego Bueno       � Data � 20/04/15 ���
�������������������������������������������������������������������������Ĵ��
���Locacao   � Gwaya            �Contato � diego@gwaya.com                ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Programa gen�rico para envio de e-mail.                    ���
���          �                                      			          ���
�������������������������������������������������������������������������Ĵ��
���Parametros� NIL												          ���
�������������������������������������������������������������������������Ĵ��
���Retorno   � NIL                                                        ���
�������������������������������������������������������������������������Ĵ��
���Aplicacao � SIGACOM/SIGAGPE                                            ���
�������������������������������������������������������������������������Ĵ��
���Uso       � Jopy                                                       ���
�������������������������������������������������������������������������Ĵ��
���Analista Resp.�  Data  � Bops � Manutencao Efetuada                    ���
�������������������������������������������������������������������������Ĵ��
���              �  /  /  �      �                                        ���
���              �  /  /  �      �                                        ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/

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
	oMessage:cFrom    := AllTrim(GetMv("MV_RELFROM")) //Indica o endere�o de uma conta de e-mail (remetente) para representar o e-mail enviado. Exemplo: usuario@provedor.com.br.
	oMessage:cTo      := AllTrim(GetMv("MV_RELFROM"))//cCC//pra quem vai o email //Indica o endere�o de uma conta de e-mail que ser� utilizada para enviar o respectivo e-mail.
	oMessage:cCC      := cCC //AllTrim(GetMv("MV_RELFROM"))    //Indica o endere�o de e-mail, na se��o Com C�pia (CC), que receber� a mensagem.
	oMessage:cBCC     := cBcc    //Indica o endere�o de e-mail, na se��o C�pia Oculta, que receber� a mensagem.
	oMessage:cSubject := cAssunto   //Indica o assunto do e-mail. Caso n�o seja especificado, o assunto ser� enviado em branco.
	oMessage:cBody    := cBody    //Indica o conte�do da mensagem que ser� enviada.
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