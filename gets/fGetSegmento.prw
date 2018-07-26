#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  fGetSegmento  ºAutor ³Diego Bueno      º Data ³   22/06/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Obtem segmento do Protheus conforme ID Meus Pedidos.       º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Protheus x MeusPedidos.com.br                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

#DEFINE ID     1
#DEFINE CODIGO 2

User Function fGetSegmento(cId,nOpc)
Local cQuery  := ""
Local cCodigo := ""

Default cId   := ""
Default nOpc  := ID 

cQuery := "SELECT X5_CHAVE, X5_DESCRI as nome, X5_DESCENG as ultima_alteracao, X5_DESCSPA as id, 	 
cQuery += "CASE WHEN D_E_L_E_T_ = '*' THEN 'true' else 'false' END AS excluido  
cQuery += "FROM "+RetSQLName("SX5")+" SX5 " 
cQuery += "WHERE  X5_TABELA = 'T3' AND X5_DESCSPA = '" + AllTrim(cId) +"' "

MemoWrite("C:\temp\getSegmento.sql",cQuery)

if Select("SEGMENTO") > 0
	SEGMENTO->(DbCloseArea())
endif

TcQuery cQuery New Alias "SEGMENTO"
if ! SEGMENTO->(EOF())
	cCodigo := AllTrim(SEGMENTO->X5_CHAVE)
endif
SEGMENTO->(DbCloseArea())
		
Return(cCodigo)