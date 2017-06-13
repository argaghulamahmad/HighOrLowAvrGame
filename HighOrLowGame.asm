;High Or Low Game - Tugas Akhir Pengantar Organisasi Komputer
;1606821601 - Arga Ghulam Ahmad
;1606879773 - Misael Jonathan
;1606917600 - Reza Ramadhansyah Putra

.include "m8515def.inc"

;.def temp1 = r16 ;
;.def temp2 = r17 ; 
.def ledData = r20 ; simpan informasi led correct incorrect
.def angka1 = r21 ; angka sebelum
.def angka2 = r22 ; angka sekarang
.def point = r23 ; point
.def point_digit2 = r15 ; simpan informasi point yang didapatkan
.def tempA = r25
.def tempC = r18
.def A  = r19
.def PB = r24
.def ZH_temp = r27
.def ZL_temp = r26
.def checker = r28

.org $00
rjmp MAIN
.org $01
rjmp ext_int0	
.org $02
rjmp ext_int1
.org $06
rjmp ISR_TOV1


MAIN:
	cbi PORTA,1 
	ldi PB,$01 
	out PORTB,PB
	sbi PORTA,0
	cbi PORTA,0
	ldi angka2, 0
	ldi tempA, 0
	ldi checker, 0
	ldi point, 0x30

INIT_STACK:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

INIT_LED:
	ldi r16,low(RAMEND)
	out SPL,r16
	ldi r16,high(RAMEND)
	out SPH,r16
	ldi r16, 0x03 ;(1<<CS01) ;
	out TCCR1B,r16
	ldi r16, (1<<TOV1)
	out TIFR,r16
	ldi r16, (1<<TOIE1)
	out TIMSK,r16
	ldi ledData, 0x03
	out DDRE, ledData
	ser tempC
	out DDRC, tempC
	ldi tempC, 0xff
	out PORTC, tempC ;; BUAT LAMPU INIT_LED:	

INIT_INTERRUPT:
	ldi r16,0b00001010
	out MCUCR,r16
	ldi r16,0b11000000
	out GICR,r16	

INIT_LCD_MAIN:
	rcall INIT_LCD
	ser r16
	out DDRA,r16
	out DDRB,r16

INPUT_OPENING: ;LOAD OPENING
	ldi ZH,high(2*opening)
	ldi ZL,low(2*opening)
	rjmp LOADBYTE2

ACTIVATE_SEI:
	sei

INPUT_TEXT: ;LOAD ANGKA (NUMARRAY)
	ldi ZH_temp,high(2*numArray)
	ldi ZL_temp,low(2*numArray)

INPUT_KET:
	ldi ZH,high(2*next_number)
	ldi ZL,low(2*next_number)
	rjmp LOADBYTE_KET

	;add ZL,tempA
	;add ZH,tempA

INPUT_PEMANIS:
	ldi ZH,high(2*pemanis)
	ldi ZL,low(2*pemanis)
	ldi checker, 0
	rjmp LOADBYTE_PEMANIS

INPUT_NUM:
	mov ZH, ZH_temp
	mov ZL, ZL_temp
	rjmp LOADBYTE1

INPUT_CLOSING:  ;LOAD CLOSING
	rcall CLEAR_LCD
	ldi ZH,high(2*closing)
	ldi ZL,low(2*closing)
	rjmp LOADBYTE3

LOADBYTE1: ;UNTUK LOAD ANGKA
	CLR ledData
	out PORTE, ledData
	;mov ZL,tempA
	lpm
	;tst r0
	;breq forever
	mov A, r0
	rcall WRITE_TEXT
	mov angka1, angka2 ;MEMASUKKAN ANGKA KE TEMP VARIABLE
	mov angka2, r0
	adiw ZL_temp,1
	rjmp ENTER_END

ENTER_END:
	cbi PORTA,1 
	cbi PORTA,2
	ldi PB, 0xA7 ; perintah pindah baris
	out PORTB, PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_02
	adiw ZL,1
	rjmp INPUT_PEMANIS

LOADBYTE_PEMANIS:
	lpm
	tst r0
	breq CHANGE
	mov A, r0
	rcall WRITE_TEXT
	adiw ZL,1
	rjmp LOADBYTE_PEMANIS

CHANGE:
	rcall DELAY_03
	rcall DELAY_03
	rcall CLEAR_LCD
	rjmp INPUT_KET

LOADBYTE2: ;UNTUK LOAD OPENING, TANPA DELAY
	lpm ; Load byte from program memory into r0

	tst r0 ;CHECK KALAU UDAH END OF TEXT (KETEMU 0), LANJUT MASUK DISPLAY NUM ARRAY
	breq DELAYPRAOP ;
	
	mov r16, r0
	cpi r16, 1
	breq ENTER_LOAD2
	mov A, r0 ; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 ; Increase Z registers
	rjmp LOADBYTE2

LOADBYTE_KET: ;LOAD CURRENT NUM (TULISAN)
	lpm
	tst r0
	breq INPUT_NUM
	mov A, r0
	rcall WRITE_TEXT
	adiw ZL,1
	rjmp LOADBYTE_KET

DELAYPRAOP:
	rcall DELAY_02
	rcall DELAY_02
	rcall CLEAR_LCD
	rcall DELAY_02
	rjmp ACTIVATE_SEI


LOADBYTE3: ;UNTUK LOAD CLOSING, TANPA DELAY & END PROG
	lpm ; Load byte from program memory into r0

	tst r0 ;CHECK KALAU UDAH END OF TEXT (KETEMU 0), LANJUT KELUAR
	breq SHOW_SCORE ;
	
	mov r16, r0
	cpi r16, 1
	breq ENTER_LOAD3
	mov A, r0 ; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 ; Increase Z registers
	rjmp LOADBYTE3


SHOW_SCORE:
	tst point_digit2
	brne SHOW_SCORE_DIGIT2

SHOW_SCORE_DIGIT1:
	sbi PORTA,1
	out PORTB, point
	sbi PORTA,0
	cbi PORTA,0
	rcall DELAY_03
	rjmp END_PROG

SHOW_SCORE_DIGIT2:
	sbi PORTA,1
	out PORTB, point_digit2
	sbi PORTA,0
	cbi PORTA,0
	rcall DELAY_03
	rjmp SHOW_SCORE_DIGIT1

WRITE_TEXT_NUM:
	sbi PORTA,1
	out PORTB, A
	sbi PORTA,0
	cbi PORTA,0
	rcall DELAY_03
	rcall CLEAR_LCD
	ret

END_PROG:
	cli
	ldi ledData, 0x00
	out PORTE, ledData
	CLR ledData
	rjmp forever

ENTER_LOAD2:
	cbi PORTA,1 
	cbi PORTA,2
	ldi PB, 0xA7 ; perintah pindah baris
	out PORTB, PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_02
	adiw ZL,1
	rjmp LOADBYTE2

ENTER_LOAD3:
	cbi PORTA,1 
	cbi PORTA,2
	ldi PB, 0xA7 ; perintah pindah baris
	out PORTB, PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_02
	adiw ZL,1
	rjmp LOADBYTE3

INIT_LCD:
	cbi PORTA,1
	ldi PB,0x38
	out PORTB,PB
	sbi PORTA,0
	cbi PORTA,0
	rcall INIT_LCD_TYPE
	ret

INIT_LCD_TYPE:
	cbi PORTA,1
	cbi PORTA,2
	ldi PB,0b00001100
	out PORTB,PB
	sbi PORTA,0
	cbi PORTA,0
	ret

forever:
	rjmp forever

ISR_TOV1:
	lsl tempC
	out PORTC, tempC
	cpi tempC, 0
	breq indicatorLED ;kalau dah kelar/end
	reti 
	
indicatorLED:
	rcall TEST_SCORE
	rjmp INPUT_CLOSING

TEST_SCORE:
	cpi point, 0x39
	brsh DUA_DIGIT
	ret

DUA_DIGIT:
	ldi r16, 0x31
	add point_digit2, r16
	subi point, 9
	rjmp TEST_SCORE

ext_int0: ;HIGH
	cpi checker, 1
	breq END_INT
	inc checker
	cp angka2, angka1
	brsh add_point
	ldi ledData, 0x02
	out PORTE, ledData
	CLR ledData
	rjmp END_INT

END_INT:
	reti

ext_int1: ;LOW
	cpi checker, 1
	breq END_INT
	inc checker
	cp angka2, angka1
	brlo add_point
	ldi ledData, 0x02
	out PORTE, ledData
	CLR ledData
	reti

add_point:
  	inc point
	ldi ledData, 0x01
	out PORTE, ledData
	CLR ledData
  	reti

CLEAR_LCD:
	cbi PORTA,1 
	ldi PB,$01 
	out PORTB,PB
	sbi PORTA,0
	cbi PORTA,0
	rcall DELAY_01
	ret

WRITE_TEXT: ;OUTPUT TEXT
	sbi PORTA,1
	out PORTB, A
	sbi PORTA,0
	cbi PORTA,0
	rcall DELAY_01
	//rcall CLEAR_LCD
	ret

EXIT:
	rjmp EXIT

DELAY_01:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; DELAY_CONTROL 40 000 cycles
	; 5ms at 8.0 MHz

	    ldi  r16, 52
	    ldi  r17, 242
	L1: dec  r17
	    brne L1
	    dec  r16
	    brne L1
	    nop
	ret

DELAY_00:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 4 000 cycles
	; 500us at 8.0 MHz

	    ldi  r16, 6
	    ldi  r17, 49
	L0: dec  r17
	    brne L0
	    dec  r16
	    brne L0
	ret

DELAY_02:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 160 000 cycles
; 20ms at 8.0 MHz

	    ldi  r16, 208
	    ldi  r17, 202
	L2: dec  r17
	    brne L2
	    dec  r16
	    brne L2
	    nop
		ret
		
DELAY_03:
; Generated by delay loop calculator
; at http://www.bretmulvey.com/avrdelay.html
;
; Delay 320 000 cycles
; 40ms at 8.0 MHz

    ldi  r16, 2
    ldi  r17, 160
    ldi  r20, 147
L3: dec  r20
    brne L3
    dec  r17
    brne L3
    dec  r16
    brne L3
    nop
	ret



numArray:
.db "4","2","6","9","4", "5", "7", "1", "2", "3", "5", "9", "2", "7", "3", "5", "4","2","6","9","4", "5", "7", "1", "2", "3", "5", "9", "2", "7", "3", "5",0

opening:
.db "HIGH OR LOW GAME",1, " LETS PLAY !", 0

closing:
.db "GAME OVER",1, " points : ", 0

next_number:
.db "Current Num : ", 0

pemanis:
.db " High or Low ?", 0