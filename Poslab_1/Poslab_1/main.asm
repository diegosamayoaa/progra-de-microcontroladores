/*
* Lab1.asm
*
* Creado: 3/2/26
* Autor : Diego Samayoa
* Descripción: Poslaboratorio 1
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
 //Configurar clock a 1 MHz
	LDI		R16, (1<<CLKPCE) // Habilitamos el prescaler
	STS		CLKPR, R16
	LDI		R16, 0b00000100 // Divisor de 16
	STS		CLKPR, R16 
//Configuro los bits que voy a usar de salida y limpio la salida
	LDI r16,0xF0
	OUT DDRD, r16
	LDI r16, 0x0F
	OUT DDRB,r16
	LDI r16, 0b00011111     
	OUT DDRC, r16
	CLR r16
	OUT PORTD, r16
	OUT PORTB, r16
	OUT PORTC, r16
	
//Configuro bits que voy a usar de entrada y enciendo el pull up
	CBI DDRD,DDD2
	SBI PORTD,PORTD2
	CBI DDRD,DDD3
	SBI PORTD,PORTD3
	CBI DDRB,DDB4
	SBI PORTB,PORTB4
	CBI DDRB,DDB5
	SBI PORTB,PORTB5
	LDI r16, 0b00100000
	OUT PORTC, r16
	clr r16
	clr r17
	clr r18
	clr r19
	clr r20
	clr r21
	clr r22
	clr r23

    
/****************************************/
// Loop Infinito
MAIN_LOOP:
    call CONTADOR_1
    call CONTADOR_2
	call SUMADOR
    rjmp MAIN_LOOP

//***************************************/
;Contador 1 encargado de los 4 bits menos significativos del port D
;Boton situado en PIND2 es para incrementar y el boton en PIND3 es para restar
;r16 es el encargado de ser el contador
//***************************************/
CONTADOR_1:
    IN r18, PIND
    ANDI r18, 0b00001100
    CPI  r18, 0b00001100
    BREQ MUESTRA_LOW

    RCALL delay

    IN r19, PIND
    ANDI r19, 0b00001100
    CP r19,r18
    BRNE MUESTRA_LOW

    sbrs r19, 2
    rcall INCREASE_1

    sbrs r19, 3
    rcall DECREASE_1

MUESTRA_LOW: ; este se utiliza para hacer un OUT de los valor que cambiar
    IN r20, PORTB
    ANDI r20, 0xF0 ; Mantengo bit alto
    mov r21, r16
    ANDI r21, 0x0F
    OR   r20, r21
    OUT PORTB,r20
    ret

//Increase 1
INCREASE_1:
    INC r16
    ANDI r16, 0x0F
A_REB1:
    SBIS PIND, 2
    RJMP A_REB1
    RCALL delay
    RET

//Decrease 1
DECREASE_1:
    DEC r16
    ANDI r16, 0x0F
A_REB2:
    SBIS PIND, 3
    RJMP A_REB2
    RCALL delay
    RET

//***************************************/
;Contador 2 encargado de los 4 bits mas significativos del port D
;Boton situado en PINB4 es para incrementar y el boton en PINB5 es para restar
;r17 es el encargado de ser el contador
//***************************************/
CONTADOR_2:
    IN r18, PINB
    ANDI r18, 0b00110000
    CPI  r18, 0b00110000
    BREQ MUESTRA_HIGH

    RCALL delay

    IN r19, PINB
    ANDI r19, 0b00110000
    CP r19,r18
    BRNE MUESTRA_HIGH

    sbrs r19, 4
    rcall INCREASE_2

    sbrs r19, 5
    rcall DECREASE_2

MUESTRA_HIGH:
    IN r20, PIND
    ANDI r20, 0x0F ; Mantengo bit bajo
    mov r21, r17
    ANDI r21, 0x0F
    SWAP r21 ; intercambia los nibbles del registro
    OR   r20, r21
    OUT PORTD,r20
    ret

//Increase 2
INCREASE_2:
    INC r17
    ANDI r17, 0x0F
A_REB_1:
    SBIS PINB, 4
    RJMP A_REB_1
    RCALL delay
    RET

//Decrease 2
DECREASE_2:
    DEC r17
    ANDI r17, 0x0F
A_REB_2:
    SBIS PINB, 5
    RJMP A_REB_2
    RCALL delay
    RET

//***************************************/
;Sumador de ambos registros
;Boton para activarlo se encuentra en PINC5
;Leds que muestran resultado de 4 bits estan en PINC0-PINC3
;Led de que muestra si hay overflow se encuentra en PINC4
//***************************************/

SUMADOR:
	IN r24,PINC
	SBRC r24,5
	ret

	rcall delay

	IN r24,PINC
	SBRC r24,5
	ret

	mov r22, r24
	add r22,r17
	mov r23,r22
	andi r23, 0xF0
	CPI r23, 0x00
	BREQ no_of
	SBI PORTC, PORTC4
	rjmp led_sum 

no_of:
	CBI PORTC, PORTC4
led_sum:
	in r18, PORTC
	andi r18,0b11110000
	mov r19,r22
	andi r19, 0b00001111
	or r18, r19
	out PORTC, r18

A_REB_SUM:
	SBIS PINC,5
	rjmp A_REB_SUM
	rcall delay
	ret

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