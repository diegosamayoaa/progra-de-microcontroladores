/*
 * main.c
 *
 * Created: 13/4/26
 * Author: Diego Samayoa
 * Description: Contador de 8 bits, medidor de voltaje por medio de ADC y alarma
 */

/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>

/****************************************/
// Function prototypes
void setup(void);
uint8_t leer_boton(uint8_t pin);

void adc_init(void);
uint8_t adc_leer_8bits(void);

void mostrar_segmentos(uint8_t valor_hex);
void apagar_displays(void);
void multiplexar_displays(uint8_t valor);

/****************************************/
// Tabla de 7 segmentos
const uint8_t tabla_7seg[16] = {0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71};

/****************************************/
// Main Function
int main(void)
{
    uint8_t counter = 0;
	uint8_t adc_val = 0;

    setup();
	adc_init();
	
    PORTD = counter;

    while (1)
    {
        // incremento
        if (leer_boton(PB0))
        {
            counter++;
            PORTD = counter;

            // Esperar a que suelte el botón
            while (!(PINB & (1 << PB0)));
        }

        // decremento
        if (leer_boton(PB1))
        {
            counter--;
            PORTD = counter;

            // Esperar a que suelte el botón
            while (!(PINB & (1 << PB1)));
        }
		
		// ADC
		adc_val = adc_leer_8bits();
		multiplexar_displays(adc_val);
		
		//Alarma PC0
		
		if (adc_val >= counter)
		{
			PORTC |= (1 << PC0);   // encender LED
		}
		else
		{
			PORTC &= ~(1 << PC0);  // apagar LED
		}
    }
}

/****************************************/
// CONFIGURACIÓN INICIAL
void setup(void)
{
    // Desactivar USART 
    UCSR0B = 0x00;

    // PORTD como salidas
    DDRD = 0xFF;
    PORTD = 0x00;

    // PB0 y PB1 como entradas
    DDRB &= ~((1 << PB0) | (1 << PB1));
    PORTB |= (1 << PB0) | (1 << PB1);
	
	// PB2 - PB5 como salidas
	DDRB |= (1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5);
	PORTB &= ~((1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5));
	
	// PC1 - PC5 como salidas
	DDRC |= (1 << PC1) | (1 << PC2) | (1 << PC3) | (1 << PC4) | (1 << PC5);
	PORTC &= ~((1 << PC1) | (1 << PC2) | (1 << PC3));
	
	// PC0 como salida para la alarma en A0
	DDRC |= (1 << PC0);
	apagar_displays();
}

/****************************************/
// Lee botones (Se usa antirrebote fisico)
uint8_t leer_boton(uint8_t pin)
{
    if (!(PINB & (1 << pin)))
    {
        return 1;
    }
    return 0;
}

/****************************************/
// Interrupt routines

// -----------------------------
// INICIALIZACIÓN DEL ADC
// -----------------------------
void adc_init(void)
{
	ADMUX = 0;
	ADMUX |= (1 << REFS0);   // referencia AVcc
	ADMUX |= (1 << ADLAR);   // left adjust
	
	// ADC6 = 0110
	ADMUX |= (1 << MUX2) | (1 << MUX1);

	ADCSRB = 0x00;           // MUX5 = 0

	ADCSRA = 0;
	ADCSRA |= (1 << ADEN);   // habilitar ADC
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // prescaler 128
}

// -----------------------------
// LECTURA ADC DE 8 BITS
// Retorna ADCH (0 a 255)
// -----------------------------
uint8_t adc_leer_8bits(void)
{
	ADCSRA |= (1 << ADSC); // iniciar conversión

	while (ADCSRA & (1 << ADSC)); // esperar fin

	return ADCH;
}

// -----------------------------
// APAGAR LOS DOS DISPLAYS
// -----------------------------
void apagar_displays(void)
{
	PORTC |= (1 << PC4) | (1 << PC5);
}

// -----------------------------
// Mostrar digitos en hexadecimal
// -----------------------------
void mostrar_segmentos(uint8_t valor_hex)
{
	uint8_t patron = tabla_7seg[valor_hex];

	// Limpiar segmentos primero
	PORTB &= ~((1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5));
	PORTC &= ~((1 << PC1) | (1 << PC2) | (1 << PC3));

	//a en PB2
	if (patron & (1 << 0)) PORTB |= (1 << PB2);

	//b en PB3
	if (patron & (1 << 1)) PORTB |= (1 << PB3);

	//c en PB4
	if (patron & (1 << 2)) PORTB |= (1 << PB4);

	//d en PB5
	if (patron & (1 << 3)) PORTB |= (1 << PB5);

	//e en PC1
	if (patron & (1 << 4)) PORTC |= (1 << PC1);

	//f en PC2
	if (patron & (1 << 5)) PORTC |= (1 << PC2);

	//g en PC3
	if (patron & (1 << 6)) PORTC |= (1 << PC3);
}

// -----------------------------
//Multiplexado de ambos displays
// -----------------------------
void multiplexar_displays(uint8_t valor)
{
	uint8_t alto = (valor >> 4) & 0x0F;
	uint8_t bajo = valor & 0x0F;

	// Display izquierdo
	apagar_displays();
	mostrar_segmentos(alto);
	PORTC &= ~(1 << PC4); // encender izquierdo
	_delay_ms(3);

	// Display derecho
	apagar_displays();
	mostrar_segmentos(bajo);
	PORTC &= ~(1 << PC5); // encender derecho
	_delay_ms(3);

	apagar_displays();
}