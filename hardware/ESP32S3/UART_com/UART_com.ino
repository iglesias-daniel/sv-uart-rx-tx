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