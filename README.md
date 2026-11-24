# UART Loopback with FIFO Buffer in SystemVerilog

A synthesizable **UART (8N1) transceiver with a 64-byte FIFO buffer**, written in SystemVerilog for FPGA targets. Bytes received on the `rx` pin are buffered in a FIFO, then read back out, **echoed on the `tx` pin**, and shown on 8 LEDs.

## Highlights

- **UART receiver and transmitter** in 8N1 format (1 start bit, 8 data bits, no parity, 1 stop bit), LSB first.
- **16x oversampling**: the start bit is validated at its midpoint and each data bit is sampled at the middle of the bit period, which improves noise immunity.
- **Synchronous 64 x 8-bit FIFO** using 7-bit read/write pointers, where the extra MSB distinguishes the full and empty states.
- **FSM-based design**: the receiver and transmitter are each implemented as finite state machines.
- **Clock-enable style timing**: a single `tick` strobe (one pulse every 163 clock cycles) drives both RX and TX timing.
- Asynchronous, active-high reset.
- Modular, hierarchical design with a clear top-level integration.

## Skills Demonstrated

RTL design in SystemVerilog, finite state machine design, serial communication protocols (UART), FIFO and pointer-based flow control, clock division and baud-rate generation, and module integration for FPGA.

## System Architecture

```
                 ┌──────────────────────────── top ────────────────────────────┐
                 │                                                             │
   rx ──────────►│  ┌─────────────────────┐  data[7:0]   ┌──────────────┐ dt    │
                 │  │ control (UART RX)   ├─────────────►│ fifo 64x8    ├──┬───►│──► led[7:0]
                 │  │  ┌─────┐            │  w (write)   │              │  │    │
                 │  │  │ tik │──► tick ───┼──┐           │              │  │    │
                 │  │  └─────┘            ├─────────────►│              │  │    │
                 │  └─────────────────────┘              └──────▲───────┘  │    │
                 │                                    r (read)  │ empty    │    │
                 │                                       ┌──────┴───────┐  │    │
                 │                      tick ───────────►│ UART TX (FSM)│◄─┘    │
                 │                                       └──────┬───────┘       │
                 └──────────────────────────────────────────────┼───────────────┘
                                                                ▼
                                                               tx
```

**Data flow**

1. A host (e.g. a PC) sends a byte to the `rx` pin.
2. `control` decodes the byte and raises the write strobe `w`.
3. `fifo` stores the byte.
4. `top` detects that the FIFO is not empty, reads the byte, and displays it on `led`.
5. `top` transmits the same byte back on `tx` (echo).

## Repository Structure

| File | Modules | Description |
|------|---------|-------------|
| `controldesign.sv` | `tik`, `control` | `tik`: tick generator for baud timing. `control`: UART receiver FSM that outputs the received byte and a write strobe. |
| `fifodesign.sv` | `fifo` | 64 x 8-bit FIFO with an empty flag. |
| `top.sv` | `top` | Top-level module: connects the receiver and FIFO, and contains the UART transmitter FSM and LED output. |

> Note: `design.sv` in the working folder duplicates `controldesign.sv`, so only one of them should be included in a project.

## Module Details

### `tik`: Baud Tick Generator

A 26-bit counter counts from 0 to 162 and produces a one-cycle `tick` pulse, giving **one tick every 163 clock cycles**. Each UART bit lasts 16 ticks:

```
Bit period = 163 x 16 = 2608 clock cycles
Baud rate  = f_clk / 2608
```

| Clock | Resulting baud rate | Nearest standard rate |
|-------|---------------------|-----------------------|
| 50 MHz  | ~19,171 | 19,200 (~0.15% error) |
| 100 MHz | ~38,343 | 38,400 (~0.15% error) |

To target another clock or baud rate, use `N = f_clk / (baud x 16)` and adjust the compare value (`162` = N - 1).

### `control`: UART Receiver

| State | Behavior |
|-------|----------|
| `ide` | Waits for `rx` to go low (start bit) and counts about 8 to 9 ticks to reach the middle of the start bit. If `rx` returns high, the counter is cleared (glitch rejection). |
| `start` | Samples `rx` every 16 ticks and shifts each bit into `data` (LSB first), for 8 bits. |
| `stop` | Waits 16 ticks for the stop bit, pulses `w` for one cycle to signal a valid byte, then returns to `ide`. |

### `fifo`: 64-Byte Buffer

- Memory array of 64 x 8 bits.
- 7-bit read pointer `rd` and write pointer `wr` (6 low bits are the address, the MSB is a wrap-around flag):
  - `empty = (rd == wr)`
  - `full  = (rd[5:0] == wr[5:0]) && (rd[6] != wr[6])`
- Writes occur when `w` is high and the FIFO is not full. Reads occur when `r` is high and the FIFO is not empty. Read data appears on `dt` one clock cycle later.

### `top`: Integration and UART Transmitter

| Step | Action |
|------|--------|
| `0` | If the FIFO is not empty, assert read strobe `r` and move to step 1. |
| `1` | Wait one cycle for FIFO data to become valid on `dt`. |
| `2` | Drive `led` with `dt` and run the transmit FSM: start bit, 8 data bits (LSB first), stop bit. Then return to step 0. |

The `tx` output is driven only while `tx_ena` is high and is otherwise high-impedance.

## Ports

| Module | Inputs | Outputs |
|--------|--------|---------|
| `top` | `clk`, `rst`, `rx` | `tx`, `led[7:0]` |
| `control` | `clk`, `rst`, `rx` | `data[7:0]`, `tick`, `w` |
| `fifo` | `clk`, `rst`, `data[7:0]`, `w`, `r` | `dt[7:0]`, `fifo_empty` |

## Getting Started

### Simulation

Any SystemVerilog-capable simulator works (Verilator, Icarus Verilog with `-g2012`, ModelSim/Questa, Vivado Simulator). Example with Icarus Verilog and your own testbench `tb.sv`:

```bash
iverilog -g2012 -o sim tb.sv top.sv controldesign.sv fifodesign.sv
vvp sim
```

### FPGA

1. Create a project in your vendor tool (Vivado, Quartus, etc.) and add `top.sv`, `controldesign.sv`, and `fifodesign.sv`. Set `top` as the top-level module.
2. Assign pins for `clk`, `rst`, `rx`, `tx`, and `led[7:0]` according to your board.
3. Check that the divider value in `tik` matches your board clock (see the baud table above).
4. Program the board, open a serial terminal set to **8 data bits, no parity, 1 stop bit** at the matching baud rate, and type characters. They will be echoed back and their ASCII codes shown on the LEDs.

## Future Improvements

- Add a self-checking testbench.
- Parameterize the baud divider and FIFO depth.
- Add framing-error detection and `full` / overflow status outputs.
- Drive `tx` high when idle (standard UART idle level) instead of high-impedance.
- Optional parity bit support.

## License

Add a license of your choice (for example MIT) as a `LICENSE` file in the repository.
