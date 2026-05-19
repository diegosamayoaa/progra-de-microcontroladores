/*
 * ADC.c
 *
 * Created: 4/28/2026 12:23:55 PM
 *  Author: diego
 */ 
#include "ADC.h"

void ADC_Init(void)
{
	ADMUX = 0;
	ADCSRA = 0;

	ADMUX |= (1 << REFS0); // Referencia AVcc

	ADCSRA |= (1 << ADEN);  // Habilitar ADC
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Prescaler 128
}

uint16_t ADC_Read(uint8_t channel)
{
	channel &= 0x07; // Limita canales de 0 a 7

	ADMUX = (ADMUX & 0xF0) | channel;

	ADCSRA |= (1 << ADSC); // Inicia conversión

	while (ADCSRA & (1 << ADSC));

	return ADC;
}

uint8_t ADC_ToAngle(uint16_t adc_value)
{
	return (uint8_t)(((uint32_t)adc_value * 180U) / 1023U);
}