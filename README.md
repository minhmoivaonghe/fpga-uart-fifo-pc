# FPGA UART Echo with FIFO Buffer

A SystemVerilog implementation of a **UART** link between a PC and an FPGA. Bytes sent from the PC are received by a hardware UART receiver, buffered in a **64-byte FIFO**, shown on **8 LEDs**, and transmitted back to the PC unchanged (echo). Implemented on an Intel/Altera **Cyclone IV EP4CE6** FPGA.

## Demo

`in folder docs`

## How It Works

1. The PC sends a byte through a serial terminal.
2. The **receiver** detects the start bit, samples 8 data bits (LSB first) at the middle of each bit, and pulses a write signal when the byte is complete.
3. The byte is pushed into the **FIFO**.
4. The **transmitter FSM** pops bytes from the FIFO, drives the value onto the LEDs, and sends it back to the PC as a UART frame.
5. The terminal shows exactly what was typed, confirming two-way communication.

## Architecture

```
                 +----------------------------- FPGA -----------------------------+
                 |                                                                |
PC --TX--> rx -> | control (UART RX) --> fifo (64 x 8) --> TX FSM (top) --> tx    | --RX--> PC
                 |      ^                                    |                    |
                 |   tik (baud tick) -------------------------+--> led[7:0]        |
                 +----------------------------------------------------------------+
```

| Module | File | Role |
|--------|------|------|
| `tik` | `controldesign.sv` | Baud-rate tick generator; one tick every 163 clock cycles (16x oversampling) |
| `control` | `controldesign.sv` | UART receiver FSM (idle / data / stop), mid-bit sampling, outputs received byte and write strobe |
| `fifo` | `fifodesign.sv` | 64-entry x 8-bit synchronous FIFO with 7-bit pointers, full and empty detection |
| `top` | `top.sv` | Top level: connects receiver and FIFO, transmit FSM, LED output |

## UART Configuration

- Frame format: **8N1** (8 data bits, no parity, 1 stop bit), LSB first
- Oversampling: 16x
- Baud rate: `f_clk / (163 x 16)`, which gives about **19200 baud** with a 50 MHz clock

To change the baud rate, change the divider value (`162`) in the `tik` module.

## Hardware

| Item | Description |
|------|-------------|
| FPGA board | Intel/Altera Cyclone IV EP4CE6, 50 MHz clock |
| PC link | USB-to-UART adapter (3.3 V logic) |
| Output | 8 LEDs showing the last transmitted byte |
| Tool | Quartus II |

## Project Structure

```
fpga-uart-fifo-pc/
├── src/
│   ├── top.sv             # Top level
│   ├── controldesign.sv   # Baud tick generator + UART receiver
│   └── fifodesign.sv      # 64 x 8 FIFO
├── sim/
│   └── testbench          # Simulation testbench
├── docs/                  # Demo video, photos, waveforms
└── README.md
```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/minhmoivaonghe/fpga-uart-fifo-pc.git
   ```
2. In Quartus II, create a project for **EP4CE6** and add all files in `src/`.
3. Set **`top`** as the top-level entity.
4. Assign pins:

   | Signal | Description |
   |--------|-------------|
   | `clk` | 50 MHz board clock |
   | `rst` | Reset (active high) |
   | `rx` | Connect to the adapter TX pin |
   | `tx` | Connect to the adapter RX pin |
   | `led[7:0]` | 8 LEDs |
5. Compile and program the FPGA, and connect the adapter (share ground).
6. Open a serial terminal (PuTTY, Tera Term) at **19200 baud, 8N1, no flow control**.
7. Type characters: each one is echoed back and its ASCII code appears on the LEDs.

## Simulation

Run the testbench in `sim/` with ModelSim/Questa to check the receiver, FIFO and transmitter behaviour.

## Limitations

- Fixed baud rate set at design time
- No parity and no stop-bit (framing) error detection
- If the FIFO is full, newly received bytes are dropped

## Author

**Do Thanh Minh** - Electrical/Electronic Engineering student, Industrial University of Ho Chi Minh City (IUH)
Interested in FPGA design and Design Verification.
GitHub: [@minhmoivaonghe](https://github.com/minhmoivaonghe)
