/*
 * main.c
 *
 * Created: 12/3/26
 * Author: Diego Samayoa
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)

#include <avr/io.h>
#include <stdint.h>

/****************************************/
// Function prototypes

void setup();
void delay();

/****************************************/
// Main Function
int main(void)
{
	setup();
	while (1)
	{
		PORTC	^|=(1<<DDC3)|(1<<DDC2)|(1<<DDC1)|(1<<DDC0)|;// ^ es toggle
		delay();
		//PORTC	&=~((1<<DDC3)|(1<<DDC2)|(1<<DDC1)|(1<<DDC0)|);
		//delay();
	}
}
/****************************************/
// NON-Interrupt subroutines
void setup()
{
	// Configuracion de prescaler a 16
	CLKPR	=(1<<CLKPCE);
	CLKPR	=(1<<CLKPS2);
	// Configurar salidas
	DDRC	|=(1<<DDC3)|(1<<DDC2)|(1<<DDC1)|(1<<DDC0)|;
	PORTC	&=~((1<<DDC3)|(1<<DDC2)|(1<<DDC1)|(1<<DDC0)|);
}
void delay()
{
	for (volatile uint8_t i=0;i<255;i++)
	{
		for (volatile uint8_t i=0;i<255;i++)
		{	
		}
	}
}
/****************************************/
// Interrupt routines