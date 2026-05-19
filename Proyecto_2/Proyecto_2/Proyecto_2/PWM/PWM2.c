/*
 * PWM2.c
 *
 * Created: 4/28/2026 12:08:53 PM
 *  Author: diego
 */ 

#include "PWM2.h"
#include <avr/interrupt.h>

#define SERVO_MIN_TICKS 100
#define SERVO_MAX_TICKS 200
#define FRAME_TICKS     2000

static volatile uint16_t servo2A_ticks = 150;
static volatile uint16_t servo2B_ticks = 150;
static volatile uint16_t frame_counter = 0;

static uint16_t AngleToTicks(uint8_t angle)
{
	if (angle > 180)
	{
		angle = 180;
	}

	return SERVO_MIN_TICKS + ((uint32_t)angle * (SERVO_MAX_TICKS - SERVO_MIN_TICKS)) / 180;
}

void PWM2_InitServo(void)
{
	DDRB |= (1 << DDB3); // OC2A / D11
	DDRD |= (1 << DDD3); // OC2B / D3

	PORTB &= ~(1 << PORTB3);
	PORTD &= ~(1 << PORTD3);

	TCCR2A = 0;
	TCCR2B = 0;

	TCCR2A |= (1 << WGM21); // Modo CTC
	TCCR2B |= (1 << CS21);  // Prescaler 8

	OCR2A = 19; // interrupción cada 10 us

	TIMSK2 |= (1 << OCIE2A);

	Servo2A_SetAngle(90);
	Servo2B_SetAngle(90);
}

void Servo2A_SetAngle(uint8_t angle)
{
	servo2A_ticks = AngleToTicks(angle);
}

void Servo2B_SetAngle(uint8_t angle)
{
	servo2B_ticks = AngleToTicks(angle);
}

ISR(TIMER2_COMPA_vect)
{
	frame_counter++;

	if (frame_counter >= FRAME_TICKS)
	{
		frame_counter = 0;

		PORTB |= (1 << PORTB3);
		PORTD |= (1 << PORTD3);
	}

	if (frame_counter == servo2A_ticks)
	{
		PORTB &= ~(1 << PORTB3);
	}

	if (frame_counter == servo2B_ticks)
	{
		PORTD &= ~(1 << PORTD3);
	}
}