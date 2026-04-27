/*
 * eeprom.h
 *
 * Created: 4/23/2026 3:09:14 PM
 *  Author: diego
 */ 


#ifndef EEPROM_H_
#define EEPROM_H_

#include <avr/io.h>

void writeEEPROM(uint16_t direccion, uint8_t dato);
uint8_t readEEPROM(uint16_t direccion);


#endif /* EEPROM_H_ */