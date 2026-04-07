/*
 * main.c
 *
 * Created: 
 * Author: Diego
 * Description: contador con timer 0 a 500ms
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <stdint.h>
#include <avr/interrupt.h>

#define TCNT0_value 100
uint8_t counter =0;
/****************************************/
// Function prototypes
void setup();
void initTMR0();
/****************************************/
// Main Function
int main(void)
{
    cli();
	setup();
	//Habilitar interrupcion por overflow
	TIMSK0	|= (1<<TOIE0);
	sei();
    while (1) 
    {
    }
}

/****************************************/
// NON-Interrupt subroutines
void setup()
{
	// Configuracion de prescaler a 16 F_cpu=1MHz
	CLKPR	=(1<<CLKPCE);
	CLKPR	=(1<<CLKPS2);
	// Configurar salidas
	DDRC	|=(1<<DDC3)|(1<<DDC2)|(1<<DDC1)|(1<<DDC0)|;
	PORTC	&=~((1<<DDC3)|(1<<DDC2)|(1<<DDC1)|(1<<DDC0)|);
	// Conigurar timer 0
	initTMR0();
}
void initTMR0()
{
	//Configurar en modo normal
	TCCR0A	&= ~((1<<WGM01)|(1<<WGM00));
	TCCR0B	&= ~(1<<WGM02);
	//Configurara prescaler tmr0 a 64
	TCCR0B	&= ~(1<<CS02);
	TCCR0B	|=((1<<CS01)|(1<<CS00));
	//Iniciar TCNT0
	TCNT0=TCNT0_value;
}
/****************************************/
// Interrupt routines

ISR(TIMER0_OVF_vect)
{
	TCNT0=TCNT0_value;
	counter++;
	if (counter==50)
	{
		PORTC++;
		PORTC&= 0x0F;
		counter=0;
	}
}