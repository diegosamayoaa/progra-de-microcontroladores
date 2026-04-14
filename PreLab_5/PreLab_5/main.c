/*
 * PreLab_5.c
 *
 *
 * main.c
 *
 * Created: 14/4/26
 * Author: Diego Samayoa
 * Description: Conversion ADC y modulo PWM1 para controlar un servo
 */

/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include "PWM/PWM1.h"
/****************************************/
//Variables Globales
volatile uint8_t valor_ADC = 0;
/****************************************/
// Function prototypes
void setup();
void initADC6();
/****************************************/
// Main Function
int main(void)
{
	cli();
	//setup();
	initADC6();
	initPWM1A(no_invertido, fastPWM_ICR1_top, 8);
	ICR1 = 39999;
	OCR1A = 3000;
	sei();
	
	
	while (1)
	{
		updateDutyCycle1A(800 + ((uint32_t)valor_ADC * 4200) / 255);//Actualizar continuamente el duty cycle del PWM
	}
}
/****************************************/
// NON-Interrupt subroutines
void initADC6()
{
	ADMUX = 0;
	//aref = 5V; Justificación a la izquierda; Selección de ADC6
	
	ADMUX |= (1<<REFS0)|(1<<ADLAR)|(1<<MUX1)|(1<<MUX2);
	ADCSRA = 0;
	
	//se habilita ADC, prescaler, interrupcion y se comienza la conversion
	ADCSRA = (1<<ADEN)|(1<<ADIE)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADSC);
}
/****************************************/
// Interrupt routine
ISR(ADC_vect)
{
	valor_ADC = ADCH; //Se coloca el valor alto del adc
	ADCSRA |= (1<<ADSC); //se comienza otra vez la conversion
}
