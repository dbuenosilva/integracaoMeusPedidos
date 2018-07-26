#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.ch"

user function fGetTpPed(Filial,cNum)
	Local cQry := ""

	cQry := "SELECT TOP 1 SC6.C6_XOPER "
	cQry += "FROM " +RetSqlName("SC6")+ " SC6 "
	cQry += "WHERE SC6.D_E_L_E_T_ <> '*' AND SC6.C6_FILIAL = '"+Filial+"' AND SC6.C6_NUM = '"+cNum+"' "

	MemoWrite("C:\temp\fGetTpPed.sql",cQry)

	if Select("TPPED") > 0
		TPPED->(DbCloseArea())
	endif

	TcQuery cQry New Alias "TPPED"
	//(C6_OPER = 14 OU 15 É VENDA, 7 OU R OU W OU 16 É BONIFICAÇÃO, 27 AMOSTRA, 6  TROCA) OUTRO DA ERRO
	if(TPPED->(!Eof()))
		if(alltrim(TPPED->C6_XOPER) == '14') .OR. (alltrim(TPPED->C6_XOPER)== '15')
			cTpPed := "null"
		elseif (alltrim(TPPED->C6_XOPER) == '16') .OR. ( alltrim(TPPED->C6_XOPER) == '7') .OR. ( alltrim(TPPED->C6_XOPER) == 'R') .OR. ( alltrim(TPPED->C6_XOPER) == 'W') //Bonificação
			cTpPed := "107"
		elseif(alltrim(TPPED->C6_XOPER) == '27')//Amostra
			cTpPed := "106"
		elseif(alltrim(TPPED->C6_XOPER) == '6')//Troca
			cTpPed := "108" 
		else 
			//erro
			cTpPed := "null"
		endif
	endif

	TPPED->(DbCloseArea())
return cTpPed
