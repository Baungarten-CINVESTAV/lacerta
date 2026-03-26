<p align="center">
  <img src="documentation_mkdoc/docs/img/Logo_Black_background_white.svg" alt="Mifral logo" width="220">
</p>

# Lacerta: Open Hardware Interface Engine for Embedded Systems

![Lacerta logo](documentation_mkdoc/docs/img/Lacerta2.png)

## Project Overview

**Lacerta** is an open-source hardware platform that enables the rapid creation of graphical interfaces for embedded systems using custom silicon.

**The whole documentation can be found** [**here**](https://baungarten-cinvestav.github.io/lacerta/).

The system allows developers to design graphical interfaces using a graphical configuration tool and deploy them directly to hardware implemented in a custom ASIC integrated with the Caravel SoC platform. The hardware renders the interface in real time and outputs the result through a VGA display.

The generated interface may include visual components such as:

- Buttons
- Horizontal and vertical bars
- Numeric indicators
- Status indicators
<p align="center">
<img src="documentation_mkdoc/docs/img/sample_icons.jpg">
</p>
<p align="center">
<b>Figure 1.</b> Examples of graphical components supported by Lacerta, including buttons, horizontal and vertical bars, numeric indicators, and status indicators used to visualize real-time system data.
</p>

The ASIC receives input data from sensors, external microcontrollers, or other embedded systems and dynamically updates the graphical elements according to the incoming data stream. Both analog and digital signals can be connected to the Lacerta platform through appropriate interface circuitry or external converters, enabling the visualization of a wide range of real-world signals. This allows physical measurements such as temperature, voltage, speed, or system status signals to be directly represented through graphical components including bars, indicators, and numeric displays.

<p align="center">
<img src="documentation_mkdoc/docs/img/flow1.drawio.svg">
</p>
<p align="center">
<b>Figure 2.</b> Lacerta system concept: heterogeneous input signals are processed by the Lacerta ASIC to generate the custom graphical HMI displayed on a monitor.
</p>

The goal of Lacerta is to provide a low-cost, fully open-source reference architecture for embedded human–machine interfaces (HMI). By combining configurable hardware graphics generation with flexible input interfaces, Lacerta enables the rapid development of customizable dashboards and monitoring systems for industrial, commercial, and edge-IoT applications.

<p align="center">
<img src="documentation_mkdoc/docs/img/Flow_interface.drawio.svg">
</p>
<p align="center">
<b>Figure 4.</b> Lacerta interface creation workflow. A graphical editor is used to design custom interface layouts, which are translated into configuration data interpreted by the Lacerta hardware engine to generate the graphical display.
</p>

<p align="center">
<img src="documentation_mkdoc/docs/img/lacerta_blockd2-caravel.drawio.svg">
</p>
<p align="center">
<b>Figure 5.</b> Block diagram of the Lacerta ASIC inside the Caravel environment. The figure shows how a host computer or the embedded Caravel RISC-V processor sends commands through UART and Wishbone interfaces to the command arbiter, rendering logic, and memory subsystem; the updated frame data is then read by the VGA controller to drive the screen.
</p>

## Open and Reproducible Architecture

Lacerta is designed as a **fully open-source reference architecture**. The project includes all required design artifacts to reproduce the system, including:

- [Documentation](https://baungarten-cinvestav.github.io/lacerta/)
- [RTL source code for the ASIC implementation](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/verilog/rtl)
- [Librelane physical design flow integration](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/openlane)  
<!--- [Verification testbenches]()  -->
- [PCB design files](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/PCB)
- [Firmware examples](https://github.com/chipfoundry/caravel_board)  
- [Interface design tools](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/Interface_Design_Software)

### Lacerta Interface Design Software — GUI Notes

Important:
- The prebuilt GUI in this repository is currently distributed as a Windows executable package and can only be run on **Windows**.
- Before running the GUI, you must extract the files located in `Interface_Design_Software/exe_file_GUI` (the RAR parts). Ensure all parts are in the same directory and extract them with a tool such as 7-Zip or WinRAR.

Quick steps
1. Copy the folder [Interface_Design_Software/exe_file_GUI](https://github.com/Baungarten-CINVESTAV/lacerta/tree/main/Interface_Design_Software/exe_file_GUI) to a Windows machine (or access it from Windows).
2. Extract/unpack all archive parts (e.g. LacertaHMIDesigner.part1.rar, part2, part3) into a single directory.
3. Run the extracted installer or executable on Windows.

