/*
 * PWM1.c
 *
 * Created: 4/28/2026 12:05:38 PM
 *  Author: diego
 */ 
#include "PWM1.h"

#define SERVO_MIN 2000
#define SERVO_MAX 4000
#define SERVO_TOP 39999

static uint16_t angleToTicks(uint8_t angle)
{
	if (angle > 180)
	{
		angle = 180;
	}

	return SERVO_MIN + ((uint32_t)angle * (SERVO_MAX - SERVO_MIN)) / 180;
}

void PWM1_InitServo(void)
{
	DDRB |= (1 << DDB1); // OC1A - D9
	DDRB |= (1 << DDB2); // OC1B - D10

	TCCR1A = 0;
	TCCR1B = 0;

	TCCR1A |= (1 << COM1A1) | (1 << COM1B1);
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM13) | (1 << WGM12);

	TCCR1B |= (1 << CS11); // Prescaler 8

	ICR1 = SERVO_TOP;

	Servo1A_SetAngle(90);
	Servo1B_SetAngle(90);
}

void Servo1A_SetAngle(uint8_t angle)
{
	OCR1A = angleToTicks(angle);
}

void Servo1B_SetAngle(uint8_t angle)
{
	OCR1B = angleToTicks(angle);
}