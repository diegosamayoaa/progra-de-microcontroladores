/*
 * main.c
 *
 * Created: 21/4/26
 * Author: Diego Samayoa
 * Description: Por medio de UART se tiene un sistema con dos funciones, la primera es que se envia un caracter y este se muestra en un set de 8 leds
 *				y la otra funcion es mostrar el valor de un potenciometro con lectura ADC
 */

/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL
#define BAUD 9600
#define UBRR_VALUE ((F_CPU/16/BAUD)-1)

#include <avr/io.h>
#include <util/delay.h>
/****************************************/

// Function prototypes
void UART_init(void);
void UART_tx(char data);
char UART_rx(void);
void cadena(char txt[]);
void ADC_init(void);
uint16_t ADC_read(void);
void UART_tx_num(uint16_t num);
/****************************************/

// Main Function
int main(void)
{
	UART_init();
	ADC_init();

	DDRB = 0b00111111;   // PB0-PB5 como salida
	DDRC = 0b00000011;   // PC0-PC1 como salida, PC2 queda como entrada ADC

	uint8_t dato;
	uint16_t pot;
	char opcion;

	while (1)
	{
		cadena("\r\n--- MENU Lab 6 ---\r\n");
		cadena("1. Leer Potenciometro\r\n");
		cadena("2. Enviar ASCII\r\n");
		cadena("Seleccione una opcion: ");

		opcion = UART_rx();
		UART_tx(opcion); 
		cadena("\r\n");

		if (opcion == '1')
		{
			pot = ADC_read();
			cadena("Valor del potenciometro: ");
			UART_tx_num(pot);
			cadena("\r\n");
		}
		else if (opcion == '2')
		{
			cadena("Ingrese un caracter: ");
			dato = UART_rx();
			UART_tx(dato); 
			cadena("\r\n");

			PORTB = (dato & 0b00111111);   // bits 0-5 a PB0-PB5
			PORTC = (dato >> 6) & 0b00000011; // bits 6-7 a PC0-PC1
		}
		else
		{
			cadena("Opcion invalida solo puede ser 1 o 2\r\n");
		}

		_delay_ms(500);
	}
}

/****************************************/
// NON-Interrupt subroutines

void UART_init(void)
{
	// Configura la velocidad de comunicación
	UBRR0H = (UBRR_VALUE >> 8);
	UBRR0L = UBRR_VALUE;

	// Habilita transmisión y recepción
	UCSR0B = (1 << TXEN0) | (1 << RXEN0);

	// Formato: 8 bits, sin paridad, 1 bit de parada
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void UART_tx(char data)
{
	// Espera hasta que el buffer de transmisión esté vacío
	while (!(UCSR0A & (1 << UDRE0)));

	// Envía un carácter
	UDR0 = data;
}

char UART_rx(void)
{
	// Espera hasta recibir un dato
	while (!(UCSR0A & (1 << RXC0)));

	// Retorna el dato recibido
	return UDR0;
}

void cadena(char txt[])
{
	// Envía una cadena carácter por carácter
	while (*txt != '\0')
	{
		UART_tx(*txt);
		txt++;
	}
}

void ADC_init(void)
{
	// Referencia AVcc, canal ADC2 (PC2 / A2)
	ADMUX = (1 << REFS0) | (1 << MUX1);

	// Habilita ADC, prescaler 128
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t ADC_read(void)
{
	// Inicia conversión
	ADCSRA |= (1 << ADSC);

	// Espera a que termine
	while (ADCSRA & (1 << ADSC));

	// Retorna valor de 10 bits
	return ADC;
}

void UART_tx_num(uint16_t num)
{
	char buffer[6];      // arreglo para guardar los digitos
	uint8_t i = 0;       // contador

	if (num == 0)        // si el numero es 0
	{
		UART_tx('0');    // enviamos '0'
		return;          // salimos de la funcion
	}

	while (num > 0)      // mientras haya digitos
	{
		buffer[i] = (num % 10) + '0'; // obtenemos el ultimo digito y lo pasamos a ASCII
		num = num / 10;               // eliminamos el ultimo digito
		i++;                         
	}

	while (i > 0)        // recorrer el arreglo al reves
	{
		i--;             
		UART_tx(buffer[i]); // enviar cada digito
	}
}

/****************************************/
// Interrupt routines