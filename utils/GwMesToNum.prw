#INCLUDE "totvs.ch"
#INCLUDE "fileio.ch"
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � GwMesToNum  � Autor � Diego Bueno     � Data �  13/06/19   ���
�������������������������������������������������������������������������͹��
���Descricao � Converte Mes extenso para numerico                         ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � Jopy                                                       ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function GwMesToNum(cMes)
Local cRetorno := "  "
Default cMes := ""

Do Case
	Case cMes == "Jan"
		cRetorno := "01"
	Case cMes == "Feb"
		cRetorno := "02"
	Case cMes == "Mar"
		cRetorno := "03"
	Case cMes == "Apr"
		cRetorno := "04"
	Case cMes == "May"
		cRetorno := "05"
	Case cMes == "Jun"
		cRetorno := "06"
	Case cMes == "Jul"
		cRetorno := "07"
	Case cMes == "Aug"
		cRetorno := "08"
	Case cMes == "Sep"
		cRetorno := "09"
	Case cMes == "Oct"
		cRetorno := "10"
	Case cMes == "Nov"
		cRetorno := "11"
	Case cMes == "Dec"
		cRetorno := "12"
	Otherwise
		cRetorno := "  "
EndCase
Return(cRetorno)