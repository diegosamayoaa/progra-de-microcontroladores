#include "pwm1_servo.h"
#include <avr/io.h>


#define servo_min 500U
#define servo_max 2500U
#define servo_top    39999U

static uint16_t AngleToTicks(uint8_t angle);

void PWM1_Init(void)
{
	
	DDRB |= (1 << DDB1);// pin d9 salida servo

	TCCR1A = 0;
	TCCR1B = 0;//limpiar timer1

	// Fast PWM, TOP = ICR1
	TCCR1A |= (1 << COM1A1) | (1 << WGM11);// activar salida PWM en modo Fast con top en ICR1
	TCCR1B |= (1 << WGM13) | (1 << WGM12) | (1 << CS11); // prescaler 8

	ICR1 = servo_top;// con 16mhz y prescaler 8 40000 ticks son 20ms

	Servo1_SetAngle(90);
}

void Servo1_SetAngle(uint8_t angle)
{
	OCR1A = AngleToTicks(angle);// el valor de OCR1A define el ancho de pulso
}

static uint16_t AngleToTicks(uint8_t angle)
{
	if (angle > 180) angle = 180;

	uint16_t pulse = servo_min +
	(((uint32_t)(servo_max - servo_min) * angle) / 180U);// convertir 0 a 500 y 180 a 2500 microsegundos

	return pulse * 2;
}