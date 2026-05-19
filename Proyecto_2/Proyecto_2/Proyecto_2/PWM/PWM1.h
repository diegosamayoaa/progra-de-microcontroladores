/*
 * PWM1.h
 *
 * Created: 4/28/2026 12:05:27 PM
 *  Author: diego
 */ 


#ifndef PWM1_H_
#define PWM1_H_

#include <avr/io.h>
#include <stdint.h>

void PWM1_InitServo(void);
void Servo1A_SetAngle(uint8_t angle);
void Servo1B_SetAngle(uint8_t angle);

#endif /* PWM1_H_ */