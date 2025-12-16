# sv-uart-rx-tx
Synchronous UART RX/TX core in Verilog with a configurable baud rate, start/stop bit handling, and shift-register–based serial communication. Includes a real hardware implementation and validation between an iCEBreaker FPGA and an ESP32-S3.

# How to use it

## Use only software

- You need `iverilog` and `gtkwave` installed to compile and view waveforms, respectively (if you want to run the code under `/src` and `/tb`).

```bash
sudo apt update
sudo apt install iverilog gtkwave
git clone https://github.com/iglesias-daniel/sv-uart-rx-tx
cd sv-uart-rx-tx
```

- To execute the testbench:

```bash
    //to complete
```

## Use on real hardware

- If you want to run this UART RX/TX design on real hardware, you can. The implementation was tested on an iCEBreaker v1.0e FPGA and communicates with a real ESP32-S3 (Heltec Wireless Stick Lite V3). You will need the following dependencies:

```bash
sudo apt update
sudo apt install yosys nextpnr-ice40 fpga-icestorm iverilog gtkwave make git
cd hardware/iCEBreaker
```

- You also need the `main.mk` file from the official iCEBreaker examples. You can copy it manually, write your own, or simply do:

```bash
    git clone https://github.com/icebreaker-fpga/icebreaker-verilog-examples.git
    mv icebreaker-verilog-examples/main.mk .
    rm -rf icebreaker-verilog-examples
```
- Make sure your FPGA is connected, then run:

```bash
    make
    make prog
```
- For the ESP32-S3 firmware, upload the code located in `hardware/ESP32S3/` to your MCU using the Arduino IDE.