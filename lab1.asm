/*
* Lab1.asm
*
* Creado: 3/2/26
* Autor : Diego Samayoa
* Descripción: Practica de laboratorio 1
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
//Configuro los bits que voy a usar de salida y limpio la salida
	LDI r16,0x0F
	OUT DDRB, r16
	CLR r16
	OUT PORTB, r16
	
//Configuro bits que voy a usar de entrada y enciendo el pull up
	CBI DDRD, DDD4
	CBI DDRD, DDD5 
	SBI PORTD, PORTD4 
	SBI PORTD, PORTD5 
	clr r16

    
/****************************************/
// Loop Infinito
MAIN_LOOP:
	IN r17, PIND
	ANDI r17, 0b00110000
	CPI  r17, 0b00110000
	BREQ MAIN_LOOP

	RCALL delay

	IN r18, PIND
	ANDI r18, 0b00110000
	CP r18,r17
	BRNE MAIN_LOOP

	sbrs r18, 5
	rcall INCREASE

	sbrs r18, 4
	rcall DECREASE

	MOV r19,r16
	ANDI r19,0x0F
	OUT PORTB, r19
	RJMP MAIN_LOOP
//Increase
INCREASE:
	INC r16
	ANDI r16, 0x0F
A_REB:
	SBIS PIND, 5 
	RJMP A_REB
	RCALL delay
	RET
//Decrease
DECREASE:
	DEC r16 
	ANDI r16, 0x0F 
A_REB2:
	SBIS PIND, 4  
	RJMP A_REB2
	RCALL delay
	RET



/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines

/****************************************/
//Delay
delay:
    LDI R20, 0xFF            
DEL0:
    LDI R21, 0xFF           

DEL1:
    DEC R21
    BRNE DEL1
    DEC R20
    BRNE DEL0
    RET