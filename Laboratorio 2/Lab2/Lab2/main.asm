/*
* main.asm
*
* Creado:
* Autor : Diego Samayoa
* Descripción: Lab 2 - Contador hexadecimal (0-F) en display 7 segmentos 
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
    RJMP    SETUP

/****************************************/
// Tabla de display de 7 segmentos (HEX 0-F)
table7seg:    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

/****************************************/
// Configuración de la pila
SETUP:
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

/****************************************/
// Configuracion MCU
    CLI              

    //Configurar clock a 1 MHz (asumiendo reloj base 16 MHz -> /16)
    LDI     R16, (1<<CLKPCE)    // Habilitamos el prescaler
    STS     CLKPR, R16
    LDI     R16, 0b00000100     // Divisor de 16
    STS     CLKPR, R16

    //Disable UART
    LDI     R16, 0x00
    STS     UCSR0B, R16

    //DISPLAY:
    LDI     R16, 0b0011_1111
    OUT     DDRC, R16
    CLR     R16
    OUT     PORTC, R16
	SBI		DDRB, DDB0
	CBI     PORTB, PB0

    //PB1/PB2 entradas con pull-up (botones)

    SBI     PORTB, PB1          // pull-up PB1
    SBI     PORTB, PB2          // pull-up PB2
	    
    CLR     R19 
	CLR     R22                 

    // Mostrar inicial
    RCALL   display

/****************************************/
// Loop Infinito
MAIN_LOOP:
    //Botón 1 (incremento)
    SBIC    PINB, PB1           
    RJMP    boton_2
    RCALL   A_reb1
    RCALL   suma
    RCALL   display

boton_2:
    // Botón 2 (decremento)
    SBIC    PINB, PB2
    RJMP    MAIN_LOOP
    RCALL   A_reb2
    RCALL   resta
    RCALL   display
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

// Incremento 
suma:
    INC     R19
    ANDI    R19, 0x0F
    RET

// Decremento 
resta:
    DEC     R19
    ANDI    R19, 0x0F
    RET

// Actualizar display 
display:
    LDI     ZH, HIGH(table7seg<<1)
    LDI     ZL, LOW(table7seg<<1)
    ADD     ZL, R19
    ADC     ZH, R22
    LPM     R18, Z              

    // bits 0 a 5 a PORTC (A-F)
    MOV     R20, R18
    ANDI    R20, 0b0011_1111
    OUT     PORTC, R20

    // bit 6 a PB0 (G)
    CBI PORTB, PB0
	SBRC R18,6
	SBI PORTB, PB0
	RET

// Anti-rebote PB1
A_reb1:
    RCALL   delay
    SBIC    PINB, PB1           ; ver estado del boton
    RET
esperar_1:
    SBIS    PINB, PB1           ; esperar soltado
    RJMP    esperar_1
    RCALL   delay
    RET

; Anti-rebote PB2
A_reb2:
    RCALL   delay
    SBIC    PINB, PB2
    RET
esperar_2:
    SBIS    PINB, PB2
    RJMP    esperar_2
    RCALL   delay
    RET

/****************************************/
// Interrupt routines


/****************************************/
//Delay

delay:
    LDI     R20, 80
DEL0:
    LDI     R21, 250
DEL1:
    DEC     R21
    BRNE    DEL1
    DEC     R20
    BRNE    DEL0
    RET
