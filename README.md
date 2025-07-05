# Green-Guard
## FPGA & LSTM-Driven Smart Irrigation System

**EECS 3216 Digital Systems Engineering - Final Project**

This project implements an intelligent home automation system for plant care, integrating environmental sensing, hardware control, and a machine learning model for optimal watering recommendations, displayed via a custom VGA output on an FPGA.

## Table of Contents

1.  [Project Overview](#project-overview)
2.  [Demo](#demo)
3.  [Goals and Rationale](#goals-and-rationale)
4.  [System Architecture](#system-architecture)
5.  [Hardware Components](#hardware-components)
6.  [Software and AI Model](#software-and-ai-model)
7.  [Experimentation and Results](#experimentation-and-results)
8.  [Challenges Encountered](#challenges-encountered)
9. [Getting Started](#getting-started)
10. [Group Members](#group-members)
11. [License](#license)

## Project Overview

**Green-Guard** is a real-time embedded system designed to automate plant care by monitoring environmental conditions (soil moisture, humidity), controlling actuators (water pump, fan), and providing visual feedback. A key innovation is the integration of a machine learning model to analyze historical data and recommend optimal environmental conditions to improve plant health. The system leverages a hybrid architecture combining a Raspberry Pi Pico microcontroller for sensing and control with a DE10-Lite FPGA for real-time VGA display of sensor data.

## Demo

Check out a demonstration of the system in action:
https://www.youtube.com/watch?v=Yn1OlFF0FPE

## Goals and Rationale

The primary goal is to design and implement an intelligent system that provides personalized care for plants, enhancing health and reducing risks of over/under-watering.

The rationale is rooted in addressing challenges in:
*   **Agricultural Applications:** Managing environmental variability and stress on crops.
*   **Conservation:** Providing tailored care for sensitive and exotic plant species (like the ghost orchid).
*   **Home Gardening:** Empowering urban dwellers and hobbyists with automated, consistent, and water-efficient plant care.

Engineering goals include contributing to **Biodiversity Preservation** by supporting diverse plant types and promoting **Environmental Sustainability** through water conservation.

## System Architecture

The system employs a **dual-controller architecture** for modularity and leveraging the strengths of different platforms:

1.  **Raspberry Pi Pico:** Acts as the sensing and control hub. It interfaces with sensors (DHT11, soil moisture), processes readings, implements threshold-based control logic for actuators (water pump, fan), and encodes sensor data into a binary format for the FPGA.
2.  **DE10-Lite FPGA:** Handles the visual feedback. It receives binary sensor data from the Pico via GPIO, decodes it, converts it to BCD format, and renders real-time humidity and moisture values as 7-segment digits on a standard VGA monitor.

Communication between the Pico and DE10-Lite is achieved using **parallel binary GPIO**, providing a fast and lightweight data path.

## Hardware Components

*   **Raspberry Pi Pico:** Microcontroller for sensor reading and actuator control.
*   **Intel DE10-Lite:** FPGA for VGA display output.
*   **DHT11 Sensor:** Measures ambient humidity and temperature.
*   **Analog Soil Moisture Sensor:** Measures water content in soil (outputs analog voltage).
*   **5v Relay Module:** Controls the water pump.
*   **MOSFET Switch:** Optionally controls a cooling fan for humidity regulation.
*   **Small Water Pump:** Delivers water to the plant.
*   **Breadboard, Jumpers, Power Supplies:** For system assembly and power distribution.

## Software and AI Model

*   **Raspberry Pi Pico Firmware:** Written in Arduino-style C++ using the Arduino IDE. Manages sensor readings, implements control logic based on predefined thresholds, and encodes data for FPGA transmission.
*   **DE10-Lite FPGA Logic:** Developed in Verilog using Intel Quartus Prime. Decodes incoming binary GPIO data, performs BCD conversion, and generates VGA signals to display sensor values. Includes custom logic for rendering 7-segment digits.
*   **AI Model (Python):** A time series forecasting model built using TensorFlow/Keras.
    *   **Architecture:** Long Short-Term Memory (LSTM) network.
    *   **Input Features:** Moisture, Humidity, Watering levels from historical data.
    *   **Target:** Predicted Plant Health score.
    *   **Training Data:** Concatenated data from five distinct environmental scenarios (collected over 14-day cycles on an orchid).
    *   **Preprocessing:** MinMaxScaler for normalization, sliding window approach for sequence creation.
    *   **Optimization Strategy:** Randomized search to find environmental conditions (Moisture, Humidity, Watering amount) that maximize the predicted plant health for the next day.

The AI model is separate from the real-time embedded system but is intended to provide recommendations for optimizing system thresholds or future iterations.

## Experimentation and Results

The system was tested under various conditions (different soil moisture levels, simulated humidity).

Key findings:
*   The soil moisture threshold ( `< 20000` ADC) and humidity threshold ( `> 60%` ) effectively triggered the water pump and fan, respectively.
*   Real-time environmental feedback was successfully displayed on the VGA monitor via the DE10-Lite, with minimal perceived latency despite the Pico's 2-second update rate.
*   The parallel binary GPIO communication scheme proved functional for the data transfer, enabling real-time display.
*   The system demonstrated reliable closed-loop sensing and actuation based on the defined thresholds.

![image](https://github.com/user-attachments/assets/b67084c9-0c75-466d-93b7-ce8931fdd821)
![image](https://github.com/user-attachments/assets/87845ae4-5fc2-467e-bbf5-d9071eaccfa8)

## Challenges Encountered

During development, several challenges were faced:
*   **Unstable GPIO Data Transfer:** Inconsistent connections via breadboard jumpers sometimes caused brief flickering on the VGA display.
*   **Timing Mismatch:** The difference between the Pico's sensor update rate (2s) and the VGA refresh rate (60Hz) occasionally caused temporary visual glitches during data transitions.
*   **Voltage and Power Issues:** Powering high-current actuators from the same rail as logic components caused voltage dips, requiring mitigation with capacitors, flyback diodes, and a separate power source for the pump.
*   **Moisture Sensor Inconsistency:** Sensor readings were sensitive to soil type and environmental noise, necessitating the use of a buffered threshold.

Most of these challenges were addressed through hardware adjustments and minor logic refinements.

## Getting Started

To replicate this project, you will need the hardware listed above and the corresponding software environments:
*   Arduino IDE (for Pico code)
*   Intel Quartus Prime (for DE10-Lite Verilog code)
*   Python with necessary libraries (TensorFlow, Keras, scikit-learn, pandas, numpy, matplotlib) for the AI model.

The final code for the Pico (Arduino C++), DE10-Lite (Verilog), and the AI Model (Python) are available in this repository, in dedicated folders (e.g., `Verilog`, `Arduino`, `ML`). Refer to the code comments and the project documentation for detailed setup and usage instructions.

## Group Members

*   Svastik Sharma (217997081)
*   Ahmed Abdulahi (218407635)
*   Sathira Williams (218131938)
*   Yaroslava Samokhina (217316217)

## License
This project is licensed under the [Apache-2.0 license](LICENSE).

