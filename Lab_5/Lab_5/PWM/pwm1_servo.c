/*
 * pwm1_servo.c
 *
 * Created: 4/14/2026 
 *  Author: diego
 */ 
#include "pwm1_servo.h"
#include <avr/io.h>

// 16 MHz -> prescaler 8 -> 0.5 micros por tick
// 1000 ticks -- 5000 ticks

#define SERVO_MIN_US 500U
#define SERVO_MAX_US 2500U
#define SERVO_TOP    39999U

static uint16_t AngleToTicks(uint8_t angle);

void PWM1_Init(void)
{
	// D9 ? OC1A
	DDRB |= (1 << DDB1);

	TCCR1A = 0;
	TCCR1B = 0;

	// Fast PWM, TOP = ICR1
	TCCR1A |= (1 << COM1A1) | (1 << WGM11);
	TCCR1B |= (1 << WGM13) | (1 << WGM12) | (1 << CS11); // prescaler 8

	ICR1 = SERVO_TOP;

	Servo1_SetAngle(90);
}

void Servo1_SetAngle(uint8_t angle)
{
	OCR1A = AngleToTicks(angle);
}

static uint16_t AngleToTicks(uint8_t angle)
{
	if (angle > 180) angle = 180;

	uint16_t pulse = SERVO_MIN_US +
	(((uint32_t)(SERVO_MAX_US - SERVO_MIN_US) * angle) / 180U);

	return pulse * 2; // 0.5 us por tick
}