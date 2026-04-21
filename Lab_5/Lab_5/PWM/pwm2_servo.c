/*
 * pwm2_servo.c
 *
 * Created: 4/14/2026 
 *  Author: diego
 */ 
#include "pwm2_servo.h"
#include <avr/io.h>

// 16 MHz -> prescaler de 1024 -> 64 micros por tick
// 2000 -- 4000

#define SERVO_MIN_COUNT 8U
#define SERVO_MAX_COUNT 39U

static uint8_t AngleToCounts(uint8_t angle);

void PWM2_Init(void)
{
	// D3 ? OC2B
	DDRD |= (1 << DDD3);

	TCCR2A = 0;
	TCCR2B = 0;

	// Fast PWM
	TCCR2A |= (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);

	// Prescaler 1024
	TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);

	Servo2_SetAngle(90);
}

void Servo2_SetAngle(uint8_t angle)
{
	OCR2B = AngleToCounts(angle);
}

static uint8_t AngleToCounts(uint8_t angle)
{
	if (angle > 180) angle = 180;

	return SERVO_MIN_COUNT +
	(((uint32_t)(SERVO_MAX_COUNT - SERVO_MIN_COUNT) * angle) / 180U);
}