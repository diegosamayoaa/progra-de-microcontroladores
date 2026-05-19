/*
 * main.c
 *
 * Created: 28/4/26
 * Author: Diego Samayoa
 * Description: Proyecto 2 que consta del manejo de 4 servos por medio de PWM para el funcionamiento de una garra. 3 maneras distintas de ajustarlo, por medio de ADC, EEPROM y Adafruit
 */
/****************************************/
// Encabezado (Libraries)

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include <stdio.h>      // Libreria utilizada para sprintf()
                        // sprintf() convierte numeros a texto

#include <stdlib.h>     // Libreria utilizada para atoi()
                        // atoi() convierte texto a numero entero

#include "PWM/PWM1.h"
#include "PWM/PWM2.h"
#include "UARTlib/UART.h"
#include "ADC/ADC.h"
#include "EEPROMlib/eeprom.h"

/****************************************/
// Definiciones de pines

#define boton  PD2              // Boton para cambiar modo
#define boton_guardar PD7       // Boton para guardar presets

#define led_m  PD4              // LED modo manual
#define led_e  PD5              // LED modo EEPROM
#define led_u  PD6              // LED modo UART/Adafruit

/****************************************/
// Variables globales

uint8_t modo = 0;               // Variable para manejar modos

uint8_t preset_actual = 0;      // Preset donde se guardara
uint8_t preset_uart = 0;        // Preset seleccionado por UART

uint8_t modo_anterior = 255;    // Para detectar cambio de modo

// Variables para almacenar angulos actuales
uint8_t a_servo1;
uint8_t a_servo2;
uint8_t a_servo3;
uint8_t a_servo4;

/****************************************/
// Function prototypes

void init_boton(void);
void boton_modo(void);

void init_leds(void);
void led_modo(void);

void guardar_e(void);
void leer_e(void);

void uart_preset(void);
void menu_uart(void);

void mostrar_angulos(void);

void uart_adafruit(void);

/****************************************/
// Main Function

int main(void)
{
    cli(); // Deshabilitar interrupciones globales

	/****************************************/
	// Inicializaciones

	PWM1_InitServo();     // Inicializar PWM Timer1
	PWM2_InitServo();     // Inicializar PWM Timer2

	init_UART();          // Inicializar UART
	ADC_Init();           // Inicializar ADC

	init_boton();         // Inicializar botones
	init_leds();          // Inicializar LEDs

	sei(); // Habilitar interrupciones globales

    while (1)
    {
	    // Revisar cambio de modo
	    boton_modo();

		// Detectar entrada a un nuevo modo
		if (modo != modo_anterior)
		{
			// Mostrar menu UART solo en modo EEPROM
			if (modo == 1)
			{
				menu_uart();
			}

			modo_anterior = modo;
		}

		/****************************************/
		// MODO 0 -> MANUAL

	    if (modo == 0)
	    {
		    led_modo();

			// Leer potenciometros y convertir a angulos
			a_servo1 = ADC_ToAngle(ADC_Read(0));
			a_servo2 = ADC_ToAngle(ADC_Read(1));
			a_servo3 = ADC_ToAngle(ADC_Read(2));
			a_servo4 = ADC_ToAngle(ADC_Read(3));

			// Actualizar servos
		    Servo1A_SetAngle(a_servo1);
		    Servo1B_SetAngle(a_servo2);
		    Servo2A_SetAngle(a_servo3);
		    Servo2B_SetAngle(a_servo4);

			// Guardar presets en EEPROM
			guardar_e();
	    }

		/****************************************/
		// MODO 1 -> EEPROM

	    else if (modo == 1)
	    {
		    led_modo();

			// Seleccionar presets mediante UART
			uart_preset();
	    }

		/****************************************/
		// MODO 2 -> ADAFRUIT IO

	    else if (modo == 2)
	    {
		    led_modo();

			// Control en tiempo real desde Adafruit
			uart_adafruit();
	    }
    }
}

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Inicializacion de botones

void init_boton(void)
{
	// Configurar botones como entrada
	DDRD &= ~(1 << boton);
	DDRD &= ~(1 << boton_guardar);

	// Activar pull-up interno
	PORTD |= (1 << boton);
	PORTD |= (1 << boton_guardar);
}

/****************************************/
// Funcion para cambiar modos

void boton_modo(void)
{
	static uint8_t estado_anterior = 1;
	static uint8_t boton_bloqueado = 0;

	uint8_t estado_actual = (PIND & (1 << boton)) ? 1 : 0;

	// Detectar flanco de bajada
	if (estado_actual == 0 && estado_anterior == 1 && boton_bloqueado == 0)
	{
		_delay_ms(30); // Antirrebote

		if (!(PIND & (1 << boton)))
		{
			modo++;

			// Regresar a modo 0
			if (modo > 2)
			{
				modo = 0;
			}

			boton_bloqueado = 1;
		}
	}

	// Liberar boton
	if (estado_actual == 1)
	{
		boton_bloqueado = 0;
	}

	estado_anterior = estado_actual;
}

/****************************************/
// Inicializacion de LEDs

void init_leds(void)
{
	// Configurar LEDs como salida
	DDRD |= (1 << led_m) | (1 << led_e) | (1 << led_u);

	// Apagar todos los LEDs
	PORTD &= ~((1 << led_m) | (1 << led_e) | (1 << led_u));
}

/****************************************/
// Encender LED segun modo

void led_modo(void)
{
	// Apagar todos
	PORTD &= ~((1 << led_m) | (1 << led_e) | (1 << led_u));

	// Modo manual
	if (modo == 0)
	{
		PORTD |= (1 << led_m);
	}

	// Modo EEPROM
	else if (modo == 1)
	{
		PORTD |= (1 << led_e);
	}

	// Modo UART/Adafruit
	else if (modo == 2)
	{
		PORTD |= (1 << led_u);
	}
}

/****************************************/
// Guardar presets en EEPROM

void guardar_e(void)
{
	static uint8_t estado_anterior = 1;
	static uint8_t boton_bloqueado = 0;

	uint8_t estado_actual = (PIND & (1 << boton_guardar)) ? 1 : 0;

	// Detectar pulsacion
	if (estado_actual == 0 && estado_anterior == 1 && boton_bloqueado == 0)
	{
		_delay_ms(30);

		if (!(PIND & (1 << boton_guardar)))
		{
			// Guardar angulos actuales
			writeEEPROM((preset_actual * 4), a_servo1);
			writeEEPROM((preset_actual * 4) + 1, a_servo2);
			writeEEPROM((preset_actual * 4) + 2, a_servo3);
			writeEEPROM((preset_actual * 4) + 3, a_servo4);

			writeString("Preset guardado\r\n");

			// Pasar al siguiente preset
			preset_actual++;

			// Sobreescribir circularmente
			if (preset_actual > 3)
			{
				preset_actual = 0;
			}

			boton_bloqueado = 1;
		}
	}

	// Liberar boton
	if (estado_actual == 1)
	{
		boton_bloqueado = 0;
	}

	estado_anterior = estado_actual;
}

/****************************************/
// Leer presets desde EEPROM

void leer_e(void)
{
	uint8_t direccion_base;

	// Seleccionar direccion base
	direccion_base = preset_uart * 4;

	// Leer angulos guardados
	a_servo1 = readEEPROM(direccion_base);
	a_servo2 = readEEPROM(direccion_base + 1);
	a_servo3 = readEEPROM(direccion_base + 2);
	a_servo4 = readEEPROM(direccion_base + 3);

	// Actualizar servos
	Servo1A_SetAngle(a_servo1);
	Servo1B_SetAngle(a_servo2);
	Servo2A_SetAngle(a_servo3);
	Servo2B_SetAngle(a_servo4);
}

/****************************************/
// Seleccionar presets mediante UART

void uart_preset(void)
{
	char rx;

	// Verificar si llego un dato UART
	if (UCSR0A & (1 << RXC0))
	{
		rx = UDR0;

		// Ignorar enter
		if (rx == '\r' || rx == '\n')
		{
			return;
		}

		writeString("Dato recibido: ");
		writeChar(rx);
		writeString("\r\n");

		// Seleccionar preset
		if (rx == '1')
		{
			preset_uart = 0;
		}
		else if (rx == '2')
		{
			preset_uart = 1;
		}
		else if (rx == '3')
		{
			preset_uart = 2;
		}
		else if (rx == '4')
		{
			preset_uart = 3;
		}
		else
		{
			writeString("Preset invalido\r\n");
			mostrar_angulos();
			return;
		}

		// Cargar preset
		leer_e();

		// Mostrar valores
		mostrar_angulos();
	}
}

/****************************************/
// Menu UART EEPROM

void menu_uart(void)
{
	writeString("\r\n");
	writeString("=== CONTROL UART ===\r\n");
	writeString("Enviar:\r\n");
	writeString("1 -> Preset 1\r\n");
	writeString("2 -> Preset 2\r\n");
	writeString("3 -> Preset 3\r\n");
	writeString("4 -> Preset 4\r\n");
	writeString("\r\n");
}

/****************************************/
// Mostrar angulos actuales

void mostrar_angulos(void)
{
	char buffer[10];

	writeString("\r\n");
	writeString("Angulos actuales:\r\n");

	// sprintf() convierte el numero entero a texto
	sprintf(buffer, "%d", a_servo1);
	writeString("Servo 1: ");
	writeString(buffer);
	writeString("\r\n");

	sprintf(buffer, "%d", a_servo2);
	writeString("Servo 2: ");
	writeString(buffer);
	writeString("\r\n");

	sprintf(buffer, "%d", a_servo3);
	writeString("Servo 3: ");
	writeString(buffer);
	writeString("\r\n");

	sprintf(buffer, "%d", a_servo4);
	writeString("Servo 4: ");
	writeString(buffer);
	writeString("\r\n\r\n");
}

/****************************************/
// Control UART desde Adafruit IO

void uart_adafruit(void)
{
	static char buffer[5];
	static uint8_t index = 0;

	char rx;
	uint8_t angulo;

	// Verificar si llego dato UART
	if (UCSR0A & (1 << RXC0))
	{
		rx = UDR0;

		// Mostrar dato recibido
		writeChar(rx);

		/****************************************/
		// Fin del comando

		if (rx == '\n')
		{
			buffer[index] = '\0';

			// atoi() convierte el texto recibido a numero entero
			angulo = atoi(&buffer[1]);

			/****************************************/
			// SERVO 1

			if (buffer[0] == 'A')
			{
				a_servo1 = angulo;

				Servo1A_SetAngle(a_servo1);

			}

			/****************************************/
			// SERVO 2

			else if (buffer[0] == 'B')
			{
				a_servo2 = angulo;

				Servo1B_SetAngle(a_servo2);

			}

			/****************************************/
			// SERVO 3

			else if (buffer[0] == 'C')
			{
				a_servo3 = angulo;

				Servo2A_SetAngle(a_servo3);

			}

			/****************************************/
			// SERVO 4

			else if (buffer[0] == 'D')
			{
				a_servo4 = angulo;

				Servo2B_SetAngle(a_servo4);

			}

			// Reiniciar buffer
			index = 0;
		}

		/****************************************/
		// Guardar caracteres recibidos

		else
		{
			if (rx != '\r')
			{
				buffer[index] = rx;

				index++;

				// Evitar overflow
				if (index >= 5)
				{
					index = 0;
				}
			}
		}
	}
}

/****************************************/
// Interrupt routines