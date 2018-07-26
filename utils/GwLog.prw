#INCLUDE "totvs.ch"
#INCLUDE "fileio.ch"
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ GwLog  บ Autor ณ Diego Bueno          บ Data ณ  06/09/17   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Grava Logs em /system/gwaya.log                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Jopy                                                       บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

User Function GwLog(cArqTxt,cGrava)

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Cria o arquivo texto                                                ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Private nHdl    := -1 //fCreate(cArqTxt)
Private nError  := 0
Private cEOL    := "CHR(13)+CHR(10)"
Private cLin    
Private cDirLog := AllTrim(GetMV("MV_GWDIRLG",,""))

If Empty(cEOL)
    cEOL := CHR(13)+CHR(10)
Else
    cEOL := Trim(cEOL)
    cEOL := &cEOL
Endif

Default cArqTxt := "gwaya.log"
Default cGrava  := ""

cArqTxt := cDirLog + iif( ! Empty(cDirLog) .And. SubStr(cDirLog,Len(cDirLog),1) <> "\","\","") + cArqTxt
cLin    := Space(254) + cEOL 
nHdl    := fOpen(cArqTxt, FO_READWRITE)
nError  :=  fError()
 
If nError <> 0 .And. nError <> 2 .AND. nHdl == -1

	if nError == 2 .OR. nError == 161 // Arquivo nใo existe
		nHdl    := fCreate(cArqTxt)	
	endif
	
Endif

If nHdl == -1
    MsgAlert("O arquivo de nome "+cArqTxt+" nใo pode ser criado! FERROR: " +  AllTrim(Str(fError())),"Aten็ใo!")
    Return
Endif

if ! Empty(cGrava)

	// Posiciona no fim do arquivo, retornando o tamanho do mesmo
    fSeek(nHdl, 0, FS_END)

	cGrava  := DtoC(Date()) + " " + Time() + " >> " + cGrava  
    cLin    := Stuff(cLin,1,Len(cGrava),cGrava)
    
    //ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
    //ณ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ณ
    //ณ linha montada.                                                      ณ
    //ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
    If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
        MsgAlert("Ocorreu um erro na grava็ใo do arquivo " + cArqTxt + "!","Aten็ใo!")
        conout(DtoC(Date()) + " " + Time() + " >> " + "GwLog() ocorreu um erro na gravacao do arquivo " + cArqTxt + "!")
    Endif

endif

fClose(nHdl)

Return