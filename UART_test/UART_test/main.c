/*
 * UART_test.c
 *
 * Created: 4/16/2026 3:27:33 PM
 * Author : diego
 */ 
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
//Llamar librerias
#include "UARTlib/UART.h"
/****************************************/
// Function prototypes

/****************************************/
// Main Function
int main(void)
{
	cli();
	DDRB|=(1<<DDB5);
	DDRD|=(1<<DDD5);
	PORTB &= ~(1<<PORTB5);
	PORTD &= ~(1<<PORTD5);
    init_UART();
	sei();
	writeString();
    while (1) 
    {
    }
}

/****************************************/
// NON-Interrupt subroutines


/****************************************/
// Interrupt routines
ISR(USART_RX_vect)
{
	uint8_t bufferRX=UDR0;
	writeChar((bufferRX));
	if (bufferRX=='a')
	{
		//Encender ambos leds
		PORTB|= (1<<PORTB5);
		PORTD|= (1<<PORTD5);
	}
	if (bufferRX=='b')
	{
		//Apagar ambos leds
		PORTB &= ~(1<<PORTB5);
		PORTD &= ~(1<<PORTD5);
	}
}

