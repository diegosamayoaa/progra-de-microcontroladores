/*
 * UART.c
 *
 * Created: 4/23/2026 2:35:19 PM
 *  Author: diego
 */ 
#include "UART.h"

void init_UART()
{
	//Configurar pines
	DDRD &=~(1<<DDD0);//D0=RX entrada
	DDRD |=(1<<DDD1);//D1=TX salida
	//Normal speed
	UCSR0A=0;
	//Habilitar interrupcion de RX, habilitar RX y TX
	UCSR0B =(1<<RXEN0)|(1<<TXEN0);
	// Pongo que vamos a usar 8 bits, modo asincrono, 1 stop bit y sin paridad
	UCSR0C =(1<<UCSZ01)|(1<<UCSZ00);
	// Cargar UBRR0
	UBRR0=103; //9600 BAUD rate
	
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
char UART_ReadChar(void)
{
	while (!(UCSR0A & (1 << RXC0)));
	return UDR0;
}