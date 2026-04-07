/*
 * main.c
 *
 * Created: 4/6/26
 * Author: Diego Samayoa
 * Description: Contador binario de 8 bits con dos pushbuttons
 *              PB0 incrementa el contador
 *              PB1 decrementa el contador
 *              Se implementa antirrebote fisico
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>

/****************************************/
// Function prototypes
void setup(void);
uint8_t boton(uint8_t pin);
/****************************************/
// Main Function
int main(void)
{
	uint8_t counter=0;
	
	setup();
	PORTD=counter;
	
    while (1) 
    {
		 // Incrementar con boton en PB0
		 if (boton(PB0))
		 {
			 counter++;
			 PORTD = counter;

			 // revisar botonazo y esperar que suelte
			 while (!(PINB & (1 << PB0)));
			 
		 }

		 // Decrementar con boton en PB1
		 if (boton(PB1))
		 {
			 counter--;
			 PORTD = counter;

			 // revisar botonazo y esperar que suelte
			 while (!(PINB & (1 << PB1)));
			
		 }
    }
}

/****************************************/
// NON-Interrupt subroutines
void setup(void)
{
	// Desactivamos USART
	UCSR0B = 0x00;
	//Configurar PORTD como salida
	DDRD=0xFF;
	PORTD=0x00;
	
	//Configurar PB0 y PB1 como entradas con pullup
	DDRB &= ~((1 << PB0) | (1 << PB1));
	PORTB |= (1 << PB0) | (1 << PB1);
}

uint8_t boton(uint8_t pin)
{
	//detectar botonazo 
	if (!(PINB & (1 << pin)))
	{
		
		if (!(PINB & (1 << pin)))
		{
			return 1;
		}
	}
	return 0;
}
/****************************************/
// Interrupt routines