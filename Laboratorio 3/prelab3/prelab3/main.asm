/*
* prelab3.asm
*
* Creado: 
* Autor : Diego Samayoa
* preguntas pre lab: 
* pregunta 1: El Program Counter guarda la dirección actual en la pila y luego salta a la dirección 
* de la rutina de interrupción. Cuando termina la interrupción, regresa a donde se había quedado.
* Pregunta 2:	PCICR: Habilita las interrupciones por cambio de estado en los pines (Pin Change Interrupt).
*				PCMSK0: Selecciona específicamente qué pines activarán esa interrupción.
*				TIMSK0: Activa las interrupciones del Timer0
* Pregunta 3:	CLI: Desactiva las interrupciones globales.
				SEI: Activa las interrupciones globales.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

.dseg
.org    SRAM_START
flag_inc:   .byte   1
flag_dec:   .byte   1

.cseg
.org 0x0000
    RJMP    RESET

; Vector de interrupción PCINT1 (cambios en PCINT[14:8] = PORTC)
.org 0x0008
    RJMP    INT_1

/****************************************/
// Configuración de la pila + setup general
RESET:
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:
    CLR     R1                  ; siempre debe ser 0 (buena practica)

    ;LEDs PB0-PB3 salidas
    LDI     R16, (1<<DDB0)|(1<<DDB1)|(1<<DDB2)|(1<<DDB3)
    OUT     DDRB, R16
    CLR     R17                 ; contador
    OUT     PORTB, R17          ; se muestra en las LEDS

    ;Botones PC0/PC1 entrada con pull-up 
    CBI     DDRC, DDC0
    CBI     DDRC, DDC1
    SBI     PORTC, PC0
    SBI     PORTC, PC1

    ; Flags en 0
    CLR     R16
    STS     flag_inc, R16
    STS     flag_dec, R16

    ; Timer0 normal / prescaler 64
    LDI     R16, 0x00
    OUT     TCCR0A, R16
    LDI     R16, (1<<CS01)|(1<<CS00)
    OUT     TCCR0B, R16
    LDI     R16, (1<<TOV0)
    OUT     TIFR0, R16          ; limpiar bandera overflow

    ;Habilitar interrupciones para PC0 y PC1
    LDI     R16, (1<<PCINT8)|(1<<PCINT9)
    STS     PCMSK1, R16

    LDI     R16, (1<<PCIF1)
    OUT     PCIFR, R16          ; limpiar bandera pin-change grupo 1

    LDI     R16, (1<<PCIE1)
    STS     PCICR, R16          ; habilitar grupo PCINT1

    SEI                         ; habilitar interrupciones globales

/****************************************/
// Loop Infinito
MAIN_LOOP:

    ;Revisar incremento
    LDS     R16, flag_inc
    TST     R16
    BREQ    CHECK_DEC
    CLR     R16
    STS     flag_inc, R16       ; limpiar bandera
    INC     R17                 ; incrementar contador
    ANDI    R17, 0x0F
    OUT     PORTB, R17          ; mostrar leds

    ; anti-rebote (esperar soltar PC0)
ESPERAR_SUELTA_INC:
    SBIS    PINC, PC0
    RJMP    ESPERAR_SUELTA_INC
    RCALL   DELAY_20MS
    SBIS    PINC, PC0
    RJMP    ESPERAR_SUELTA_INC

    LDI     R16, (1<<PCIF1)     ; limpiar bandera interrupcion 1
    OUT     PCIFR, R16
    LDI     R16, (1<<PCIE1)     ; volver a activar interrupciones grupo 1
    STS     PCICR, R16

CHECK_DEC:
    ;revisar decremento
    LDS     R16, flag_dec
    TST     R16
    BREQ    MAIN_LOOP
    CLR     R16
    STS     flag_dec, R16
    DEC     R17                 ; decrementar
    ANDI    R17, 0x0F
    OUT     PORTB, R17

    ; anti-rebote (esperar soltar PC1)
ESPERAR_SUELTA_DEC:
    SBIS    PINC, PC1
    RJMP    ESPERAR_SUELTA_DEC
    RCALL   DELAY_20MS
    SBIS    PINC, PC1
    RJMP    ESPERAR_SUELTA_DEC

    LDI     R16, (1<<PCIF1)
    OUT     PCIFR, R16
    LDI     R16, (1<<PCIE1)
    STS     PCICR, R16

    RJMP    MAIN_LOOP

/****************************************/
// Delay ~20ms usando Timer0 overflow 
DELAY_20MS:
    LDI     R20, 20             ; contador de 20 overflows
ESPERA_OVERFLOW_20MS:
    IN      R16, TIFR0
    SBRS    R16, TOV0
    RJMP    ESPERA_OVERFLOW_20MS
    LDI     R16, (1<<TOV0)
    OUT     TIFR0, R16          ; limpiar bandera timer
    DEC     R20
    BRNE    ESPERA_OVERFLOW_20MS
    RET

/****************************************/
// ISR PCINT1 (PORTC)
INT_1:
    PUSH    R16
    IN      R16, SREG
    PUSH    R16

    CLR     R16
    STS     PCICR, R16          ; Deshabilitar interrupciones temporalmente

    ;Si PC0 = 0 -> INC
    SBIC    PINC, PC0
    RJMP    VERIFICAR_DEC_ISR
    LDI     R16, 1
    STS     flag_inc, R16
    RJMP    FIN_ISR

VERIFICAR_DEC_ISR:
    ; Si PC1 = 0  DEC
    SBIC    PINC, PC1
    RJMP    FIN_ISR
    LDI     R16, 1
    STS     flag_dec, R16

FIN_ISR:
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI
