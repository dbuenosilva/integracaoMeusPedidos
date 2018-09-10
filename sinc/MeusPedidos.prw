#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ MeusPedidos ³ Autor ³ Diego Bueno        ³ Data ³ 25/04/18 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Locacao   ³ GWAYA            ³Contato ³ diego@gwaya.com                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Integracao Protheus x MeusPedidos.com.br                   ³±±
±±³          ³                                      			          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³                      				                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ NIL                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Aplicacao ³ SIGAFAT                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Menu      ³ Miscelanea / Especificos / Integracao MeusPedidos          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Integracao Protheus x MeusPedidos.com.br                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Analista Resp.³  Data  ³ Bops ³ Manutencao Efetuada                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³              ³  /  /  ³      ³                                        ³±±
±±³              ³  /  /  ³      ³                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/

User Function JobMeusPedidos()
	local lPedAuto := GetMv("MV_XPEDAUT",,.F.)
	
	u_fSincGrpProdutos(.T.)
	u_fSincProdutos(.T.)
	u_fSincSegmentos(.T.)
	u_fSincClientes(.T.)
	u_fSincTabelasDePrecos(.T.)
	u_fSincCondicoesPgto(.T.)
	u_fSincFormasPgto(.T.)

	u_fSincCTabPreco(.T.) 
	u_fSincCCondPgto(.T.)
	u_fSincCVendedores(.T.) 
	if lPedAuto
		u_fSincPedidos(.T.)
	endif
	U_fSincFat(.T.)
	// u_fSincTitulos()

Return

User Function MeusPedidos

	Local aCores    := {{ "ZZ1_STATUS",'ENABLE'}, {"ZZ1_STATUS",'DISABLE'} }

	Private cCadastro := "Integracao MeusPedidos"

	Private aRotina   := { {"Pesquisar","AxPesqui",0,1} ,;
	{"Visualizar","AxVisual",0,2} ,;
	{"Categoria de Produtos","Processa( {|| u_fSincGrpProdutos() }, 'Aguarde', 'Sincronizando Categoria de Produtos...',.F.)",0,3} ,;
	{"Produtos","Processa( {|| u_fSincProdutos() }, 'Aguarde', 'Sincronizando Cadastro de Produtos...',.F.)",0,3} ,;
	{"Segmento de Clientes","Processa( {|| u_fSincSegmentos() }, 'Aguarde', 'Sincronizando Segmento de Clientes',.F.)",0,3} ,;	
	{"Clientes","Processa( {|| u_fSincClientes() }, 'Aguarde', 'Sincronizando Cadastro de Clientes..',.F.)",0,3} ,;               
	{"Tabelas de Precos","Processa( {|| u_fSincTabelasDePrecos() }, 'Aguarde', 'Sincronizando Tabelas de Precos..'  ,.F.)",0,3},;   			
	{"Tabelas de Precos X Clientes","Processa( {|| u_fSincCTabPreco() }, 'Aguarde', 'Sincronizando Tabelas de Precos x Clientes'  ,.F.)",0,3},;	
	{"Cond.Pagto X Clientes","Processa( {|| u_fSincCCondPgto() }, 'Aguarde', 'Sincronizando Cond.Pagto X Clientes'  ,.F.)",0,3},;		
	{"Vendedores X Clientes","Processa( {|| u_fSincCVendedores() }, 'Aguarde', 'Sincronizando Vendedores x Clientes'  ,.F.)",0,3},;		
	{"Condicoes de Pagamento","Processa( {|| u_fSincCondicoesPgto() }, 'Aguarde', 'Sincronizando Condicoes de Pagamentos',.F.)",0,3} ,;	
	{"Formas de Pagamento","Processa( {|| u_fSincFormasPgto() }, 'Aguarde', 'Sincronizando Formas de Pagamentos',.F.)",0,3} ,;	
	{"Pedidos de Vendas","Processa( {|| u_fSincPedidos() }, 'Aguarde', 'Sincronizando Pedidos de Vendas',.F.)",0,3} ,;
	{"Titulos","Processa( {|| u_fSincTitulos() }, 'Aguarde', 'Sincronizando Titulos a Receber..',.F.)",0,3},;
	{"Faturamento ","Processa( {|| U_fSincFat() }, 'Aguarde', 'Sincronizando Faturamento..',.F.)",0,3}    }                                                           

	Private cDelFunc := ".F." // Validacao para a exclusao. Pode-se utilizar ExecBlock
	Private cString := "ZZ1"
	dbSelectArea(cString)
	dbSetOrder(1)
	mBrowse( 6,1,22,75,cString,,,,,,aCores )

	Return NIL


	/*
	fGravaMeusPedidos

	Grava erros de comunicacao na tabela ZZ1

	estrutura de aDados:
	*/
	#DEFINE ROTINA  1
	#DEFINE HTTPCOD 2
	#DEFINE RETORNO 3
	#DEFINE HEADER  4
	#DEFINE IDMPED  5
	#DEFINE DTMPED  6
	#DEFINE MENSAG  7
	#DEFINE STATUS  8

User Function fGravaMeusPedidos(aDados)
	Local aArea := GetArea()
	Local lRet  := .F.
	Default aDados := {}

	IF Len(aDados) == 8 .And. RecLock("ZZ1",.T.)
		ZZ1_FILIAL := xFilial("ZZ1")
		ZZ1_DATA   := Date()
		ZZ1_HORA   := time()
		ZZ1_USUARI := cUserName
		ZZ1_ROTINA := aDados[ROTINA]
		ZZ1_STATUS := aDados[STATUS]
		ZZ1_HTTPCO := aDados[HTTPCOD]
		ZZ1_RETHTT := aDados[RETORNO]
		ZZ1_HEADHT := aDados[HEADER]
		ZZ1_IDMEUS := aDados[IDMPED]
		ZZ1_DTMEUS := aDados[DTMPED]
		ZZ1_MENSAG := aDados[MENSAG]
		ZZ1->(MsUnlock())
		lRet := .T.
	endif
	RestArea(aArea)
Return(lRet)