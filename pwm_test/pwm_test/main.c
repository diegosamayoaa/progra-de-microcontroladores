/*
 * main.c
 *
 * Created: 
 * Author: 
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <util/delay.h>
/****************************************/
// Function prototypes
void setup();
void initPWM();
void updateDutyCycle0A(uint8_t ciclo);
void updateDutyCycle0B(uint8_t ciclo);
/****************************************/
// Main Function
int main(void)
{
	uint8_t duty=127;
	setup();
	initPWM();
	updateDutyCycle0A(duty);
	updateDutyCycle0B(duty);
    /* Replace with your application code */
    while (1) 
    {
			updateDutyCycle0A(duty);
			updateDutyCycle0B(duty);
			duty++
			
    }
}

/****************************************/
// NON-Interrupt subroutines
void setup ()
{
	CLKPR=(1<<CLKPCE);
	CLKPR=(1<<CLKPS2);//prescaler para que sea 1Mhz
}
void initPWM()
{
	//Configurar salidas
	DDRD |=(1<<DDD6)|(1<<DDD5);
	TCCR0A=0;
	TCCR0B=0;
	
	// NO invertido OCROA e INVERTIDO OCROB
	TCCR0A |= (1<<COM0A1);// no invertido
	TCCR0A |= (1<<COM0A1)|(1<<COM0B0);//invertido
	
	TCCR0A |= (1<<WGM01)|(1<<WGM00);
	
	TCCR0B |=(1<<CS01); //Prescaler = 8
}
void updateDutyCycle0A()
{
	OCR0A=ciclo;
}
void updateDutyCycle0B()
{
	OCR0B=ciclo;
}
/****************************************/
// Interrupt routines


// UCSR0B = 0x00; //desactivar usart