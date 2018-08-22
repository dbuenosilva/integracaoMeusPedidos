#INCLUDE "TOTVS.CH"


/*__________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Funçào    ¦ fValidTime  ¦ Autor ¦ Joao Elso      ¦ Data ¦ 2018/08/15	  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçào ¦ Fonte para validar e corrigir data hora 	                  ¦¦¦
¦¦¦formato AAAA/MM/DD HH:MM:SS			 								  ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦ Uso      ¦ Empadao                                                    ¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
*/


user function fValidTime(cTime)
	local aTime := {}
	local Hora := ""
	local cReturn := ""
	default cTime := ""

	if len(alltrim(cTime))< 18
		return ""
	endif

	aTime := StrTokArr(cTime," ")
	Hora := substr(aTime[2],1,2)
	Minuto := substr(aTime[2],4,2)
	Segundo := substr(aTime[2],7,2)

	if Val(Hora) < 0
		Hora := "00"
	elseif Val(Hora) > 24
		Hora := "24"
	endif

	if Val(Minuto) < 0
		Minuto := "00"
	elseif Val(Minuto) > 60
		Minuto := "59"
	endif

	if Val(Segundo) < 0
		Segundo := "00"
	elseif Val(Segundo) > 60
		Segundo := "59"
	endif

	cReturn := aTime[1] + " " + Hora+":"+Minuto+":"+Segundo


return cReturn