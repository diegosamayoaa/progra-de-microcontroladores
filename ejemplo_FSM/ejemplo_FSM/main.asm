/*
* ejemplo_FSM.asm
*
* Creado: 
* Autor : 
* Descripción: ejemplo de maquina de estado finito, 4 modos 
*				1 suma con boton
*				2 resta con boton
*				3 suma con timer 0.5s
*				4 resta con timer 0.5s
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

.equ T1VALUE=0XE17B
.equ MAX_MODES= 4
.def MODE=R20
.def COUNTER=R21
.def ACTION=R22

.cseg
.org 0x0000
	jmp START

// Vectores de interrupcion
.org PCI2addr
	jmp  PIND_ISR
.org OVF1addr
	jmp TMR1_ISR


START:
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

//Declaramos salidas
	SBI DDRB, DDB0
	SBI DDRB, DDB1
	CBI PORTB, PORTB0
	CBI PORTB, PORTB1
	SBI DDRC, DDC0
	SBI DDRC, DDC1
	SBI DDRC, DDC2
	SBI DDRC, DDC3
	CBI PORTC, PORTC0
	CBI PORTC, PORTC1
	CBI PORTC, PORTC2
	CBI PORTC, PORTC3

//Declaramos entradas; 2 botones con pullup

	CBI DDRD, DDD2
	CBI DDRD, DDD3
	SBI PORTD, PORTD2
    SBI PORTD, PORTD3

// Configuramos timer 1
	call INIT_TMR1

//Inicializar variables/registros
	CLR MODE
	CLR COUNTER
	CLR ACTION


// Habilitar interrupciones
// timer 1
	ldi r16, (1<<TOIE1)
	sts TIMSK1, r16
// PD2 y PD3 pinchange
	LDI r16, (1<< PCIE2)
	STS PCICR, r16
	ldi r16, (1<<PCINT19)|(1<<PCINT18)
	STS PCMSK2, r16
//Interrupciones globales habilitadas

	SEI

/****************************************/
// Loop Infinito
MAIN_LOOP:

	OUT PORTC, COUNTER
	OUT PORTB, MODE
	CPI MODE, 0
	BREQ INC_MODE
	CPI MODE, 1
	BREQ DEC_MODE
	CPI MODE, 2
	BREQ AUTO_INC_MODE
	CPI MODE, 3
	BREQ AUTO_DEC_MODE
    RJMP MAIN_LOOP

INC_MODE:
	CPI ACTION, 0X01
	BRNE EXIT_IM
	INC COUNTER
	ANDI COUNTER, 0X0F
	clr ACTION

EXIT_IM:
	RJMP MAIN_LOOP

DEC_MODE:
	CPI ACTION, 0X01
	BRNE EXIT_DM
	DEC COUNTER
	ANDI COUNTER, 0X0F
	clr ACTION

EXIT_DM:
	RJMP MAIN_LOOP

AUTO_INC_MODE:
	CPI ACTION, 0X01
	BRNE EXIT_AIM
	INC COUNTER
	ANDI COUNTER, 0X0F
	clr ACTION

EXIT_AIM:
	RJMP MAIN_LOOP

AUTO_DEC_MODE:
	CPI ACTION, 0X01
	BRNE EXIT_ADM
	DEC COUNTER
	ANDI COUNTER, 0X0F
	clr ACTION

EXIT_ADM:
	RJMP MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
INIT_TMR1:
	ldi r16, 0x00
	sts TCCR1A, r16
	ldi r16, (1<<CS11)|(1<<CS10) // prescaler 64
	sts TCCR1B, r16
	ldi r16, HIGH(T1VALUE)
	STS TCNT1H, r16
	ldi r16, LOW(T1VALUE)
	STS TCNT1L, r16
	ret
/****************************************/
// Interrupt routines
PIND_ISR:
	PUSH R16
	IN R16, SREG
	PUSH R16

	SBIS PIND, PIND2
	RJMP CONTINUAR
	INC MODE
	CPI MODE, MAX_MODES
	BRNE CONTINUAR
	CLR MODE


CONTINUAR:
	CPI MODE, 0
	BREQ INC_MODE_ISR
	CPI MODE, 1
	BREQ DEC_MODE_ISR
	CPI MODE,2 
	BREQ AUTO_INC_MODE_ISR
	CPI MODE,3
	BREQ AUTO_DEC_MODE_ISR
	RJMP EXIT_PIND_ISR

INC_MODE_ISR:
	SBIC PIND,PIND3
	BREQ EXIT_PIND_ISR
	LDI ACTION, 0X01
	RJMP EXIT_PIND_ISR

DEC_MODE_ISR:
	SBIC PIND,PIND3
	BREQ EXIT_PIND_ISR
	LDI ACTION, 0X01
	RJMP EXIT_PIND_ISR

AUTO_INC_MODE_ISR:
	RJMP EXIT_PIND_ISR

AUTO_DEC_MODE_ISR:
	RJMP EXIT_PIND_ISR

EXIT_PIND_ISR:
	POP R16
	OUT SREG, R16
	POP R16
	RETI
TMR1_ISR:

	PUSH R16
	IN R16, SREG
	PUSH R16

	ldi r16, HIGH(T1VALUE)
	STS TCNT1H, r16
	ldi r16, LOW(T1VALUE)
	STS TCNT1L, r16

	CPI MODE,0
	BREQ EXIT_TMR1_ISR
	CPI MODE, 1
	BREQ EXIT_TMR1_ISR
	CPI MODE, 2
	BREQ MODE2_ISR
	CPI MODE, 3
	BREQ MODE3_ISR

MODE2_ISR:
	ldi ACTION, 0X01
	RJMP EXIT_TMR1_ISR

MODE3_ISR:
	ldi ACTION, 0X01
	RJMP EXIT_TMR1_ISR

EXIT_TMR1_ISR:
	POP R16
	OUT SREG, R16
	POP R16

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