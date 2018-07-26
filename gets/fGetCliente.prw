#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"
/*
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  fGetCliente   �Autor �Diego Bueno      � Data �   22/06/18   ���
�������������������������������������������������������������������������͹��
���Desc.     � Obtem cliente do Protheus conforme ID Meus Pedidos.        ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � Integracao Protheus x MeusPedidos.com.br                   ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

#DEFINE ID     1
#DEFINE CODIGO 2

User Function fGetCliente(cId,nOpc)
Local cQuery  := ""
Local cRetorno := ""

Default cId   := ""
Default nOpc  := ID 

if  nOpc  == ID 
	cQuery := "SELECT A1_COD+A1_LOJA AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SA1")+" SA1 " 
	cQuery += "WHERE A1_XIDMPED = '" + AllTrim(cId) +"' "
elseif nOpc  == CODIGO 
	cQuery := "SELECT A1_XIDMPED AS CAMPO "   
	cQuery += "FROM "+RetSQLName("SA1")+" SA1 " 
	cQuery += "WHERE A1_COD+A1_LOJA = '" + AllTrim(cId) +"' "
endif
MemoWrite("C:\temp\getCliente.sql",cQuery)

if Select("CLIENTE") > 0
	CLIENTE->(DbCloseArea())
endif

TcQuery cQuery New Alias "CLIENTE"
if ! CLIENTE->(EOF())
	cRetorno := AllTrim(CLIENTE->CAMPO)
endif
CLIENTE->(DbCloseArea())
		
Return(cRetorno)