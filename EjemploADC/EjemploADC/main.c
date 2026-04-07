/*
 * main.c
 *
 * Created: 19/3/26
 * Author:  Diego Samayoa
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>	//Interrupciones
/****************************************/
// Function prototypes
void setup();
void initADC();
/****************************************/
// Main Function
int main(void)
{
	cli();
	setup();
	initADC();
	//Habilitar interrupciones
	ADCSRA|=(1<<ADIE);
	//Iniciar ADC
	ADCSRA|=(1<<ADSC);
	sei();
    while (1)
    {
    }
}

/****************************************/
// NON-Interrupt subroutines
void setup()
{
	//prescaler CPU =16 f=1MHz
	CLKPR=(1<<CLKPCE);
	CLKPR=(1<<CLKPS2);
	
	// entradas y salidas (DDRD)
	
	DDRD=0xFF;
	PORTD=0x00;
	UCSR0B=0x00;	//apagar PD0 y PD1
	
	
}

void initADC()
{
	//borrar ADMUX=00000110
	ADMUX=0;
	//VRef=AVcc; justificado a la izquierda
	ADMUX|=(1<<REFS0)|(1<<ADLAR)|(1<<REFS0)|(1<<REFS0);
	//Borrar ADCSRA
	ADCSRA=0;
	//Habilitar ADC y PRescaler=8 ->1Mhz/8
	ADCSRA|=(1<<ADEN)|(1<<ADPS1)|(1<<ADPS0);
	
}
/****************************************/
// Interrupt routines
ISR(ADC_vect)
{
	PORTD=ADCH;
	ADCSRA|=(1<<ADSC);	//para que se repita 
}