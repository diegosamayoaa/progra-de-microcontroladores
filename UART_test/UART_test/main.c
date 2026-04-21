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
/****************************************/
// Function prototypes
void init_UART();
void writeChar(char c);
void writeString(char* string);
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
	writeChar('H');
	writeChar('o');
	writeChar('l');
	writeChar('a');
    while (1) 
    {
    }
}

/****************************************/
// NON-Interrupt subroutines
void init_UART()
{
	//Configurar pines
	DDRD &=~(1<<DDD0);//D0=RX entrada
	DDRD |=(1<<DDD0);//D1=TX salida
	//Normal speed
	UCSR0A=0;
	//Habilitar interrupcion de RX, habilitar RX y TX
	UCSR0B =(1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0);
	// Pongo que vamos a usar 8 bits, modo asincrono, 1 stop bit y sin paridad
	UCSR0C =(1<<UCSZ01)|(1<<UCSZ00);
	// Cargar UBRR0
	UBRR0=103;
	
}
void writeChar(char c)
{
	while(!(UCSR0A & (1<<UDRE0)));
	
	UDR0=c;
}
void writeString(char* string)
{
	for(uint8_t i=0; string[i] !='\0';i++)
	{
		writeChar(string[i]);
	}
}

/****************************************/
// Interrupt routines
ISR(USART_RX_vect)
{
	uint8_t bufferRX=UDR0;
	writeChar((bufferRX));
	if (bufferRX=='a')
	{
		PORTB|= (1<<PORTB5);
		PORTD|= (1<<PORTD5);
	}
	if (bufferRX=='b')
	{
		PORTB &= ~(1<<PORTB5);
		PORTD &= ~(1<<PORTD5);
	}
}

// UCSR0B = 0x00; //desactivar usart