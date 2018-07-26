#include "TOTVS.CH"   
/*‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±/ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒø±±
±±=Programa  = GwTiraGraf  = Autor = Diego Bueno        = Data = 13/01/15 =±±
±±vƒƒƒƒƒƒƒƒƒƒ˜ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ˜ƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒ¥±±
±±=Locacao   = GWAYA            =Contato = diego@gwaya.com                =±±
±±vƒƒƒƒƒƒƒƒƒƒ˜ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥±±
±±=Descricao = Programa para retirar caracteres especiais nao convertidos =±±
±±=          = pela funcao padrao da TOTVS NoAcento e converter para UTF8 =±±
±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
???????????????????????????????????????????????????????????????????????????*/

User Function GwTiraGraf(sOrig)
Private sRet 	  := ""  
Default sOrig := "" 
sRet := sOrig
   sRet = strtran (sRet, "·", " ")
   sRet = strtran (sRet, "È", "E")
   sRet = strtran (sRet, "Ì", "I")
   sRet = strtran (sRet, "Û", "U")
// sRet = strtran (sRet, "?", " ")
   sRet = STRTRAN (sRet, "¡", "i")
   sRet = STRTRAN (sRet, "…", " ")
   sRet = STRTRAN (sRet, "Õ", "O")
   sRet = STRTRAN (sRet, "”", " ")
   sRet = STRTRAN (sRet, "/", "-")
   sRet = strtran (sRet, "„", " ")
   sRet = STRTRAN (sRet, "’", " ")
   sRet = strtran (sRet, "‚", " ")
   sRet = strtran (sRet, "Í", "i")
   sRet = strtran (sRet, "Ó", "o")
   sRet = strtran (sRet, "Ù", "o")
   sRet = strtran (sRet, "°", " ")
   sRet = STRTRAN (sRet, "¬", " ")
   sRet = STRTRAN (sRet, "Œ", " ")
   sRet = STRTRAN (sRet, "‘", " ")
   sRet = STRTRAN (sRet, "€", " ")
   sRet = strtran (sRet, "Á", "A")
   sRet = strtran (sRet, "«", " ")
   sRet = strtran (sRet, "‡", " ")
   sRet = strtran (sRet, "¿", " ")
//   sRet = strtran (sRet, "?", ".")
   sRet = strtran (sRet, "™", " ")
   sRet = strtran (sRet, "'", " ")// Aspas simples
   sRet = strtran (sRet, chr(39), " ") // Aspas simples
   sRet = strtran (sRet, '"', " ")// Aspas duplas
   sRet = strtran (sRet, chr(34), " ")// Aspas duplas           
   sRet = strtran (sRet,"\t", " ")    // TAB
   sRet = strtran (sRet,"\u0009", " ")  //TAB   
   sRet = strtran (sRet, chr(13) + chr(10), " ") // EOL        
   sRet = strtran (sRet,"\n", " ")  // EOL
   sRet = strtran (sRet,"\r", " ")// EOL  
   sRet = strtran (sRet,chr(96), " ")//	crase `   
   
   // Demais caractes ASCII
   /*
   sRet = strtran (sRet, chr(0), " ")//	NUL (null)	==> limpa a string
   */
   sRet = strtran (sRet, chr(1), " ")//	SOH (start of heading)
   sRet = strtran (sRet, chr(2), " ")// STX (start of text)	
   sRet = strtran (sRet, chr(3), " ")//	ETX (end of text)	
   sRet = strtran (sRet, chr(4), " ")//	EOT (end of transmission)	
   sRet = strtran (sRet, chr(5), " ")//	ENQ (enquiry)	
   sRet = strtran (sRet, chr(6), " ")//	ACK (acknowledge)	
   sRet = strtran (sRet, chr(7), " ")//	BEL (bel)	
   sRet = strtran (sRet, chr(8), " ")//	BS (backspace)	
   sRet = strtran (sRet, chr(9), " ")//	TAB (horizontal tab)	
   sRet = strtran (sRet, chr(10), " ")// LF (NL line feed, new line)	
   sRet = strtran (sRet, chr(11), " ")// VT (verticle tab)	
   sRet = strtran (sRet, chr(12), " ")// FF (NP form feed, new page)	
   sRet = strtran (sRet, chr(13), " ")// CR (carriage return)	
   sRet = strtran (sRet, chr(14), " ")// SO (shift out)	
   sRet = strtran (sRet, chr(15), " ")// SI (shift in)	
   sRet = strtran (sRet, chr(16), " ")// DLE (data link exchange)	
   sRet = strtran (sRet, chr(17), " ")// DC1 (device control 1)	
   sRet = strtran (sRet, chr(18), " ")// DC2 (device control 2)	
   sRet = strtran (sRet, chr(19), " ")// DC3 (device control 3)	
   sRet = strtran (sRet, chr(20), " ")// DC4 (device control 4)	
   sRet = strtran (sRet, chr(21), " ")// NAK (negitive acknowledge)	
   sRet = strtran (sRet, chr(22), " ")// SYN (synchronous idle)	
   sRet = strtran (sRet, chr(23), " ")// ETB (end of trans. block)
   sRet = strtran (sRet, chr(24), " ")// CAN (cancel)	
   sRet = strtran (sRet, chr(25), " ")// EM (end of medium)	
   sRet = strtran (sRet, chr(26), " ")// SUB (substitute)
   sRet = strtran (sRet, chr(27), " ")// ESC (escape)	
   sRet = strtran (sRet, chr(28), " ")// FS (file separator)	
   sRet = strtran (sRet, chr(29), " ")// GS (group separator)	
   sRet = strtran (sRet, chr(30), " ")// RS (record separator)	
   sRet = strtran (sRet, chr(31), " ")// US (unit separator)   
   
   sRet = AllTrim(EnCodeUtf8(NoAcento(sRet))) 
     
return(sRet)