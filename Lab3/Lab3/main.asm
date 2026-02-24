/*
* main.asm
*
* Creado: 17/2/26
* Autor : Diego Samayoa
* Descripción:	contador hexadecimal de 4 bits utilizando una interrupción del TMR0. La
*				interrupción del TMR0 deberá ser entre 5 y 20ms, pero el contador deberá cambiar cada
*				1000ms. Muestre el contador con el TMR0 en un display de 7 segmentos, de manera que
*				se muestre el conteo en segundos.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)

.include "M328PDEF.inc"

;==============================
; VARIABLES EN SRAM
;==============================
.dseg
.org SRAM_START
delay_10: .byte 1
hexadecimal:    .byte 1

;==============================
; VECTORES
;==============================
.cseg
.org 0x0000
RJMP PILA

.org 0x001C
RJMP TMR0

;==============================
;Configuración de la pila
;==============================
PILA:
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16

    RJMP SETUP

; Deshabilitar USART
LDI R16, 0x00
STS UCSR0B, R16


table7seg:
 .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

;==============================
; SETUP
;==============================
SETUP:
    CLR R1

    ; -------- SEGMENTOS PD1–PD7 --------
    LDI R16, 0b11111110        ; PD1–PD7 para display
    OUT DDRD, R16

    ; Apagar segmentos (display de ánodo común ? 1=LOW)
    LDI R16, 0b11111110
    OUT PORTD, R16

    ; -------- DIGITO 1 EN PC0 --------
    SBI DDRC, DDC0             ; PC0 como salida (para habilitar la primera parte del display)
    SBI PORTC, PC0             ; activar dígito 1 (HIGH)

    ; -------- Inicializar variables --------
    CLR R16
    STS delay_10, R16
    STS hexadecimal, R16

    ;======== TIMER0 CTC ~10ms ========
    LDI R16, (1<<WGM01)
    OUT TCCR0A, R16

    LDI R16, (1<<CS02)|(1<<CS00)   ; prescaler /1024
    OUT TCCR0B, R16

    LDI R16, 155                   ; ~10ms
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

;==============================
; INTERRUPCIÓN TIMER0
;==============================
TMR0:
    PUSH R16
    PUSH R17
    IN   R17, SREG
    PUSH R17

    ; ---- contar 10ms ----
    LDS R16, delay_10
    INC R16
    CPI R16, 100
    BRLO GUARDAR

    ; ---- 1 segundo ----
    CLR R16
    STS delay_10, R16

    LDS R16, hexadecimal
    INC R16
    ANDI R16, 0x0F
    STS hexadecimal, R16

    RJMP MOSTRAR

GUARDAR:
    STS delay_10, R16

MOSTRAR:
    LDS R16, hexadecimal
    RCALL tabla
    RCALL show_disp

    POP R17
    OUT SREG, R17
    POP R17
    POP R16
    RETI

;==============================
; ESCRIBIR DISPLAY
;==============================
show_disp:
    ; R16 = patrón abcdefg (bit0=a ... bit6=g)

    LSL R16              ; mover a PD1–PD7
    COM R16              ; invertir (ánodo común)

    ANDI R16, 0b11111110 ; proteger PD0
    OUT PORTD, R16

    RET

;==============================
; TABLA HEX 0–F
;==============================
tabla:
    PUSH ZL
    PUSH ZH

    LDI ZH, HIGH(table7seg*2)
    LDI ZL, LOW(table7seg*2)

    ADD ZL, R16
    ADC ZH, R1

    LPM R16, Z

    POP ZH
    POP ZL
    RET