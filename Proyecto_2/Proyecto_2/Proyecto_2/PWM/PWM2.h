/*
 * PWM2.h
 *
 * Created: 4/28/2026 12:09:03 PM
 *  Author: diego
 */ 


#ifndef PWM2_H_
#define PWM2_H_

#include <avr/io.h>
#include <stdint.h>

void PWM2_InitServo(void);
void Servo2A_SetAngle(uint8_t angle);
void Servo2B_SetAngle(uint8_t angle);


#endif /* PWM2_H_ */