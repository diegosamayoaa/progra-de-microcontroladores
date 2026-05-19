# =========================================================
# Proyecto 2
# Diego Samayoa
# =========================================================

# Librerias
import sys
import time
import serial

from Adafruit_IO import MQTTClient

# =========================================================
# CONFIGURACION ADAFRUIT
# =========================================================

ADAFRUIT_IO_USERNAME = "-"
ADAFRUIT_IO_KEY = "-"

# =========================================================
# PUERTO SERIAL
# =========================================================

ser = serial.Serial('COM3', 9600)

time.sleep(2)

# =========================================================
# FEEDS
# =========================================================

# SEND (Sliders)
FEED_SERVO1_SEND = 'servo1-send'
FEED_SERVO2_SEND = 'servo2-send'
FEED_SERVO3_SEND = 'servo3-send'
FEED_SERVO4_SEND = 'servo4-send'

# READ (Gauges)
FEED_SERVO1_READ = 'servo1-read'
FEED_SERVO2_READ = 'servo2-read'
FEED_SERVO3_READ = 'servo3-read'
FEED_SERVO4_READ = 'servo4-read'

# =========================================================
# CALLBACKS MQTT
# =========================================================

def connected(client):

    print("Conectado a Adafruit IO")

    # Suscribirse a sliders
    client.subscribe(FEED_SERVO1_SEND)
    client.subscribe(FEED_SERVO2_SEND)
    client.subscribe(FEED_SERVO3_SEND)
    client.subscribe(FEED_SERVO4_SEND)

    print("Feeds suscritos correctamente")


def disconnected(client):

    print("Desconectado")
    sys.exit(1)


def message(client, feed_id, payload):

    print(f'\nFeed recibido: {feed_id}')
    print(f'Valor recibido: {payload}')

    # =====================================================
    # SERVO 1
    # =====================================================

    if feed_id == FEED_SERVO1_SEND:

        comando = f'A{payload}\n'

        print(comando)

        ser.write(comando.encode())

        client.publish(FEED_SERVO1_READ, payload)

        print(f'Enviado UART -> {comando}')

    # =====================================================
    # SERVO 2
    # =====================================================

    elif feed_id == FEED_SERVO2_SEND:

        comando = f'B{payload}\n'

        ser.write(comando.encode())

        client.publish(FEED_SERVO2_READ, payload)

        print(f'Enviado UART -> {comando}')

    # =====================================================
    # SERVO 3
    # =====================================================

    elif feed_id == FEED_SERVO3_SEND:

        comando = f'C{payload}\n'

        ser.write(comando.encode())

        client.publish(FEED_SERVO3_READ, payload)

        print(f'Enviado UART -> {comando}')

    # =====================================================
    # SERVO 4
    # =====================================================

    elif feed_id == FEED_SERVO4_SEND:

        comando = f'D{payload}\n'

        ser.write(comando.encode())

        client.publish(FEED_SERVO4_READ, payload)

        print(f'Enviado UART -> {comando}')


# =========================================================
# MQTT CLIENT
# =========================================================

client = MQTTClient(
    ADAFRUIT_IO_USERNAME,
    ADAFRUIT_IO_KEY
)

client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

# =========================================================
# CONECTAR
# =========================================================

print("Conectando a Adafruit IO...")

client.connect()

client.loop_background()

# =========================================================
# LOOP PRINCIPAL
# =========================================================

while True:

    print("Esperando datos...")

    time.sleep(3)