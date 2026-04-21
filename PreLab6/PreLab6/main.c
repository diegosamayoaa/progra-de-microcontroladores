/*
 * main.c
 *
 * Created: 21/4/26
 * Author: Diego Samayoa
 * Description:
 */

/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL
#define BAUD 9600
#define UBRR_VALUE ((F_CPU/16/BAUD)-1)

#include <avr/io.h>
/****************************************/

// Function prototypes
void UART_init(void);
void UART_tx(char data);
char UART_rx(void);
/****************************************/

// Main Function
int main(void)
{
	UART_init();

	DDRB = 0xFF; // LEDs en el puerto B

	while (1)
	{
		UART_tx('D'); //Mandamos la letra D

		for (volatile long i = 0; i < 500000; i++);

		PORTB = UART_rx(); //Mostramos en los leds del puerto B el binario del caracter que enviamos
	}
}

/****************************************/
// NON-Interrupt subroutines

void UART_init(void)
{
	// Configura la velocidad de comunicación (baud rate)
	UBRR0H = (UBRR_VALUE >> 8);
	UBRR0L = UBRR_VALUE;

	// Habilita transmisión (TX) y recepción (RX)
	UCSR0B = (1 << TXEN0) | (1 << RXEN0);

	// Configura el formato: 8 bits de datos, sin paridad, 1 bit de parada
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void UART_tx(char data)
{
	// Espera hasta que el buffer de transmisión esté vacío
	while (!(UCSR0A & (1 << UDRE0)));

	// Envía un carácter por UART
	UDR0 = data;
}

char UART_rx(void)
{
	// Espera hasta que llegue un dato recibido
	while (!(UCSR0A & (1 << RXC0)));

	// Retorna el dato recibido
	return UDR0;
}

/****************************************/
// Interrupt routines