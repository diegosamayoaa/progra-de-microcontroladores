
/*
* main.asm
*
* Creado: 
* Autor : Diego Samayoa
* Descripción: PreLab2
*/
/****************************************/

.def cont   = r16 
.def aux        = r17
.def aux2       = r18
.def cont2 = r19
.def of      = r20
.def tmp        = r21
.def tick     = r22

.dseg
.org SRAM_START

.cseg
.org 0x0000
    rjmp RESET

RESET:
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

    clr r1
    clr cont
    clr cont2
    clr tick


    ldi aux, 0b11111100
    out DDRD, aux
    cbi PORTD, 2
    cbi PORTD, 3
    cbi PORTD, 4
    cbi PORTD, 5


    sbi DDRB, 5
    cbi PORTB, 5


    cbi DDRC, 0
    cbi DDRC, 1
    sbi PORTC, 0
    sbi PORTC, 1


    ldi aux, 0x00
    out TCCR0A, aux
    ldi aux, (1<<CS02)|(1<<CS00)
    out TCCR0B, aux

    rjmp MAIN_LOOP

MAIN_LOOP:

    rcall Tick100ms

    tst tmp
    breq NO_TICK

    inc cont
    andi cont, 0x0F
    rcall MostrarLEDs
NO_TICK:
    rcall AlarmaCheck
    rjmp MAIN_LOOP


Tick100ms:
    clr tmp
    tst tick
    brne T0_CHECK

    ldi of, 6
    ldi aux, 229
    out TCNT0, aux
    ldi aux, (1<<TOV0)
    out TIFR0, aux
    ldi tick, 1
    ret

T0_CHECK:
    in aux2, TIFR0
    sbrs aux2, TOV0
    ret


    ldi aux, (1<<TOV0)
    out TIFR0, aux
    clr aux
    out TCNT0, aux

    dec of
    brne T0_NOTYET

    clr tick
    ldi tmp, 1
    ret

T0_NOTYET:
    ret


MostrarLEDs:
    mov aux, cont
    andi aux, 0x0F
    lsl aux
    lsl aux
    in aux2, PORTD
    andi aux2, 0b11000011
    or aux2, aux
    out PORTD, aux2
    ret

AlarmaCheck:
    mov aux, cont
    andi aux, 0x0F
    mov aux2, cont2
    cp aux, aux2
    brne AlarmOff

AlarmOn:
    sbi PORTB, 5
    ret

AlarmOff:
    cbi PORTB, 5
    ret