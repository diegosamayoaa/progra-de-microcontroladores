/*
* Ejercicio de clase 1.asm
*
* Creado: 29/1/26
* Autor : Diego Samayoa
* Descripcion: Ejercicio de clase
*/
/****************************************/
// Encabezado (Definicion de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
 /****************************************/
// Configuracion de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
	//Configurar entradas y salidas
	//Output
	SBI DDRB, DDB0		// Bit 0 de DDRD seteado en 1; por lo tanto es una salida
	CBI PORTB, PORTB0	// Bit 0 apagado, valor de salida es 0
	//Inputs
	CBI DDRD, DDD5		// Bit 0 apagado, es una entrada
	CBI PORTD, PORTD5	// Deshabilitamos pull up

    
/****************************************/
// Loop Infinito
MAIN_LOOP:
	IN		R16, PIND		//Leer pin D y guardarlo en R16
	ANDI	R16, 0b00100000	//Mascara para solo dejar pasar el Pin 5 que es el que quiero leer
	BRNE	MAIN_LOOP
	SBI		PINB, PINB0		// Toggle que cambia el valor del bit 0 al opuesto; (TOGGLE SOLO FUNCIONA EN PIN)
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines

/****************************************/