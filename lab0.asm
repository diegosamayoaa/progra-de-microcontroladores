;
; AssemblerApplication1.asm
;
; Created: 1/20/2026 2:45:35 PM
; Author : diego
;


.include "M328PDEF.inc"
.org 0x00

rjmp START; Indica que el programa se diriga a la parte inicial.

start:
    LDI R16, 0b00000100; Cargo un valor en el registro
	OUT DDRD, R16; Cargo el valor mencionado anteriormente para indicar que el bit 2 del puerto D es una salida.
	LDI R16, 0b00000000;
	OUT PORTD, R16;Preparo 
	rjmp loop;
loop:
	LDI R16, 0b00000100;Cargo un valor en el registro
	OUT PORTD, R16;
	rcall delay;
	LDI R16, 0b00000000;
	OUT PORTD, R16;
	rcall delay; 
	rjmp loop;

delay:
	LDI R17, 50;
retardo1:	
	LDI R18, 0b11111111;
retardo2:
	LDI R19, 0b11111111;
proceso:
	DEC R19;
	BRNE proceso;
	dec R18;
	BRNE retardo2;
	dec R17
	BRNE retardo1;
	RET;




