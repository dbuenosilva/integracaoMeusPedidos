#INCLUDE "totvs.ch"
#INCLUDE "fileio.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ GwSubDTime  บ Autor ณ Diego Bueno     บ Data ณ  05/07/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Formata datetime e subtrai horas, caso necessario.         บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Jopy                                                       บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function GwSubDTime(cDateRet,cSub)
Local cAno 
Local cMes 
Local cDia 
Local cHrGMTMenos3 

Default cDateRet := ''
Default cSub     := '0.0'
                                                                                                                                                                                                                                       
//cDateRet := "Wed, 01 Jan 2018 00:59:14 GMT\r"
//MsgInfo(cDateRet)						

cAno := Val(SubStr(cDateRet,13,4))
cMes := Val(u_GwMesToNum(SubStr(cDateRet,9,3)))
cDia := Val(SubStr(cDateRet,6,2))
cHrGMTMenos3 :=  SubHoras( SubStr(cDateRet,18,2) , cSub )

if cHrGMTMenos3 < 0
	cHrGMTMenos3 := cHrGMTMenos3 + 24
	cDia 		 := cDia - 1
	if cDia <= 0
		cMes := cMes - 1					
		if cMes <= 0
			cMes := cMes + 12
			cAno := cAno - 1 			
		endif
		cDia := Val(SubStr(DtoS(Lastday( StoD(StrZero(cAno,4) + StrZero(cMes,2) + "01"),0)),7,2))
	endif		
endif

cAno := StrZero(cAno,4)
cMes := StrZero(cMes,2)
cDia := StrZero(cDia,2)

cDateRet := cAno + "-" + cMes + "-" + cDia + " " ;
+ PadL(StrTran(cValtoChar( cHrGMTMenos3 ),'.',':'),2,'0') + SubStr(cDateRet,20,6) // converte hora GMT retornada para GMT-3
//2018-12-31 21:59:14
Return(cDateRet)
