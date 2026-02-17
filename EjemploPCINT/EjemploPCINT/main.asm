/*
* main.asm
*
* Creado: 
* Autor : 
* Descripción: PCINT ejemplo de clase
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
.org PCI2addr
	JMP ISR_PCINT2
 /****************************************/
// Configuración de la pila
START:
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
	STS		CLKPR, R16 

	//COnfigurar entradas y salidas
	CBI DDRD, DDD2
	SBI DDRD, PORTD2
	SBI DDRB, DDB0
	SBI DDRB, DDB5
	CBI PORTB, PORTB0
	CBI PORTB, PORTB5

	//Configurar PCINT2
	LDI r16, (1<<PCIE2)
	STS PCICR, r16
	LDI r16, (1<<PCINT18)
	OUT PCMSK2, r16

	SEI
/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines
ISR_PCINT2:
	PUSH r16
	IN r16, SREG
	PUSH r16
	
	SBIS PIND, PIND2
	SBI PINB,PB0
	SBIS PIND, PIND2
	SBI PINB,PB5

	POP r16
	out SREG, r16
	POP r16

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