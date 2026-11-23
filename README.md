# Multifunction Stopwatch / Timer with VGA Display

**Course:** Systèmes Programmables VHDL, EPITA
**Authors:** Hugo Frangiamone, Abdoulaye Kone, Amanda Lassel
**Target:** Terasic DE10-Lite (Intel MAX 10 `10M50DAF484C7G`), 50 MHz clock (`MAX10_CLK1_50`)

---

## 1. Overview

This project implements a stopwatch / countdown timer in VHDL, controlled by a finite-state machine (FSM). Time is shown in `MM:SS:CC` format on six 7-segment displays, and a VGA output (640×480 @ 60 Hz) shows a background colour that reflects the FSM state, together with a progress bar driven by the hundredths of a second.

## 2. User Interface

| Resource | Function |
|---|---|
| `KEY(0)` | Asynchronous reset, active low |
| `KEY(1)` | Start / Pause / Restart (cycles between RUN and PAUSE) |
| `SW(0)` | Mode: `0` = stopwatch (count up), `1` = timer (count down) |
| `SW(9 downto 1)` | Timer reload value, in seconds (0–511) |
| `HEX5 … HEX0` | Time display `MM:SS:CC` |
| `LEDR(0)` | Mode indicator (mirrors `SW(0)`) |
| `LEDR(1)` | RUN state indicator |
| `LEDR(9 downto 2)` | LED chaser (one step every 125 ms while running) |
| VGA (4-bit R-2R DAC per colour) | State background and progress bar |

**VGA behaviour**

| State | Background | RGB (4 bits/channel) | Progress bar |
|---|---|---|---|
| STOP | Blue | `0x0, 0x0, 0xF` | Hidden |
| RUN | Green | `0x0, 0xF, 0x0` | White, lines 401–439, 6 px per hundredth (0 → 594 px) |
| PAUSE | Red | `0xF, 0x0, 0x0` | White, frozen at the width reached on entering PAUSE |

## 3. Architecture

```
                         ┌────────────┐   KeyPulse   ┌──────────┐
 KEY(1) ────────────────►│ key_pulse  ├─────────────►│ fsm_ctrl │
                         └────────────┘              └─┬──┬──┬──┘
                                       Running ────────┘  │  └──── VGA(2:0) ─────┐
                                       LoadTimer ─────────┘                      │
                                          │                                      ▼
 ┌─────────────┐ Tick100 ┌──────────────┐ │                              ┌─────────────┐
 │ tick_100hz  ├────────►│ time_counter │◄┘                              │  vga_ctrl   │──► VGA R/G/B/HS/VS
 └─────────────┘         └──┬───────────┘  centiseconds ────────────────►└──────▲──────┘
  SW(0), SW(9:1) ──────────►│ Min / Sec / Cs                                   │ clk_25
                            ▼                                            ┌─────┴─────┐
                  ┌────────────────────┐                                 │  pll_25   │◄── 50 MHz
                  │ 6 × sevenseg_decoder│──► HEX5…HEX0                   └───────────┘
                  └────────────────────┘
 Running, LoadTimer ──► led_chaser ──► LEDR(9:2)
```

| Module | File | Role |
|---|---|---|
| `stopwatch` | `stopwatch.vhd` | Top level: instantiation, BCD digit separation, output mapping |
| `key_pulse` | `key_pulse.vhd` | Rising-edge detector: one clock-wide pulse per key press |
| `fsm_ctrl` | `fsm_ctrl.vhd` | Control FSM (STOP / RUN / PAUSE), Moore outputs |
| `tick_100hz` | `tick_100hz.vhd` | 100 Hz enable pulse from the 50 MHz clock (divider by 500 000) |
| `time_counter` | `time_counter.vhd` | Up/down counter (minutes, seconds, hundredths) and timer reload |
| `sevenseg_decoder` | `sevenseg_decoder.vhd` | Digit (0–9) to 7-segment pattern (active low) |
| `led_chaser` | `led_chaser.vhd` | Chaser pattern advancing every 125 ms (6 250 000 cycles) |
| `vga_ctrl` | `vga.vhd` | 640×480 @ 60 Hz timing, state colours, progress bar |
| `pll_25` | _generated IP_ | ALTPLL, 50 MHz → 25 MHz pixel clock |

### Control FSM

```
            KEY1 pulse               KEY1 pulse
   ┌──────┐ ──────────► ┌─────┐ ──────────► ┌───────┐
   │ STOP │             │ RUN │             │ PAUSE │
   └──────┘             └──┬──┘ ◄────────── └───┬───┘
       ▲                   │     KEY1 pulse     │
       └──── KEY(0) reset (from any state) ─────┘
```

| State | `Running` | `LoadTimer` | `VGA` | `Bar` |
|---|---|---|---|---|
| STOP | 0 | 1 | `001` | `00` |
| RUN | 1 | 0 | `010` | `01` |
| PAUSE | 0 | 0 | `100` | `10` |

STOP is entered only through the reset. In timer mode, `LoadTimer` loads `SW(9:1)` into the counter while the FSM is in STOP.

### Counter behaviour

- **Stopwatch:** counts 00:00:00 → 99:59:99, then wraps to zero.
- **Timer:** loads `SW(9:1)` seconds, counts down, and stops at 00:00:00.
- Counting advances only when `Running = 1` and `Tick100 = 1`.

## 4. Constraints and Timing

- **Pin assignment:** `pinout.csv` (signal, pin, I/O standard) applied by `pin_assign.tcl`; `pins.tcl` holds the VGA assignments.
- **Timing (`sta.sdc`):**
  - `clk_50`: 20 ns period on `MAX10_CLK1_50`.
  - `clk_25`: generated clock (÷2) for the pixel clock, declared asynchronous to `clk_50`.
  - False paths on the inputs (`KEY`, `SW`) and on the slow outputs (`LEDR`, `HEX`).

## 5. Verification

### Simulation
- `tb_stopwatch.vhd`: system-level test in timer mode (reload of 60 s, STOP → RUN → PAUSE → RUN, final reset). `TICK_MAX_COUNT` is reduced to 4 to shorten the simulation.
- `tb_fsm_ctrl.vhd`: FSM test bench.

### SignalTap II (`signal_tap.stp`)
- **Sampling clock:** `MAX10_CLK1_50`, depth 128 samples, circular buffer, pre-trigger position.
- **Trigger:** rising edge of `KeyPulse`.
- **Storage qualifier:** `Tick100` (transitional storage).
- **Observed signals:** `Running`, `KeyPulse`, `Tick100`, `Chaser[7:0]`, `Centiseconds[6:0]`, `Seconds[5:0]`.


## 7. Build and Programming

1. Create the Quartus project `Stopwatch` (top-level entity `stopwatch`, device `10M50DAF484C7G`).
2. Add all `.vhd` files (excluding the test benches) and `sta.sdc`; generate the `pll_25` ALTPLL IP (50 MHz → 25 MHz).
3. Apply the pin assignments: `quartus_sh -t pin_assign.tcl`, then source `pins.tcl`.
4. Compile the project.
5. Load the `.sof` into the FPGA SRAM with the Quartus Programmer (USB-Blaster).

