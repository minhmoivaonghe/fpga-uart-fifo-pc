# FPGA UART Echo with FIFO Buffer

A Verilog implementation of a **UART** communication link between a PC and an FPGA. Data sent from the PC is received by the FPGA, buffered in a **FIFO**, shown on **LEDs**, and transmitted back to the PC unchanged (echo). Implemented on an Intel/Altera **Cyclone IV EP4CE6** FPGA.

## Demo

[![Demo video](https://img.youtube.com/vi/YOUR_VIDEO_ID/maxresdefault.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

> Watch the full demo on YouTube: https://www.youtube.com/watch?v=YOUR_VIDEO_ID

## Overview

The PC sends bytes through a serial terminal. The FPGA receives each byte, stores it in a FIFO, displays the received value on LEDs, and sends the same data back to the PC. The terminal therefore shows exactly what was sent, which verifies correct two-way communication.

## Features

- UART receiver and transmitter (8N1)
- Synchronous FIFO to decouple the receive and transmit paths
- Control FSM coordinating receive, buffering and transmit
- LED output showing the last received data
- Self-checking testbench for simulation

## Hardware

| Item | Description |
|------|-------------|
| FPGA board | Intel/Altera Cyclone IV EP4CE6 |
| PC link | USB-to-UART adapter |
| Output | LEDs |
| Tool | Quartus II |

## System Architecture

```
PC --TX--> UART RX --> FIFO --> Control FSM --> UART TX --RX--> PC
                         |
                         +--> LEDs (received data)
```

## Project Structure

```
fpga-uart-fifo-pc/
├── src/        # Verilog sources: UART design, FIFO, control FSM, top level
├── sim/        # Testbench
├── docs/       # Block diagrams, waveforms, photos
└── README.md
```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/minhmoivaonghe/fpga-uart-fifo-pc.git
   ```
2. Open Quartus II and create a new project targeting **EP4CE6**.
3. Add all files from `src/` and set the top-level entity.
4. Assign pins for the clock, UART RX/TX and LEDs.
5. Compile and program the board.
6. Connect the USB-to-UART adapter, open a serial terminal (e.g. PuTTY, Tera Term) with the matching baud rate, 8 data bits, no parity, 1 stop bit.
7. Type characters: they are echoed back and shown on the LEDs.

## Simulation

Run the testbench in `sim/` with ModelSim/Questa to verify the UART and FIFO behaviour.

## Results

Every byte sent from the PC is returned unchanged and displayed on the LEDs. See the demo video above.

## Author

**Do Thanh Minh** — Electrical/Electronic Engineering student, Industrial University of Ho Chi Minh City (IUH)
Interested in FPGA design and Design Verification.
GitHub: [@minhmoivaonghe](https://github.com/minhmoivaonghe)
