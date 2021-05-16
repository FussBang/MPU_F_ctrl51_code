$NOMOD51
$INCLUDE (83C51F.MCU)
adrRG1	equ	2000h	; registr dannyh
adrRG2	equ	2400h	; registr statusa
adrRG3	equ	2800h	; rezervirovannyj registr dlya UVV2
adrRG4	equ	2C00h	; rezervirovannyj registr dlya UVV2
adrRG5	equ	3000h	; rezervirovannyj registr dlya UVV2
adrRG6	equ	3400h	; rezervirovannyj registr dlya UVV2

		DSEG AT 34h
Using   0

;задание стека
STACKSIZE	EQU  20H
STACKR:		DS    STACKSIZE
STPOINT		EQU     $




FOPER:          DS	6
SOPER:          DS	6
TC		EQU 	46h
NC		EQU 	0Dh
EP		EQU	0FFh
		DSEG	AT	8

STACK_START:    DS 010h         ;reserve 10h bytes for stack



	CSEG AT 0
START:
		LCALL INIT_SERIAL

		JNB	P1.0,MRec	;modul' priema i otveta
        	JNB	P1.1,MSig	;modul' podachi del'ta-impul'sov
		JNB	P1.2,MDiag	;modul' diagnostiki
        	MOV	DPTR,#ERRTXT
        	CALL	TXTOUT
        	JMP	START

	MRec:
		MOV	DPTR,#INTROTXT
        	CALL	TXTOUT
     		AJMP    PROG   ; vypolnenie programmy priema paketov dannyh i paketa "start"
	MSig:
 	        MOV	DPTR,#ERRTXT
        	CALL	TXTOUT
 		AJMP   	START ; vypolnenie programmy podachi signala
	MDiag:
 	        MOV	DPTR,#ERRTXT
        	CALL	TXTOUT
 		AJMP  	START ; vypolnenie programmy podachi signala

PROG:
		MOV	R2,#0		;GLOBAL
	WAIT_PACK:
		MOV 	R0,#FOPER
		MOV	R7,#6		;LOCAL 
		MOV 	R3,#0		;LOCAL;FOR START PACK BYTES COUNTER
		MOV	R5,#0		;LOCAL
		INC	R2

		GET_PACK:
		CLR 	P1.7
		JNB 	P3.2,$
		MOV 	DPTR,#ADRRG1
		MOVX 	A,@DPTR
		MOV 	@R0,A
		INC 	R0
		CALL 	STRPACK			;CALL PP CHECKING FOR START PACK
		INC	R3
		MOV	DPTR,#adrRG2
		MOVX	A,@DPTR
		CJNE 	R4,#0DFh, NOT_STRPACK	;CONDITION TO CONTINUE: IN R4 LIES NOT DFH
		JMP 	END_PRG			;IF CONDITION FALSE, THEN START PACK HAS COME 
		NOT_STRPACK:
		DJNZ 	R7,GET_PACK

	FPACK_TO_VT:
		CALL 	NUMPACK
		MOV	R0,#FOPER
      		MOV	R7,#6
		OUT_VT:
		MOV	A,@R0
		CALL	AHEX1
		CALL	SPACE
		INC	R0
		DJNZ	R7,OUT_VT
		CALL	CRLF1

	CHCK_PACK:
		MOV 	R1,#FOPER ;
		CJNE 	@R1,#TC,WAIT_PACK  ; proverka pervogo bajta paketa, skip esli ne podoshel
		INC 	R1
		CJNE 	@R1,#NC,WAIT_PACK  ; proverka vtorogo bajta paketa, skip esli ne podoshel
		MOV 	A,R1
		ADD 	A,#04h
		MOV 	R1,A
		CJNE 	@R1,#EP,WAIT_PACK

					; НАЙДЕН СВОЙ
		MOV 	R7,#6
		MOV 	R0,#FOPER	;zapihivaet dlinu v r7, adresa v r0 i r1
		MOV 	R1,#SOPER
	SAVE_PACK:
		MOV 	A,@R0		;zapihivaet moj paket v hranilishche po bajtu
		MOV 	@R1,A
		INC 	R1
		INC 	R0
		DJNZ 	R7,SAVE_PACK
		SETB 	F0
		CALL 	ANSWER
		MOV 	DPTR,#fndtxt
		CALL 	TXTOUT

	SPACK_TO_VT:
		CALL 	NUMPACK
		MOV	R0,#SOPER
      		MOV	R7,#6
		VT_OUT:
		MOV	A,@R0
		CALL	AHEX1
		CALL 	SPACE
		INC	R0
		DJNZ	R7,VT_OUT
		CALL	CRLF1

		JMP	WAIT_PACK

	END_PRG:
	;
	;DFQ
	STPACK_TO_VT:
		CALL 	NUMPACK
		MOV	R0,#FOPER
      		MOV	R7,#3
		ST_OUT_VT:
		MOV	A,@R0
		CALL	AHEX1
		CALL	SPACE
		INC	R0
		DJNZ	R7,ST_OUT_VT
		CALL	CRLF1
		
		MOV	DPTR,#NDTXT
        	CALL	TXTOUT
		JMP 	$

	; ---------------------------------------------------------
	;                ??
	; ---------------------------------------------------------



introtxt: 	DB	'Strt',0Ah,0Dh,2
fndtxt: 	DB	'Fnd F 13: ',2
ndtxt: 		DB	'Rcv cmt.Rn',0Ah,0Dh,2
errtxt:		DB	'Err,wrong sw',0Ah,0Dh,2
	; ---------------------------------------------------------
	;                  подпрограммы
	; ---------------------------------------------------------
	STRPACK:
		CJNE	R3,#0,SEC_B_P	; proverka na nomer prishedshego bajta
		CJNE	A,#0,PACKEN	; proverka na pervoe znachenie paketa "start"
		INC	R5
		JMP	PACKEN
		SEC_B_P:
		CJNE	R3,#1,THR_B_P
		CJNE	A,#53h,PACKEN	; proverka na vtoroe znachenie paketa "start"
		CJNE	R5,#1,PACKEN	; proverka na nomer bajta paketa "start"
		INC	R5
		JMP	PACKEN
		THR_B_P:
		CJNE	R3,#2,PACKEN
		CJNE	A,#0FFh,PACKEN	; proverka na tret'e znachenie paketa "start"
		CJNE	R5,#2,PACKEN
		SETB	p1.7		;
		MOV	R5,#0		;
		MOV	R4,#0DFh 
	PACKEN:
		RET	
;-----------------------------------------------------------------------------------------------------

	ANSWER:
		;otvetnyj impul's posle priema upravlyayushchego paketa "svoj"
		MOV 	DPTR,#ADRRG2
		MOV 	A,#16
		CLR 	P1.6
		MOVX 	@DPTR,A
		NOP
		NOP
		MOV 	A,#0
		MOVX 	@DPTR,A
		SETB 	P1.6

		RET

	NUMPACK:
		MOV 	A,R2
		CALL 	AHEX1
		MOV	A,#02Eh
		CALL	VIVOD
		
		RET
;pp vor------------------------------------------------------------------------------------------------
	VIVOD:
		; драйвер вывода на терминал
		; вывод производится после окончания предыдущего преобразования и установки флага TI
		MOV	SBUF,A	; передача байта
		JNB	TI,$	; ожидание флага "передача завершена"
		CLR	TI	; очистка бита вручную	
		RET
	TXTOUT:
	; dptr - адрес текста
	; dst - A,F, r5
		MOV	R6,#0

		TXT_PRN1:
		MOV	A,R6
		MOVC	A,@A+DPTR
		CJNE	A,#2,TXT_PRN2
		RET
		TXT_PRN2:
		CALL	VIVOD
		INC	R6
		JMP	TXT_PRN1

	SPACE:
		MOV	A,#20H
		CALL	VIVOD
		RET
		;cr_:
	CRLF1:
		MOV	A,#0DH
		CALL	VIVOD
		RET
		
	LOOP_BUF:
		MOV A,@R1
		CALL AHEX1
		CALL SPACE
		INC R1
		DJNZ R7,LOOP_BUF
		CALL CRLF1

		RET
	AHEX1:
; ПП вывода hex-числа через SP на виртуальный терминал
; HEX-число в аккумуляторе
; dst - A,F, R5, 
     	  	MOV     R5,A
      		SWAP    A       ; поменять местами мл. и ст. тетрады
      		CALL    TRNF_HEX1
       		CALL	VIVOD
      		MOV     A,R5
       		CALL    TRNF_HEX1
       		CALL	VIVOD
       		RET

	TRNF_HEX1:
 ; преобразование мл. тетрады  акккумулятора в ASCII-код
; dst: acc, f
       		CLR     C
       		ANL     A,#0FH  ;выделение мл. тетрады
       		SUBB    A,#0AH  ; проверка литера-цифра
      		JC      DIGIT2
     		ADD     A,#(37H+0AH)    ; преобразование в ASCII для литеры
      		SJMP    EXITT
		digit2:
   		ADD     A,#(30H+0AH)     ; преобразование в ASCII для цифры
		EXITT:
      		RET

 	INIT_SERIAL:
; инициализация UART
;Mode				= 1/8-bit UART
;Serial Port Interrupt		= Disabled
;Receive			= Enabled
;Auto Addressing		= Disabled
; разрешение передачи для драйвера CO разрешено!!!
   		mov SCON, #050h
;Timer 2 is being used to generate baud rates.
    		mov RCAP2L, #0D9h
    		mov RCAP2H, #0FFh
    		mov T2CON, #034h
    		CLR RI              ;SCON.0
    		clr	TI
    		ret 
end
