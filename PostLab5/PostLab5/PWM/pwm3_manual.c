#include "pwm3_manual.h"
#include <avr/io.h>
#include <avr/interrupt.h>



volatile uint8_t pwm_counter = 0;//interrupciones
volatile uint8_t pwm_duty = 0;

void ManualPWM_Init(void)
{
	DDRD |= (1 << DDD5);// led salida
	PORTD &= ~(1 << PORTD5);

	TCCR0A = 0;//limpiar timer0
	TCCR0B = 0;

	TCCR0A |= (1 << WGM01);//modo CTC
	TCCR0B |= (1 << CS01) | (1 << CS00);//prescaler 64

	OCR0A = 24;// cada 25 ticks interrupcion

	TIMSK0 |= (1 << OCIE0A);

	sei();
}

void ManualPWM_SetDuty(uint8_t porcentaje) //limitar al 100%
{
	if (porcentaje > 100)
	{
		porcentaje = 100;
	}

	pwm_duty = porcentaje;//duty cycle que define el brillo
}

ISR(TIMER0_COMPA_vect)// automatico
{
	pwm_counter++;//contar de 0 a 99

	if (pwm_counter >= 100)//reiniciar
	{
		pwm_counter = 0;//empieza ciclo

		if (pwm_duty > 0)//si el duty cycle es mayor que 0 enciendo el led
		{
			PORTD |= (1 << PORTD5);
		}
		else // ciclo es 0 led apagada
		{
			PORTD &= ~(1 << PORTD5);
		}
	}

	if (pwm_counter >= pwm_duty)
	{
		PORTD &= ~(1 << PORTD5);
	}
}