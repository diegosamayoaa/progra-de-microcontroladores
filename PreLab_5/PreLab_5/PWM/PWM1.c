/*
 * PWM1.c
 *
 * Created: 4/14/2026 11:27:51 AM
 *  Author: diego
 */ 
#include "PWM1.h"

void initPWM1A(uint8_t invert, uint8_t modo, uint16_t prescaler)
{
	//CONFIGURAMOS COMO SALIDAS A PORTD6 . OCR0A = PD6
	DDRB |= (1<<DDB1);
	
	TCCR1A = 0;
	TCCR1B = 0;
	
	if (invert)
	{
		TCCR1A |= (1<<COM1A1)|(1<<COM1A0); //invertido=1
	}
	else
	{
		TCCR1A |= (1<<COM1A1); // no invertido=0
	}

	switch(modo)
	{
		case 0:
		TCCR1A |= (1<<WGM10); //phase correct 8=0
		break;

		case 1:
		TCCR1A |= (1<<WGM11); //phase correct 9=1
		break;

		case 2:
		TCCR1A |= (1<<WGM11)|(1<<WGM10); //phase correct 10=2
		break;

		case 3:
		TCCR1A |= (1<<WGM10); //fast 8=3
		TCCR1B |= (1<<WGM12);
		break;

		case 4:
		TCCR1A |= (1<<WGM11); //fast 9=4
		TCCR1B |= (1<<WGM12);
		break;

		case 5:
		TCCR1A |= (1<<WGM11)|(1<<WGM10); //fast 10=5
		TCCR1B |= (1<<WGM12);
		break;

		case 6:
		TCCR1B |= (1<<WGM13); //phase freq correct ICR1=6
		break;

		case 7:
		TCCR1A |= (1<<WGM10);
		TCCR1B |= (1<<WGM13); //phase freq correct OCR1A=7
		break;

		case 8:
		TCCR1A |= (1<<WGM11)|(1<<WGM10);
		TCCR1B |= (1<<WGM13); //phase correct ICR1=8
		break;

		case 9:
		TCCR1A |= (1<<WGM11)|(1<<WGM10);
		TCCR1B |= (1<<WGM12)|(1<<WGM13); //phase correct OCR1A=9
		break;

		case 10:
		TCCR1A |= (1<<WGM11);
		TCCR1B |= (1<<WGM12)|(1<<WGM13); //fast ICR1=10
		break;

		case 11:
		TCCR1A |= (1<<WGM11)|(1<<WGM10);
		TCCR1B |= (1<<WGM12)|(1<<WGM13); //fast OCR1A=11
		break;

		default:
		TCCR1A |= (1<<WGM10); //phase correct 8 bits
		break;
	}
	switch(prescaler)
	{
		case 1:
		TCCR1B |= (1<<CS10); //prescaler 1=1
		break;

		case 8:
		TCCR1B |= (1<<CS11); //prescaler 8=8
		break;

		case 64:
		TCCR1B |= (1<<CS11)|(1<<CS10); //prescaler 64=64
		break;

		case 256:
		TCCR1B |= (1<<CS12); //prescaler 256=256
		break;

		case 1024:
		TCCR1B |= (1<<CS12)|(1<<CS10); //prescaler 1024=1024
		break;

		default:
		TCCR1B |= (1<<CS10); //prescaler 1 default
		break;
	}
}

void initPWM1B(uint8_t invert, uint8_t modo, uint16_t prescaler)
{
	//config salida OC1B = PB2
	DDRB |= (1<<DDB2);
	
	//reset configuracion timer1
	TCCR1A &= ~((1<<COM1B1)|(1<<COM1B0)|(1<<WGM11)|(1<<WGM10));
	TCCR1B = 0;
	
	if (invert)
	{
		TCCR1A |= (1<<COM1B1)|(1<<COM1B0); //invertido=1
	}
	else
	{
		TCCR1A |= (1<<COM1B1); //no invertido=0
	}

	switch(modo)
	{
		case 0:
		TCCR1A |= (1<<WGM10); //phase correct 8=0
		break;

		case 1:
		TCCR1A |= (1<<WGM11); //phase correct 9=1
		break;

		case 2:
		TCCR1A |= (1<<WGM11)|(1<<WGM10); //phase correct 10=2
		break;

		case 3:
		TCCR1A |= (1<<WGM10); //fast 8=3
		TCCR1B |= (1<<WGM12);
		break;

		case 4:
		TCCR1A |= (1<<WGM11); //fast 9=4
		TCCR1B |= (1<<WGM12);
		break;

		case 5:
		TCCR1A |= (1<<WGM11)|(1<<WGM10); //fast 10=5
		TCCR1B |= (1<<WGM12);
		break;

		case 6:
		TCCR1B |= (1<<WGM13); //phase freq correct ICR1=6
		break;

		case 7:
		TCCR1A |= (1<<WGM10);
		TCCR1B |= (1<<WGM13); //phase freq correct OCR1A=7
		break;

		case 8:
		TCCR1A |= (1<<WGM11)|(1<<WGM10);
		TCCR1B |= (1<<WGM13); //phase correct ICR1=8
		break;

		case 9:
		TCCR1A |= (1<<WGM11)|(1<<WGM10);
		TCCR1B |= (1<<WGM12)|(1<<WGM13); //phase correct OCR1A=9
		break;

		case 10:
		TCCR1A |= (1<<WGM11);
		TCCR1B |= (1<<WGM12)|(1<<WGM13); //fast ICR1=10
		break;

		case 11:
		TCCR1A |= (1<<WGM11)|(1<<WGM10);
		TCCR1B |= (1<<WGM12)|(1<<WGM13); //fast OCR1A=11
		break;

		default:
		TCCR1A |= (1<<WGM10); //phase correct 8 default
		break;
	}

	switch(prescaler)
	{
		case 1:
		TCCR1B |= (1<<CS10); //prescaler 1=1
		break;

		case 8:
		TCCR1B |= (1<<CS11); //prescaler 8=8
		break;

		case 64:
		TCCR1B |= (1<<CS11)|(1<<CS10); //prescaler 64=64
		break;

		case 256:
		TCCR1B |= (1<<CS12); //prescaler 256=256
		break;

		case 1024:
		TCCR1B |= (1<<CS12)|(1<<CS10); //prescaler 1024=1024
		break;

		default:
		TCCR1B |= (1<<CS10); //prescaler 1 default
		break;
	}
}
void updateDutyCycle1A(uint32_t duty)
{
	OCR1A = duty;
}
void updateDutyCycle1B(uint32_t duty)
{
	OCR1B = duty;
}