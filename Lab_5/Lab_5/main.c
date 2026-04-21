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

#define F_CPU 16000000UL

#include <avr/io.h>
#include <stdint.h>
#include <util/delay.h>

#include "PWM/pwm1_servo.h"
#include "PWM/pwm2_servo.h"

/****************************************/
// Prototipos
static void ADC_Init(void);
static uint16_t ADC_Read(uint8_t channel);
static uint8_t Map_ADC_To_Angle(uint16_t adc_value);
/****************************************/

int main(void)
{
	uint16_t pot_servo_a;
	uint16_t pot_servo_b;

	ADC_Init();
	PWM1_Init();
	PWM2_Init();

	while (1)
	{
		// Servo 1 ? A4
		pot_servo_a = ADC_Read(4);
		Servo1_SetAngle(Map_ADC_To_Angle(pot_servo_a));
		_delay_ms(20);

		// Servo 2 ? A5
		pot_servo_b = ADC_Read(5);
		Servo2_SetAngle(Map_ADC_To_Angle(pot_servo_b));
		_delay_ms(20);
	}
}

/****************************************/
// ADC
/****************************************/

static void ADC_Init(void)
{
	ADMUX = 0;
	ADCSRA = 0;

	ADMUX |= (1 << REFS0); // AVcc referencia
	ADCSRA |= (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // prescaler 128
}

static uint16_t ADC_Read(uint8_t channel)
{
	channel &= 0x07;

	ADMUX = (ADMUX & 0xF0) | channel;
	ADCSRA |= (1 << ADSC);

	while (ADCSRA & (1 << ADSC));

	return ADC;
}

static uint8_t Map_ADC_To_Angle(uint16_t adc_value)
{
	return (uint8_t)(((uint32_t)adc_value * 180U) / 1023U);
}