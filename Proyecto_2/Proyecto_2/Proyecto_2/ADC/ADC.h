/*
 * ADC.h
 *
 * Created: 4/28/2026 12:23:49 PM
 *  Author: diego
 */ 


#ifndef ADC_H_
#define ADC_H_

#include <avr/io.h>
#include <stdint.h>

void ADC_Init(void);
uint16_t ADC_Read(uint8_t channel);
uint8_t ADC_ToAngle(uint16_t adc_value);

#endif /* ADC_H_ */