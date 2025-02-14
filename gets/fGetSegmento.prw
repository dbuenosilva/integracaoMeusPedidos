#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
北赏屯屯屯屯脱屯屯屯屯屯送屯屯屯淹屯屯屯屯屯屯屯屯屯退屯屯屯淹屯屯屯屯屯屯槐�
北篜rograma  fGetSegmento  篈utor 矰iego Bueno      � Data �   22/06/18   罕�
北掏屯屯屯屯拓屯屯屯屯屯释屯屯屯贤屯屯屯屯屯屯屯屯屯褪屯屯屯贤屯屯屯屯屯屯贡�
北篋esc.     � Obtem segmento do Protheus conforme ID Meus Pedidos.       罕�
北�          �                                                            罕�
北掏屯屯屯屯拓屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯贡�
北篣so       � Integracao Protheus x MeusPedidos.com.br                   罕�
北韧屯屯屯屯拖屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯急�
北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌哌�
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