# ADS131A0X

## Description
This repository showcases the drivers for an Analog-Digital Converter (ADC) and how it interfaces with a Field Programmable Gate Array (FPGA)

## Project Details 
- FPGA Model:   10CL040YF484C8G
- ADC Model:    ADS131A04
- Communication Protocol: Serial Peripheral Interface (SPI) without manual CS 

## Tags 
v1.0.0 - 0xff04 response received from SLAVE. Incorrect response when 0x0655 was sent to SLAVE. 
v1.0.1 - 0xff04 & 0x0655 received from SLAVE. Communication protocol with FPGA is now successfully established. Next: ADC Data Conversion.

## Author 
Dennis Wong Guan Ming