/*
 * eeprom.c
 *
 * Created: 4/23/2026 3:09:04 PM
 *  Author: diego
 */ 

#include "eeprom.h"

void writeEEPROM(uint16_t direccion, uint8_t dato)
{
	//Esperar a que termine de escribir el dato anterior
	while(EECR & (1<<EEPE));
	//Asignar direccion donde queremos esribrir
	EEAR = direccion;
	//Asignar dato a guardar
	EEDR = dato;
	//Master write
	EECR |= (1<<EEMPE);
	//write enable
	EECR |= (1<<EEPE);
}
uint8_t readEEPROM(uint16_t direccion)
{
	//Esperar a que termine de escribir el dato anterior
	while(EECR & (1<<EEPE));
	//Asignar direccion de donde queremos leer
	EEAR = direccion;
	// Read enable
	EECR |= (1<<EERE);
	//retornar lectura de la EEPROM en direccion deseada
	return EEDR;
}