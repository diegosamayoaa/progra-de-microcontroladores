/*
 * main.c
 *
 * Created: 23/4/26
 * Author: Diego Samayoa
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>
#include "UARTlib/UART.h"
#include "EEPROMlib/eeprom.h"
/****************************************/
// Function prototypes
uint16_t dir_eeprom = 0;

const char* L1_on = "L1:1";
const char* L1_off = "L1:0";
const char* L2_on = "L2:1";
const char* L2_off = "L2:0";

char* string_rec = "----";//declarar que son 4 espacios
uint8_t num_caracter = 0;

void estado_leds();
/****************************************/
// Main Function
int main(void)
{
	cli();
	//LEDs
	DDRD |= (1<DDD6)|(1<<DDD5);
	PORTD &= ~((1<<PORTD6)|(1<<PORTD5));
	//Boton
	DDRD &= ~((1<<DDD2));
	PORTD |= (1<<PORTD2);
	//Interrupcion PIN change puerto D
	PCICR |= (1<<PCIE2);
	//Colocamos que el boton va a estar en PD2
	PCMSK2 |= (1<<PCINT18);
	
	
	estado_leds();
	init_UART();
	sei();
	
	/*uint8_t lectura = readEEPROM(dir_eeprom);
	while (lectura != 0xFF)
	{
		writeChar(lectura);
		//writeEEPROM(dir_eeprom,0xFF); se usa para borrar todo
		dir_eeprom++;
		lectura = readEEPROM(dir_eeprom);
	}
	//dir_eeprom = 0; se usa para borrar todo*/
	
    while (1) 
    {
    }
}

/****************************************/
// NON-Interrupt subroutines

void estado_leds()
{
	//Se usa para guardar el ultimo estado de las leds antes de apagarlo
	uint8_t estadoL1 = readEEPROM(0);
	uint8_t estadoL2 = readEEPROM(1);
	if(estadoL1 == 1)
	{
		PORTD|= (1<<PORTD5);
	}
	if(estadoL2 == 1)
	{
		PORTD|= (1<<PORTD6);
	}
}
/****************************************/
// Interrupt routines
ISR(USART_RX_vect)
{
	uint8_t rx_buffer = UDR0;
	if(rx_buffer!= '\n')
	{
		writeChar(rx_buffer);
		*(string_rec+num_caracter)=rx_buffer;
		num_caracter++;
		
		//Proceso para encender o apagar led 1
		
		if(*(string_rec+0) ==*(L1_on+0) &&
		   *(string_rec+1) ==*(L1_on+1) &&
		   *(string_rec+2) ==*(L1_on+2))
		{
			if(*(string_rec+3) ==*(L1_on+3))
			{
				PORTD |=(1<<PORTD5);
				writeEEPROM(0,1);
			}
			
			if(*(string_rec+3) ==*(L1_off+3))
			{
				PORTD &=~((1<<PORTD5));
				writeEEPROM(0,0);
			}
			
		}
		
		//Proceso para encender o apagar led 2
		
		if(*(string_rec+0) ==*(L2_on+0) &&
		   *(string_rec+1) ==*(L2_on+1) &&
		   *(string_rec+2) ==*(L2_on+2))
		{
			if(*(string_rec+3) ==*(L2_on+3))
			{
				PORTD |=(1<<PORTD5);
				writeEEPROM(1,1);
			}
			
			if(*(string_rec+3) ==*(L2_off+3))
			{
				PORTD &=~((1<<PORTD5));
				writeEEPROM(1,0);
			}
			
		}
		
		/*if (rx_buffer=='a')
		{
			PORTD^=(1<<PORTD5);
		}
		if (rx_buffer=='b')
		{
			PORTD^=(1<<PORTD6);
		}*/
	}
	else{
		
		for(uint8_t i=0; i<4; i++)
		{
			*(string_rec+1)='-';
		}
		num_caracter=0;
	}

	//writeEEPROM(dir_eeprom, rx_buffer);
	//dir_eeprom++;
}

ISR(PCINT2_vect)
{
	uint8_t estadoPIND= PIND & (1<<PIND2);
	if (~(estadoPIND==(1<<PIND)))
	{
		PORTD ^= (1<<PORTD5);
	}
}