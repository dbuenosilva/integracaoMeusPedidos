#INCLUDE "totvs.ch"
#INCLUDE "fileio.ch"
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � GwLog  � Autor � Diego Bueno          � Data �  06/09/17   ���
�������������������������������������������������������������������������͹��
���Descricao � Grava Logs em /system/gwaya.log                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � Jopy                                                       ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function GwLog(cArqTxt,cGrava)

//���������������������������������������������������������������������Ŀ
//� Cria o arquivo texto                                                �
//�����������������������������������������������������������������������
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

	if nError == 2 .OR. nError == 161 // Arquivo n�o existe
		nHdl    := fCreate(cArqTxt)	
	endif
	
Endif

If nHdl == -1
    MsgAlert("O arquivo de nome "+cArqTxt+" n�o pode ser criado! FERROR: " +  AllTrim(Str(fError())),"Aten��o!")
    Return
Endif

if ! Empty(cGrava)

	// Posiciona no fim do arquivo, retornando o tamanho do mesmo
    fSeek(nHdl, 0, FS_END)

	cGrava  := DtoC(Date()) + " " + Time() + " >> " + cGrava  
    cLin    := Stuff(cLin,1,Len(cGrava),cGrava)
    
    //���������������������������������������������������������������������Ŀ
    //� Gravacao no arquivo texto. Testa por erros durante a gravacao da    �
    //� linha montada.                                                      �
    //�����������������������������������������������������������������������
    If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
        MsgAlert("Ocorreu um erro na grava��o do arquivo " + cArqTxt + "!","Aten��o!")
        conout(DtoC(Date()) + " " + Time() + " >> " + "GwLog() ocorreu um erro na gravacao do arquivo " + cArqTxt + "!")
    Endif

endif

fClose(nHdl)

Return