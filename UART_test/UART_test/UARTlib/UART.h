/*
 * UART.h
 *
 * Created: 4/23/2026 2:35:29 PM
 *  Author: diego
 */ 


#ifndef UART_H_
#define UART_H_

#include <avr/io.h>

void init_UART();
void writeChar(char c);
void writeString(char* string);



#endif /* UART_H_ */