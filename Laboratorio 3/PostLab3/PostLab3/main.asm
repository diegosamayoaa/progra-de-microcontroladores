/*
* main.asm
*
* Creado: 
* Autor : Diego Samayoa
* Descripción: Post Laboratorio 3, realizar un contador de decenas de segundos con dos display
*			   de 7 segmentos.
*/
/****************************************/

.include "M328PDEF.inc"

.dseg
.org SRAM_START
d_10ms:      .byte 1
unidades:     .byte 1
dece:      .byte 1

.cseg
.org 0x0000
RJMP RESET

.org 0x001C
RJMP TMR0

RESET:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16

    RJMP SETUP

; Disable USART
LDI R16, 0x00
STS UCSR0B, R16

Tabla_S7:
 .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

SETUP:
    CLR R1

    ; Segmentos PD1-PD7
    LDI R16, 0b11111110
    OUT DDRD, R16

    LDI R16, 0b11111110
    OUT PORTD, R16

    ; habilitar primer digito PC0
    SBI DDRC, DDC0
    SBI PORTC, PC0

    ; habilitar segundo digito PC1
    SBI DDRC, DDC1
    CBI PORTC, PC1

    CLR R16
    STS d_10ms, R16
    STS unidades, R16
    STS dece, R16

    ; setear TIMER0 CTC para 10ms
    LDI R16, (1<<WGM01)
    OUT TCCR0A, R16

    LDI R16, (1<<CS02)|(1<<CS00)
    OUT TCCR0B, R16

    LDI R16, 155
    OUT OCR0A, R16

    CLR R16
    OUT TCNT0, R16

    LDI R16, (1<<OCF0A)
    OUT TIFR0, R16

    LDI R16, (1<<OCIE0A)
    STS TIMSK0, R16

    SEI

MAIN_LOOP:
    RJMP MAIN_LOOP

TMR0:
    PUSH R16
    PUSH R17
    IN   R17, SREG
    PUSH R17

    ; contar 10ms
    LDS R16, d_10ms
    INC R16
    CPI R16, 100
    BRLO SAVE_10

    ; 1 segundo
    CLR R16
    STS d_10ms, R16

    ; suma de unidades
    LDS R16, unidades
    INC R16
    CPI R16, 10
    BRLO SAVE_UNIDADES

    ; resetear unidades
    CLR R16
    STS unidades, R16

    ; suma de decenas
    LDS R16, dece
    INC R16
    CPI R16, 6
    BRLO SAVE_DEC

    ; resetear en 60
    CLR R16
    STS dece, R16
    RJMP SHOW

SAVE_DEC:
    STS dece, R16
    RJMP SHOW

SAVE_UNIDADES:
    STS unidades, R16
    RJMP SHOW

SAVE_10:
    STS d_10ms, R16

SHOW:

    ; mostrar unidades
    SBI PORTC, PC0
    CBI PORTC, PC1

    LDS R16, unidades
    RCALL SEG7_DECODE
    RCALL SEG7_show
    RCALL delay

    ; mostrar decenas
    CBI PORTC, PC0
    SBI PORTC, PC1

    LDS R16, dece
    RCALL SEG7_DECODE
    RCALL SEG7_show
    RCALL delay

    POP R17
    OUT SREG, R17
    POP R17
    POP R16
    RETI


SEG7_show:

    LSL R16
    COM R16
    ANDI R16, 0b11111110
    OUT PORTD, R16
    RET


SEG7_DECODE:
    PUSH ZL
    PUSH ZH

    LDI ZH, HIGH(Tabla_S7*2)
    LDI ZL, LOW(Tabla_S7*2)

    ADD ZL, R16
    ADC ZH, R1

    LPM R16, Z

    POP ZH
    POP ZL
    RET

// Delay corto de alrededor de 10ms para multiplexar
delay:
    LDI R18, 30
D1:
    LDI R19, 200
D2:
    DEC R19
    BRNE D2
    DEC R18
    BRNE D1
    RET