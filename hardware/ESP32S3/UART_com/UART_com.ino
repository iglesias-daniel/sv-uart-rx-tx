/* -- By Daniel Iglesias (2025) --

El siguiente ejemplo fue implementado para demostrar el correcto funcionamiento del protocolo UART implementado 
en Verilog en una FPGA.

Pruebas:
 - Se ha enviado y recibido UART 9600 baudios SERIAL_8N1 con una ESP32S3. Con la siguiente conexión:

    ESP32S3 (Wireless Lite 2)              iCEBreaker V1.0e
            GND                                 GND
            17 (Tx)                            3 (Rx)
            18 (Rx)                            4 (Tx)

Este código se proporciona tal cual, sin garantías de ningún tipo. El autor no se hace responsable de errores, 
fallos, mal funcionamiento, pérdidas de datos ni de cualquier daño derivado de su uso.

*/

#include <HardwareSerial.h>

HardwareSerial SerialUART(1);

#define UART_TX 17
#define UART_RX 18

void setup(){
  Serial.begin(115200);
  SerialUART.begin(9600, SERIAL_8N1, UART_RX, UART_TX);
  Serial.println("ESP32-S3 UART Iniciado");
}

void loop(){

  // Recibe por UART -> USB
  if (SerialUART.available()) {
    char c = SerialUART.read();
    Serial.write(c);
  }

  // Recibe por USD -> UART
  if (Serial.available()) {
    char c = Serial.read();
    Serial.write(c);
  }

}