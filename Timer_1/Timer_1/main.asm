/*
* NombreProgra.asm
*
* Creado: 
* Autor : 
* Descripción: ejemplo timer 1
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
	jmp START
.org OVF1addr
	jmp ISR_TMR1


START:
.equ OCR1A_value=0xF424
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
	CLI
    //Configurar clock a 1 MHz
	LDI		R16, (1<<CLKPCE) // Habilitamos el prescaler
	STS		CLKPR, R16
	LDI		R16, 0b00000100 // Divisor de 16

	SBI DDRB,DDB0
    SBI DDRB,DDB5
	CBI PORTB,PORTB0
	CBI PORTB,PORTB5
	
	CALL INIT_TMR1

	ldi r16, (1<<OCIE1A)//habilitamos interrupcion de overflow
	STS TIMSK1, r16

	SEI

/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
INIT_TMR1:
	ldi R16, 0X00
	sts TCR1A, r16
	ldi r16, (1<<CS11)|(1<<WGM12)//prescaler de 64
	STS TCCR1B, r16

	LDI r16, HIGH(OCR1A_value)
	STS TCNT1H,r16
	LDI r16, LOW(OCR1A_value)
	STS TCNT1L,r16

	ret

/****************************************/
// Interrupt routines
ISR_TMR1:
	push r16
	IN r16, SREG
	push r16

	LDI r16, HIGH(OCR1A_value)
	STS OCR1AH,r16
	LDI r16, LOW(OCR1A_value)
	STS OCR1AL,r16

	SBI PINB, PINB0
	SBI PINB, PINB5

	pop r16
	OUT SREG, r16
	pop

	RETI
/****************************************/
//Delay
delay:
    LDI R20, 0x0F
DEL0:
    LDI R21, 0x0F
DEL1:
    DEC R21
    BRNE DEL1
    DEC R20
    BRNE DEL0
    RET