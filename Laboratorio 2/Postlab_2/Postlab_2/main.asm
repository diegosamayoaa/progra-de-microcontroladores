/*
* main.asm
*
* Creado:
* Autor : Diego Samayoa
* Descripción: post lab 2 - Contador hexadecimal (0-F) en display 7 segmentos 
*              Contador de segundos (4 bits) con Timer0 (tick cada 100ms).
*/            
//****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

.dseg
.org    SRAM_START
//variable_name:     .byte   1

.cseg
.org 0x0000
    RJMP    SETUP

/****************************************/

table7seg:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

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

    //Configurar clock a 1 MHz 
    LDI     R16, (1<<CLKPCE)
    STS     CLKPR, R16
    LDI     R16, 0b00000100     // /16
    STS     CLKPR, R16

    //Disable UART
    LDI     R16, 0x00
    STS     UCSR0B, R16

    //DISPLAY:
    LDI     R16, 0b0011_1111
    OUT     DDRC, R16
    CLR     R16
    OUT     PORTC, R16

    SBI     DDRB, DDB0          // G en PB0
    CBI     PORTB, PB0

    //PB1/PB2 entradas con pull-up
    SBI     PORTB, PB1
    SBI     PORTB, PB2

    //LEDS contador de segundos en PD2-PD5 y LED alarma en PD6
    LDI     R16, 0b01111100
    OUT     DDRD, R16
    CLR     R16
    OUT     PORTD, R16

    //Inicializaciones
    CLR     R19                 // contador por botones 
    CLR     R23                 // contador de segundos 
    CLR     R24                 // ticks de 100ms 
    CLR     R22                 // carry

    //Mostrar estado inicial
    RCALL   display
    RCALL   leds
    CBI     PORTD, PD6          // alarma apagada al inicio

    //Timer0 CTC -> tick ~100ms
    LDI     R16, (1<<WGM01)
    OUT     TCCR0A, R16
    LDI     R16, (1<<CS02)|(1<<CS00)     // /1024
    OUT     TCCR0B, R16
    LDI     R16, 97
    OUT     OCR0A, R16
    CLR     R16
    OUT     TCNT0, R16

    // limpiar flag inicial
    LDI     R16, (1<<OCF0A)
    OUT     TIFR0, R16

    SEI

/****************************************/
// Loop Infinito
MAIN_LOOP:
    RCALL   timer

    //Botón 1 (incremento) PB1 (activo en 0)
    SBIC    PINB, PB1
    RJMP    boton_2
    RCALL   A_reb1
    RCALL   suma
    RCALL   display

boton_2:
    //Botón 2 (decremento) PB2 (activo en 0)
    SBIC    PINB, PB2
    RJMP    MAIN_LOOP
    RCALL   A_reb2
    RCALL   resta
    RCALL   display
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

timer:
    // Polling del flag
    IN      R16, TIFR0
    SBRS    R16, OCF0A
    RET

    // borrar flag
    LDI     R16, (1<<OCF0A)
    OUT     TIFR0, R16

    // tick 100ms
    INC     R24
    CPI     R24, 10
    BRLO    timer_end

    // llegó a 1 segundo
    CLR     R24

    // contador de segundos
    INC     R23
    ANDI    R23, 0x0F
    RCALL   leds

    // si segundos igual botones; reiniciar contador y encender alarma
    CP      R23, R19
    BRNE    timer_end

    CLR     R23
    RCALL   leds

    // TOGGLE PD6 
    IN      R16, PORTD
    LDI     R17, (1<<PD6)
    EOR     R16, R17
    OUT     PORTD, R16

timer_end:
    RET

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
    CBI     PORTB, PB0
    SBRC    R18, 6
    SBI     PORTB, PB0
    RET

// Actualizar leds del contador de segundos (PD2-PD5)

leds:
    IN      R16, PORTD
    ANDI    R16, 0b11000011     // limpio PD2 PD5, guardo PD6
    MOV     R17, R23
    LSL     R17					//Mover bits a la izquierda
    LSL     R17
    ANDI    R17, 0b00111100
    OR      R16, R17
    OUT     PORTD, R16
    RET

// Anti-rebote PB1
A_reb1:
    RCALL   delay
    SBIC    PINB, PB1
    RET
esperar_1:
    SBIS    PINB, PB1
    RJMP    esperar_1
    RCALL   delay
    RET

// Anti-rebote PB2
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
