/*
* main.asm
*
* Creado: 3/3/26
* Autor : Diego Samayoa
* Descripción: Reloj digital
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

// variables para el reloj
t_1s: .byte 1	// flag al llegar a 1s

// variables para blink por software con Timer0
blinkL:     .byte 1     // low byte contador para 500ms
blinkH:     .byte 1     // high byte contador para 500ms
blink_500:  .byte 1     // toggle cada 500ms
halfsec:    .byte 1     // cuenta dos medios segundos para formar 1s

// variable para antirebote por software
debounce_lock: .byte 1

// variable para guardar ultimo estado de botones
boton_last: .byte 1

// digitos del reloj
seg:            .byte 1
min_uni:        .byte 1
min_dec:        .byte 1
hora_uni:       .byte 1
hora_dec:       .byte 1

// digitos de la fecha
dia_uni:        .byte 1
dia_dec:        .byte 1
mes_uni:        .byte 1
mes_dec:        .byte 1

// digitos de la alarma
alarm_min_uni:  .byte 1
alarm_min_dec:  .byte 1
alarm_hora_uni: .byte 1
alarm_hora_dec: .byte 1
alarm_on:       .byte 1

// indica que digito del display esta seleccionado
digito:    .byte 1

//botones y modo
boton:  .byte 1
mode:   .byte 1   ; 0=hora 1=dia 2=alarma

// configuracion
config_mode:    .byte 1   ; 0=normal 1=configurando
edit_pos:       .byte 1   ; 0=no edita 1..4 digito que se edita

.cseg
.org 0x0000
	RJMP START

.org	PCI0addr // Interrupcion de pinchange para el puerto B
	RJMP		PINB_ISR

.org	OC0Aaddr// interrupcion timer 0 compare match A
	RJMP		TIMER0_ISR


table_S7:
.DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F

 /****************************************/
 START:
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:
CLI

	// salidas para el display y led de fecha
ldi r16, 0b11111111
out DDRD, r16
clr r16
out PORTD,r16

	// salidas para digitos del display C1-C5
LDI R16,0b00111110
OUT DDRC,R16
CLR R16
OUT PORTC,R16

	//Leds para señalar y buzzer
ldi r16, 0b00110000
out DDRB, r16	
	
	// botones pb0-pb3
ldi r16, 0x0F
out PORTB, r16

	//activar PCINT
LDI R16,(1<<PCIE0)
STS PCICR,R16
LDI R16,0b00001111
STS PCMSK0,R16

	//Limpiar RAM
clr r1
clr r16

STS t_1s,R16

STS blinkL,R16
STS blinkH,R16
STS blink_500,R16
STS halfsec,R16

STS debounce_lock,R16
STS boton_last,R16

STS seg,R16

STS min_uni,R16
STS min_dec,R16
STS hora_uni,R16
STS hora_dec,R16

STS dia_dec,R16
LDI R16, 1
STS dia_uni,R16
CLR R16
STS mes_dec,R16
LDI R16, 1
STS mes_uni,R16

LDI R16, 9
STS alarm_min_uni, R16
LDI R16, 5
STS alarm_min_dec, R16
LDI R16, 3
STS alarm_hora_uni, R16
LDI R16, 2
STS alarm_hora_dec, R16
CLR R16
STS alarm_on, R16

STS digito, R16
STS boton, R16
STS mode, R16
STS config_mode, R16
STS edit_pos, R16

	// guardar estado inicial de botones
in r16, PINB
com r16
andi r16, 0x0F
sts boton_last, r16

	// Configurar timer 0 para que cuente 1ms
LDI R16,(1<<WGM01)
OUT TCCR0A,R16				
LDI R16,(1<<CS01)|(1<<CS00)
OUT TCCR0B,R16
LDI R16,249
OUT OCR0A,R16
LDI R16,(1<<OCIE0A)
STS TIMSK0,R16

RCALL actualizar_leds_modo

SEI
    
/****************************************/
// Loop Infinito
MAIN_LOOP:
	// revisamos botones para modo
	LDS R16,boton
	CPI R16,0
	BREQ check_clk
	
	// si la alarma esta activa, cualquier boton la apaga
    LDS R17, alarm_on
    CPI R17, 0
    BREQ procesar_botones

	CLR R17
    STS alarm_on, R17
    CBI PORTB, 5

procesar_botones:
	
	// B0 modo configuracion / siguiente digito
    SBRC R16, 0
    RCALL boton_config

    // B1 cambiar modo mostrado 
    SBRC R16, 1
    RCALL boton_modo

    // B2 incremento
    SBRC R16, 2
    RCALL boton_inc

    // B3 decremento
    SBRC R16, 3
    RCALL boton_dec

limpiar_bot:
    CLR R16
    STS boton,R16

check_clk:
    LDS R16,t_1s
    CPI R16,0
    BREQ MAIN_LOOP

    CLR R16
    STS t_1s,R16

    // solo actualizar reloj cuando no se esta configurando
    LDS R17,edit_pos
    CPI R17,0
    BREQ seguir_update
    RJMP MAIN_LOOP

seguir_update:
    RCALL actualizar_clk
	RCALL revisar_alarma

    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

actualizar_leds_modo:
	//Rutina que se va a utilizar para actualizar los leds al modo actual
	PUSH R16
    IN   R16, SREG
    PUSH R16

    // apagar ambos leds
    CBI PORTB,4
    CBI PORTD,7

    LDS R16,mode
    CPI R16,0
    BREQ led_hora
    CPI R16,1
    BREQ led_fecha

    // modo alarma (ambos leds encendidos)
    SBI PORTB,4
    SBI PORTD,7
    RJMP fin_leds

led_hora:
    SBI PORTB,4
    RJMP fin_leds

led_fecha:
    SBI PORTD,7

fin_leds:
    POP R16
    OUT SREG,R16
    POP R16
    RET

//Rutina para cambiar modos
cambio_modo:
    LDS R16,mode
    INC R16
    CPI R16,3
    BRLO guardar_modo
    CLR R16
guardar_modo:
    STS mode,R16
    RCALL actualizar_leds_modo
    RET

// B0: entra a configuracion
boton_config:
    LDS R16, edit_pos
    INC R16
    CPI R16,5
    BRLO guardar_edit

    // ya paso del ultimo digito, salir de configuracion
    CLR R16

guardar_edit:
    STS edit_pos, R16

    // actualizar flag de configuracion
    CPI R16,0
    BREQ salir_config

    LDI R17,1
    STS config_mode,R17
    RJMP reset_blink_conf

salir_config:
    CLR R17
    STS config_mode,R17

reset_blink_conf:
    // reiniciar multiplexado y blink para que se note de inmediato
    LDI R17,3
    STS digito,R17

    CLR R17
    STS blinkL,R17
    STS blinkH,R17
    STS blink_500,R17
    RET

// B1: cambia modo solo cuando no esta en modo de configuracion
boton_modo:
    LDS R16, edit_pos
    CPI R16, 0
    BRNE fin_boton_modo
    RCALL cambio_modo
fin_boton_modo:
    RET

// B2: incrementa digito seleccionado
boton_inc:
    LDS R16, edit_pos
    CPI R16, 0
    BREQ fin_boton_inc

    LDS R16, mode
    CPI R16, 0
    BRNE boton_inc_chk1
    RJMP inc_hora

//Esto es necesario porque la subrutina a la que nos referimos esta muy lejos
boton_inc_chk1:
    CPI R16, 1
    BRNE boton_inc_chk2
    RJMP inc_fecha

boton_inc_chk2:
    RJMP inc_alarma

fin_boton_inc:
    RET

// B3: decrementa digito seleccionado
boton_dec:
    LDS R16, edit_pos
    CPI R16, 0
    BREQ fin_boton_dec

    LDS R16, mode
    CPI R16, 0
    BRNE boton_dec_chk1
    RJMP dec_hora

//Esto es necesario porque la subrutina a la que nos referimos esta muy lejos
boton_dec_chk1:
    CPI R16, 1
    BRNE boton_dec_chk2
    RJMP dec_fecha

boton_dec_chk2:
    RJMP dec_alarma

fin_boton_dec:
    RET


//Incremento de hora actual
inc_hora:
    LDS R16, edit_pos
    CPI R16,1
    BREQ inc_hora_dec
    CPI R16,2
    BREQ inc_hora_uni
    CPI R16,3
    BREQ inc_min_dec
    CPI R16,4
    BREQ inc_min_uni
    RET
//Colocamos limite para decenas de hora
inc_hora_dec:
    LDS R16,hora_dec
    INC R16
    CPI R16,3
    BRLO save_inc_hora_dec
    CLR R16
save_inc_hora_dec:
    STS hora_dec,R16
    RCALL ajustar_hora_actual
    RET
// colocamos limite para cada digito de hora
inc_hora_uni:
    LDS R16,hora_dec
    CPI R16,2
    BRNE inc_hora_uni_normal

    LDS R16,hora_uni
    INC R16
    CPI R16,4
    BRLO save_inc_hora_uni_24
    CLR R16
save_inc_hora_uni_24:
    STS hora_uni,R16
    RET

inc_hora_uni_normal:
    LDS R16,hora_uni
    INC R16
    CPI R16,10
    BRLO save_inc_hora_uni
    CLR R16
save_inc_hora_uni:
    STS hora_uni,R16
    RET

inc_min_dec:
    LDS R16,min_dec
    INC R16
    CPI R16,6
    BRLO save_inc_min_dec
    CLR R16
save_inc_min_dec:
    STS min_dec,R16
    RET

inc_min_uni:
    LDS R16,min_uni
    INC R16
    CPI R16,10
    BRLO save_inc_min_uni
    CLR R16
save_inc_min_uni:
    STS min_uni,R16
    RET

//Decremento de hora actual
dec_hora:
    LDS R16, edit_pos
    CPI R16,1
    BREQ dec_hora_dec
    CPI R16,2
    BREQ dec_hora_uni
    CPI R16,3
    BREQ dec_min_dec
    CPI R16,4
    BREQ dec_min_uni
    RET

dec_hora_dec:
    LDS R16,hora_dec
    CPI R16,0
    BRNE dec_hora_dec_normal
    LDI R16,2
    RJMP save_dec_hora_dec

dec_hora_dec_normal:
    DEC R16

save_dec_hora_dec:
    STS hora_dec,R16
    RCALL ajustar_hora_actual
    RET

dec_hora_uni:
    LDS R16,hora_dec
    CPI R16,2
    BRNE dec_hora_uni_normal

    LDS R16,hora_uni
    CPI R16,0
    BRNE dec_hora_uni_24
    LDI R16,3
    RJMP save_dec_hora_uni_24

dec_hora_uni_24:
    DEC R16

save_dec_hora_uni_24:
    STS hora_uni,R16
    RET

dec_hora_uni_normal:
    LDS R16,hora_uni
    CPI R16,0
    BRNE dec_hora_uni_norm2
    LDI R16,9
    RJMP save_dec_hora_uni

dec_hora_uni_norm2:
    DEC R16

save_dec_hora_uni:
    STS hora_uni,R16
    RET

dec_min_dec:
    LDS R16,min_dec
    CPI R16,0
    BRNE dec_min_dec_normal
    LDI R16,5
    RJMP save_dec_min_dec

dec_min_dec_normal:
    DEC R16

save_dec_min_dec:
    STS min_dec,R16
    RET

dec_min_uni:
    LDS R16,min_uni
    CPI R16,0
    BRNE dec_min_uni_normal
    LDI R16,9
    RJMP save_dec_min_uni

dec_min_uni_normal:
    DEC R16

save_dec_min_uni:
    STS min_uni,R16
    RET

// ajusta limite de hora para formato 24hrs
ajustar_hora_actual:
    LDS R16,hora_dec
    CPI R16,2
    BRNE fin_ajustar_hora_actual
    LDS R16,hora_uni
    CPI R16,4
    BRLO fin_ajustar_hora_actual
    LDI R16,3
    STS hora_uni,R16

fin_ajustar_hora_actual:
    RET

//Incremento de fecha actual
inc_fecha:
    LDS R16, edit_pos
    CPI R16,1
    BREQ inc_dia_dec
    CPI R16,2
    BREQ inc_dia_uni
    CPI R16,3
    BREQ inc_mes_dec
    CPI R16,4
    BREQ inc_mes_uni
    RET

inc_dia_dec:
    LDS R16,dia_dec
    INC R16
    CPI R16,4
    BRLO save_inc_dia_dec
    CLR R16

save_inc_dia_dec:
    STS dia_dec,R16
    RCALL normalizar_fecha_inc
    RET

inc_dia_uni:
    LDS R16,dia_uni
    INC R16
    CPI R16,10
    BRLO save_inc_dia_uni
    CLR R16

save_inc_dia_uni:
    STS dia_uni,R16
    RCALL normalizar_fecha_inc
    RET

inc_mes_dec:
    LDS R16,mes_dec
    INC R16
    CPI R16,2
    BRLO save_inc_mes_dec
    CLR R16

save_inc_mes_dec:
    STS mes_dec,R16
    RCALL normalizar_fecha_inc
    RET

inc_mes_uni:
    LDS R16,mes_uni
    INC R16
    CPI R16,10
    BRLO save_inc_mes_uni
    CLR R16

save_inc_mes_uni:
    STS mes_uni,R16
    RCALL normalizar_fecha_inc
    RET

//Decremento de fecha actual
dec_fecha:
    LDS R16, edit_pos
    CPI R16,1
    BREQ dec_dia_dec
    CPI R16,2
    BREQ dec_dia_uni
    CPI R16,3
    BREQ dec_mes_dec
    CPI R16,4
    BREQ dec_mes_uni
    RET

dec_dia_dec:
    LDS R16,dia_dec
    CPI R16,0
    BRNE dec_dia_dec_normal
    LDI R16,3
    RJMP save_dec_dia_dec

dec_dia_dec_normal:
    DEC R16

save_dec_dia_dec:
    STS dia_dec,R16
    RCALL normalizar_fecha_dec
    RET

dec_dia_uni:
    LDS R16,dia_uni
    CPI R16,0
    BRNE dec_dia_uni_normal
    LDI R16,9
    RJMP save_dec_dia_uni

dec_dia_uni_normal:
    DEC R16

save_dec_dia_uni:
    STS dia_uni,R16
    RCALL normalizar_fecha_dec
    RET

dec_mes_dec:
    LDS R16,mes_dec
    CPI R16,0
    BRNE dec_mes_dec_normal
    LDI R16,1
    RJMP save_dec_mes_dec

dec_mes_dec_normal:
    DEC R16

save_dec_mes_dec:
    STS mes_dec,R16
    RCALL normalizar_fecha_dec
    RET

dec_mes_uni:
    LDS R16,mes_uni
    CPI R16,0
    BRNE dec_mes_uni_normal
    LDI R16,9
    RJMP save_dec_mes_uni

dec_mes_uni_normal:
    DEC R16

save_dec_mes_uni:
    STS mes_uni,R16
    RCALL normalizar_fecha_dec
    RET

//Incremento en alarma
inc_alarma:
    LDS R16, edit_pos
    CPI R16,1
    BREQ inc_alarm_hora_dec
    CPI R16,2
    BREQ inc_alarm_hora_uni
    CPI R16,3
    BREQ inc_alarm_min_dec
    CPI R16,4
    BREQ inc_alarm_min_uni
    RET

inc_alarm_hora_dec:
    LDS R16,alarm_hora_dec
    INC R16
    CPI R16,3
    BRLO save_inc_alarm_hora_dec
    CLR R16
save_inc_alarm_hora_dec:
    STS alarm_hora_dec,R16
    RCALL ajustar_hora_alarma
    RET

inc_alarm_hora_uni:
    LDS R16,alarm_hora_dec
    CPI R16,2
    BRNE inc_alarm_hora_uni_normal

    LDS R16,alarm_hora_uni
    INC R16
    CPI R16,4
    BRLO save_inc_alarm_hora_uni_24
    CLR R16
save_inc_alarm_hora_uni_24:
    STS alarm_hora_uni,R16
    RET

inc_alarm_hora_uni_normal:
    LDS R16,alarm_hora_uni
    INC R16
    CPI R16,10
    BRLO save_inc_alarm_hora_uni
    CLR R16
save_inc_alarm_hora_uni:
    STS alarm_hora_uni,R16
    RET

inc_alarm_min_dec:
    LDS R16,alarm_min_dec
    INC R16
    CPI R16,6
    BRLO save_inc_alarm_min_dec
    CLR R16
save_inc_alarm_min_dec:
    STS alarm_min_dec,R16
    RET

inc_alarm_min_uni:
    LDS R16,alarm_min_uni
    INC R16
    CPI R16,10
    BRLO save_inc_alarm_min_uni
    CLR R16
save_inc_alarm_min_uni:
    STS alarm_min_uni,R16
    RET

//Decremento en alarma
dec_alarma:
    LDS R16, edit_pos
    CPI R16,1
    BREQ dec_alarm_hora_dec
    CPI R16,2
    BREQ dec_alarm_hora_uni
    CPI R16,3
    BREQ dec_alarm_min_dec
    CPI R16,4
    BREQ dec_alarm_min_uni
    RET

dec_alarm_hora_dec:
    LDS R16,alarm_hora_dec
    CPI R16,0
    BRNE dec_alarm_hora_dec_normal
    LDI R16,2
    RJMP save_dec_alarm_hora_dec

dec_alarm_hora_dec_normal:
    DEC R16

save_dec_alarm_hora_dec:
    STS alarm_hora_dec,R16
    RCALL ajustar_hora_alarma
    RET

dec_alarm_hora_uni:
    LDS R16,alarm_hora_dec
    CPI R16,2
    BRNE dec_alarm_hora_uni_normal

    LDS R16,alarm_hora_uni
    CPI R16,0
    BRNE dec_alarm_hora_uni_24
    LDI R16,3
    RJMP save_dec_alarm_hora_uni_24

dec_alarm_hora_uni_24:
    DEC R16

save_dec_alarm_hora_uni_24:
    STS alarm_hora_uni,R16
    RET

dec_alarm_hora_uni_normal:
    LDS R16,alarm_hora_uni
    CPI R16,0
    BRNE dec_alarm_hora_uni_norm2
    LDI R16,9
    RJMP save_dec_alarm_hora_uni

dec_alarm_hora_uni_norm2:
    DEC R16

save_dec_alarm_hora_uni:
    STS alarm_hora_uni,R16
    RET

dec_alarm_min_dec:
    LDS R16,alarm_min_dec
    CPI R16,0
    BRNE dec_alarm_min_dec_normal
    LDI R16,5
    RJMP save_dec_alarm_min_dec

dec_alarm_min_dec_normal:
    DEC R16

save_dec_alarm_min_dec:
    STS alarm_min_dec,R16
    RET

dec_alarm_min_uni:
    LDS R16,alarm_min_uni
    CPI R16,0
    BRNE dec_alarm_min_uni_normal
    LDI R16,9
    RJMP save_dec_alarm_min_uni

dec_alarm_min_uni_normal:
    DEC R16

save_dec_alarm_min_uni:
    STS alarm_min_uni,R16
    RET

// ajusta limite 
ajustar_hora_alarma:
    LDS R16,alarm_hora_dec
    CPI R16,2
    BRNE fin_ajustar_hora_alarma
    LDS R16,alarm_hora_uni
    CPI R16,4
    BRLO fin_ajustar_hora_alarma
    LDI R16,3
    STS alarm_hora_uni,R16

fin_ajustar_hora_alarma:
    RET

// Over y underflow al incrementar fecha
normalizar_fecha_inc:
    RCALL validar_mes_inc
    RCALL validar_dia_inc
    RET

// validacion de fecha al decrementar
normalizar_fecha_dec:
    RCALL validar_mes_dec
    RCALL validar_dia_dec
    RET

// si el mes es mayor a 12 al incrementar, pasa a 01
validar_mes_inc:
    LDS R16,mes_dec
    LDS R17,mes_uni

    CPI R16,0
    BREQ revisar_mes_inc_0
    CPI R16,1
    BREQ revisar_mes_inc_1
    RJMP set_mes_01

revisar_mes_inc_0:
    CPI R17,0
    BREQ set_mes_01
    RET

revisar_mes_inc_1:
    CPI R17,3
    BRSH set_mes_01
    RET

set_mes_01:
    CLR R16
    LDI R17,1
    STS mes_dec,R16
    STS mes_uni,R17
    RET

// si el mes es menor a 1 al decrementar, pasa a 12
validar_mes_dec:
    LDS R16,mes_dec
    LDS R17,mes_uni

    CPI R16,0
    BREQ revisar_mes_dec_0
    CPI R16,1
    BREQ revisar_mes_dec_1
    RJMP set_mes_12

revisar_mes_dec_0:
    CPI R17,0
    BREQ set_mes_12
    RET

revisar_mes_dec_1:
    CPI R17,3
    BRSH set_mes_12
    RET

set_mes_12:
    LDI R16,1
    LDI R17,2
    STS mes_dec,R16
    STS mes_uni,R17
    RET

// si el dia queda invalido al incrementar (dependiendo del mes), pasa a 01
validar_dia_inc:
    LDS R16,dia_dec
    LDS R17,dia_uni

    CPI R16,0
    BRNE tipo_mes_inc
    CPI R17,0
    BREQ set_dia_01

tipo_mes_inc:
    RCALL obtener_tipo_mes
    CPI R16,28
    BREQ validar_feb_inc
    CPI R16,30
    BREQ validar_30_inc
    RJMP validar_31_inc

validar_feb_inc:
    LDS R17,dia_dec
    CPI R17,3
    BRSH set_dia_01
    CPI R17,2
    BRNE fin_validar_dia_inc
    LDS R17,dia_uni
    CPI R17,9
    BRSH set_dia_01
    RJMP fin_validar_dia_inc

validar_30_inc:
    LDS R17,dia_dec
    CPI R17,4
    BRSH set_dia_01
    CPI R17,3
    BRNE fin_validar_dia_inc
    LDS R17,dia_uni
    CPI R17,1
    BRSH set_dia_01
    RJMP fin_validar_dia_inc

validar_31_inc:
    LDS R17,dia_dec
    CPI R17,4
    BRSH set_dia_01
    CPI R17,3
    BRNE fin_validar_dia_inc
    LDS R17,dia_uni
    CPI R17,2
    BRSH set_dia_01
    RJMP fin_validar_dia_inc

set_dia_01:
    CLR R17
    STS dia_dec,R17
    LDI R17,1
    STS dia_uni,R17

fin_validar_dia_inc:
    RET

// si el dia queda invalido al decrementar, pasa al maximo del mes
validar_dia_dec:
    LDS R16,dia_dec
    LDS R17,dia_uni

    CPI R16,0
    BRNE tipo_mes_dec
    CPI R17,0
    BREQ poner_dia_max

tipo_mes_dec:
    RCALL obtener_tipo_mes
    CPI R16,28
    BREQ validar_feb_dec
    CPI R16,30
    BREQ validar_30_dec
    RJMP validar_31_dec

validar_feb_dec:
    LDS R17,dia_dec
    CPI R17,3
    BRSH poner_dia_max
    CPI R17,2
    BRNE fin_validar_dia_dec
    LDS R17,dia_uni
    CPI R17,9
    BRSH poner_dia_max
    RJMP fin_validar_dia_dec

validar_30_dec:
    LDS R17,dia_dec
    CPI R17,4
    BRSH poner_dia_max
    CPI R17,3
    BRNE fin_validar_dia_dec
    LDS R17,dia_uni
    CPI R17,1
    BRSH poner_dia_max
    RJMP fin_validar_dia_dec

validar_31_dec:
    LDS R17,dia_dec
    CPI R17,4
    BRSH poner_dia_max
    CPI R17,3
    BRNE fin_validar_dia_dec
    LDS R17,dia_uni
    CPI R17,2
    BRSH poner_dia_max
    RJMP fin_validar_dia_dec

poner_dia_max:
    RCALL obtener_tipo_mes
    CPI R16,28
    BREQ set_28
    CPI R16,30
    BREQ set_30
    RJMP set_31

set_28:
    LDI R17,2
    STS dia_dec,R17
    LDI R17,8
    STS dia_uni,R17
    RET

set_30:
    LDI R17,3
    STS dia_dec,R17
    CLR R17
    STS dia_uni,R17
    RET

set_31:
    LDI R17,3
    STS dia_dec,R17
    LDI R17,1
    STS dia_uni,R17
    RET

fin_validar_dia_dec:
    RET

// devuelve en un registro el maximo del mes: 28,30,31
obtener_tipo_mes:
    LDS R17,mes_dec
    CPI R17,0
    BREQ mes_grupo_0

    // meses 10,11,12
    LDS R17,mes_uni
    CPI R17,1
    BREQ mes_30
    LDI R16,31
    RET

mes_grupo_0:
    LDS R17,mes_uni
    CPI R17,2
    BREQ mes_28
    CPI R17,4
    BREQ mes_30
    CPI R17,6
    BREQ mes_30
    CPI R17,9
    BREQ mes_30
    LDI R16,31
    RET

mes_28:
    LDI R16,28
    RET

mes_30:
    LDI R16,30
    RET

//Cargar lo deseado al display
mostrar_DH:
    LDS R16,mode
    CPI R16,0
    BREQ hora_DH
    CPI R16,1
    BREQ fecha_DH
    RJMP alarma_DH

hora_DH:
    LDS R16,hora_dec
    RJMP mostrar_SEG

fecha_DH:
    LDS R16,dia_dec
    RJMP mostrar_SEG

alarma_DH:
    LDS R16,alarm_hora_dec
    RJMP mostrar_SEG

mostrar_UH:
    LDS R16,mode
    CPI R16,0
    BREQ hora_UH
    CPI R16,1
    BREQ fecha_UH
    RJMP alarma_UH

hora_UH:
    LDS R16,hora_uni
    RJMP mostrar_SEG

fecha_UH:
    LDS R16,dia_uni
    RJMP mostrar_SEG

alarma_UH:
    LDS R16,alarm_hora_uni
    RJMP mostrar_SEG

mostrar_DM:
    LDS R16,mode
    CPI R16,0
    BREQ hora_DM
    CPI R16,1
    BREQ fecha_DM
    RJMP alarma_DM

hora_DM:
    LDS R16,min_dec
    RJMP mostrar_SEG

fecha_DM:
    LDS R16,mes_dec
    RJMP mostrar_SEG

alarma_DM:
    LDS R16,alarm_min_dec
    RJMP mostrar_SEG

mostrar_UM:
    LDS R16,mode
    CPI R16,0
    BREQ hora_UM
    CPI R16,1
    BREQ fecha_UM
    RJMP alarma_UM

hora_UM:
    LDS R16,min_uni
    RJMP mostrar_SEG

fecha_UM:
    LDS R16,mes_uni
    RJMP mostrar_SEG

alarma_UM:
    LDS R16,alarm_min_uni

mostrar_SEG:
    RCALL SEG7
    RET

//Reloj

//cargar segundos actuales
actualizar_clk:
    LDS R16,seg
    INC R16
    CPI R16,60
    BRLO guardar_sec
    CLR R16

guardar_sec:
    STS seg,R16
    CPI R16,0
    BRNE done_UPDATE
//incrementar unidades de minutos
    LDS R16,min_uni
    INC R16
    CPI R16,10
    BRLO guardar_MU
    CLR R16

guardar_MU:
    STS min_uni,R16
    CPI R16,0
    BRNE done_UPDATE
// incrementar unidades de decena
    LDS R16,min_dec
    INC R16
    CPI R16,6
    BRLO guardar_MD
    CLR R16

guardar_MD:
    STS min_dec,R16
    CPI R16,0
    BRNE done_UPDATE
//incrementar unidades de horas
    LDS R16,hora_uni
    INC R16
    CPI R16,10
    BRLO guardar_HU
    CLR R16

guardar_HU:
    STS hora_uni,R16
    CPI R16,0
    BRNE revisar_24
//incrementar decenas de horas
    LDS R16,hora_dec
    INC R16
    CPI R16,3
    BRLO guardar_HD
    CLR R16

guardar_HD:
    STS hora_dec,R16
//verificar si ya llego a 24:00
revisar_24:
    LDS R16,hora_dec
    CPI R16,2
    BRNE done_UPDATE
    LDS R16,hora_uni
    CPI R16,4
    BRNE done_UPDATE
//reiniciar a 00:00 al llegar
    CLR R16
    STS hora_dec,R16
    STS hora_uni,R16
    RCALL incrementar_fecha

done_UPDATE:
    RET

// incremento de dia cuando el clock pasa de 23:59 a 00:00
incrementar_fecha:
    LDS R16,dia_uni
    INC R16
    CPI R16,10
    BRLO guardar_dia_uni_auto

    CLR R16
    STS dia_uni,R16
    LDS R16,dia_dec
    INC R16
    STS dia_dec,R16
    RJMP revisar_fecha_auto

guardar_dia_uni_auto:
    STS dia_uni,R16

revisar_fecha_auto:
    RCALL obtener_tipo_mes
    CPI R16,28
    BREQ revisar_feb_auto
    CPI R16,30
    BREQ revisar_30_auto
    RJMP revisar_31_auto

revisar_feb_auto:
    LDS R17,dia_dec
    CPI R17,2
    BRLO fin_fecha_auto
    BRNE reset_dia_mes_auto
    LDS R17,dia_uni
    CPI R17,9
    BRSH reset_dia_mes_auto
    RET

revisar_30_auto:
    LDS R17,dia_dec
    CPI R17,3
    BRLO fin_fecha_auto
    BRNE reset_dia_mes_auto
    LDS R17,dia_uni
    CPI R17,1
    BRSH reset_dia_mes_auto
    RET

revisar_31_auto:
    LDS R17,dia_dec
    CPI R17,3
    BRLO fin_fecha_auto
    BRNE reset_dia_mes_auto
    LDS R17,dia_uni
    CPI R17,2
    BRSH reset_dia_mes_auto
    RET

reset_dia_mes_auto:
    CLR R17
    STS dia_dec,R17
    LDI R17,1
    STS dia_uni,R17

    LDS R17,mes_uni
    INC R17
    CPI R17,10
    BRLO guardar_mes_uni_auto

    CLR R17
    STS mes_uni,R17
    LDS R17,mes_dec
    INC R17
    STS mes_dec,R17
    RJMP revisar_mes_auto

guardar_mes_uni_auto:
    STS mes_uni,R17

revisar_mes_auto:
    LDS R17,mes_dec
    CPI R17,1
    BRNE fin_fecha_auto
    LDS R17,mes_uni
    CPI R17,3
    BRLO fin_fecha_auto

    // si pasa de 12 el mes, volver a 01
    CLR R17
    STS mes_dec,R17
    LDI R17,1
    STS mes_uni,R17

fin_fecha_auto:
    RET

// compara la hora actual con la alarma
revisar_alarma:
    LDS R16,seg
    CPI R16,0
    BRNE fin_revisar_alarma

    LDS R16,hora_dec
    LDS R17,alarm_hora_dec
    CP R16,R17
    BRNE fin_revisar_alarma

    LDS R16,hora_uni
    LDS R17,alarm_hora_uni
    CP R16,R17
    BRNE fin_revisar_alarma

    LDS R16,min_dec
    LDS R17,alarm_min_dec
    CP R16,R17
    BRNE fin_revisar_alarma

    LDS R16,min_uni
    LDS R17,alarm_min_uni
    CP R16,R17
    BRNE fin_revisar_alarma

    LDI R16,1
    STS alarm_on,R16
    SBI PORTB,5

fin_revisar_alarma:
    RET

/****************************************/
// Interrupt routines
PINB_ISR:
    PUSH R16
    IN R16,SREG
    PUSH R16

    IN R16,PINB
    COM R16
    ANDI R16,0b00001111
    STS boton,R16

    POP R16
    OUT SREG,R16
    POP R16
    RETI


TIMER0_ISR:
	
	PUSH R16
	PUSH R17
	IN R17,SREG
	PUSH R17

	//empezamos con todos los digitos apagados
	CBI PORTC,2
	CBI PORTC,3
	CBI PORTC,4
	CBI PORTC,5

    // manejar DP a 500ms
    LDS R16,blink_500
    CPI R16,0
    BREQ dp_off
    SBI PORTC,1
    RJMP seguir_mux

dp_off:
    CBI PORTC,1

seguir_mux:

	LDS R16,digito

	CPI R16,0
	BREQ show_decH
	CPI R16,1
	BREQ show_uniH
	CPI R16,2
	BREQ show_decM
	RJMP show_uniM

	// mostramos el digito que deseamos
    // PC5 = digito1
    // PC4 = digito2
    // PC3 = digito3
    // PC2 = digito4

// mostrar decena de hora en display
show_decH:
    RCALL mostrar_DH
    LDS R17,edit_pos
    CPI R17,1
    BRNE en_d1
    LDS R17,blink_500
    CPI R17,1
    BREQ limpiar_d1
en_d1:
    SBI PORTC,5
    RJMP siguiente_dig

limpiar_d1:
    RCALL limpiar_segmentos
    RJMP siguiente_dig
// mostrar unidad de hora en display
show_uniH:
    RCALL mostrar_UH
    LDS R17,edit_pos
    CPI R17,2
    BRNE en_d2
    LDS R17,blink_500
    CPI R17,1
    BREQ limpiar_d2
en_d2:
    SBI PORTC,4
    RJMP siguiente_dig

limpiar_d2:
    RCALL limpiar_segmentos
    RJMP siguiente_dig
// mostrar decena de minutos en display
show_decM:
    RCALL mostrar_DM
    LDS R17,edit_pos
    CPI R17,3
    BRNE en_d3
    LDS R17,blink_500
    CPI R17,1
    BREQ limpiar_d3
en_d3:
    SBI PORTC,3
    RJMP siguiente_dig

limpiar_d3:
    RCALL limpiar_segmentos
    RJMP siguiente_dig
// mostrar unidades de minutos en display
show_uniM:
    RCALL mostrar_UM
    LDS R17,edit_pos
    CPI R17,4
    BRNE en_d4
    LDS R17,blink_500
    CPI R17,1
    BREQ limpiar_d4
en_d4:
    SBI PORTC,2
    RJMP siguiente_dig

limpiar_d4:
    RCALL limpiar_segmentos

	// logica para mostrar siguiente digito
siguiente_dig:
    LDS R16,digito
    INC R16
    CPI R16,4
    BRLO current_dig
    CLR R16
current_dig:
    STS digito,R16

    // contador para 500ms
    LDS R16,blinkL
    INC R16
    STS blinkL,R16
    BRNE revisar_blink_alto

    LDS R16,blinkH
    INC R16
    STS blinkH,R16

revisar_blink_alto:
    LDS R16,blinkH
    CPI R16,1
    BRNE done_ISR

    LDS R16,blinkL
    CPI R16,244
    BRNE done_ISR

    // reiniciar 500ms
    CLR R16
    STS blinkL,R16
    STS blinkH,R16

    // toggle blink_500
    LDS R16,blink_500
    LDI R17,1
    EOR R16,R17
    STS blink_500,R16

    // 2 medios segundos = 1 segundo
    LDS R16,halfsec
    INC R16
    CPI R16,2
    BRLO guardar_halfsec

    CLR R16
    STS halfsec,R16
    LDI R16,1
    STS t_1s,R16
    RJMP done_ISR

guardar_halfsec:
    STS halfsec,R16

done_ISR:
    POP R17
    OUT SREG,R17
    POP R17
    POP R16

	RETI

// limpiar segmentos sin perder PD7
limpiar_segmentos:
    PUSH R16
    IN R16,PORTD
    ANDI R16,0b10000000
    OUT PORTD,R16
    POP R16
    RET

/****************************************/

SEG7:
    PUSH ZL
    PUSH ZH
    PUSH R17

    LDI ZH,HIGH(Table_S7*2)
    LDI ZL,LOW(Table_S7*2)
    ADD ZL,R16
    ADC ZH,R1
    LPM R16,Z

	 // preservar PD7 para el led de fecha
    IN R17,PORTD
    ANDI R17,0b10000000
    OR R16,R17
    OUT PORTD,R16

    POP R17
    POP ZH
    POP ZL
    RET