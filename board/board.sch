EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:steve_parts
LIBS:crumpschemes
LIBS:board-cache
EELAYER 25 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 1 1
Title ""
Date "sam. 04 avril 2015"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text Notes 8450 600  0    60   ~ 0
Adafruit FeatherWing\n
$Comp
L VCC #PWR14
U 1 1 56D753B8
P 9700 750
F 0 "#PWR14" H 9700 600 50  0001 C CNN
F 1 "VCC" H 9700 900 50  0000 C CNN
F 2 "" H 9700 750 50  0000 C CNN
F 3 "" H 9700 750 50  0000 C CNN
	1    9700 750 
	1    0    0    -1  
$EndComp
$Comp
L CONN_01X12 JP3
U 1 1 56D754D1
P 9300 1800
F 0 "JP3" H 9300 2450 50  0000 C CNN
F 1 "PinHeader_01x12_2.54mm" V 9400 1800 50  0000 C CNN
F 2 "Adafruit_FeatherWing:Conn_PinHeader_1x12" H 9300 1800 50  0001 C CNN
F 3 "" H 9300 1800 50  0000 C CNN
	1    9300 1800
	1    0    0    -1  
$EndComp
$Comp
L CONN_01X16 JP1
U 1 1 56D755F3
P 10250 1650
F 0 "JP1" H 10250 800 50  0000 C CNN
F 1 "PinHeader_01x16_2.54mm" V 10350 1650 50  0000 C CNN
F 2 "Adafruit_FeatherWing:Conn_PinHeader_1x16" H 10250 1650 50  0001 C CNN
F 3 "" H 10250 1650 50  0000 C CNN
F 4 "_" H 10250 1650 60  0001 C CNN "Manf#"
F 5 "_" H 10250 1650 60  0001 C CNN "Manf"
F 6 "_" H 10250 1650 60  0001 C CNN "Optn"
	1    10250 1650
	1    0    0    1   
$EndComp
$Comp
L GND #PWR15
U 1 1 56D75A03
P 9700 2500
F 0 "#PWR15" H 9700 2250 50  0001 C CNN
F 1 "GND" H 9700 2350 50  0000 C CNN
F 2 "" H 9700 2500 50  0000 C CNN
F 3 "" H 9700 2500 50  0000 C CNN
	1    9700 2500
	1    0    0    -1  
$EndComp
Text Label 10050 900  2    60   ~ 0
~RESET
Text Label 10050 1100 2    60   ~ 0
AREF
Text Label 10050 1300 2    60   ~ 0
A0
Text Label 10050 1400 2    60   ~ 0
A1
Text Label 10050 1500 2    60   ~ 0
A2
Text Label 10050 1600 2    60   ~ 0
A3
Text Label 10050 1800 2    60   ~ 0
A5
Text Label 10050 1900 2    60   ~ 0
SCK
Text Label 10050 2000 2    60   ~ 0
MOSI
Text Label 10050 2100 2    60   ~ 0
MISO
Text Label 10050 2200 2    60   ~ 0
D0
Text Label 10050 2300 2    60   ~ 0
D1
Text Label 10050 1700 2    60   ~ 0
A4
Text Label 9100 1350 2    60   ~ 0
EN
Text Label 9100 1550 2    60   ~ 0
D13
Text Label 9100 1650 2    60   ~ 0
D12
Text Label 9100 1750 2    60   ~ 0
D11
Text Label 9100 1850 2    60   ~ 0
D10
Text Label 9100 1950 2    60   ~ 0
D9
Text Label 9100 2050 2    60   ~ 0
D6
Text Label 9100 2150 2    60   ~ 0
D5
Text Label 9100 2250 2    60   ~ 0
SCL
Text Label 9100 2350 2    60   ~ 0
SDA
Wire Notes Line
	2750 2750 10500 2750
Wire Notes Line
	8400 2750 8400 500 
Wire Notes Line
	8400 650  9450 650 
Wire Notes Line
	9450 650  9450 500 
Wire Wire Line
	10050 1200 9700 1200
Wire Wire Line
	9700 1200 9700 2500
Wire Wire Line
	10050 1000 9700 1000
Wire Wire Line
	9700 1000 9700 750 
Wire Wire Line
	9100 1450 8800 1450
Wire Wire Line
	9100 1250 8800 1250
Text Label 8800 1250 2    60   ~ 0
VBAT
Text Label 8800 1450 2    60   ~ 0
VUSB
NoConn ~ 10050 2400
$Comp
L GND #PWR11
U 1 1 59796D2F
P 8150 3800
F 0 "#PWR11" H 8150 3550 50  0001 C CNN
F 1 "GND" H 8150 3650 50  0000 C CNN
F 2 "" H 8150 3800 50  0001 C CNN
F 3 "" H 8150 3800 50  0001 C CNN
	1    8150 3800
	1    0    0    -1  
$EndComp
Text Label 8800 3200 0    60   ~ 0
VBAT
Text Label 7800 3500 0    60   ~ 0
MOSI
$Comp
L APA102 LED1
U 1 1 59797576
P 8600 3650
F 0 "LED1" H 8400 3950 60  0000 C CNN
F 1 "APA102 (RGB)" H 8650 3350 60  0000 C CNN
F 2 "CrumpPrints:APA102" H 8600 3200 60  0001 C CNN
F 3 "" H 8600 3200 60  0000 C CNN
	1    8600 3650
	1    0    0    -1  
$EndComp
Text Label 7800 3650 0    60   ~ 0
SCK
Wire Wire Line
	7800 3650 8150 3650
Wire Wire Line
	7800 3500 8150 3500
$Comp
L APA102 LED2
U 1 1 5979778F
P 9700 3650
F 0 "LED2" H 9500 3950 60  0000 C CNN
F 1 "APA102 (W)" H 9700 3350 60  0000 C CNN
F 2 "CrumpPrints:APA102" H 9700 3200 60  0001 C CNN
F 3 "" H 9700 3200 60  0000 C CNN
	1    9700 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	9050 3800 9150 3800
Wire Wire Line
	9150 3800 9150 3200
Wire Wire Line
	8800 3200 10250 3200
Wire Wire Line
	10250 3200 10250 3800
Wire Wire Line
	10250 3800 10150 3800
Connection ~ 9150 3200
Wire Wire Line
	9050 3650 9250 3650
Wire Wire Line
	9050 3500 9250 3500
$Comp
L CONN_01X03 J1
U 1 1 59797A62
P 7650 750
F 0 "J1" H 7650 950 50  0000 C CNN
F 1 "MOTION DETECTOR" V 7750 750 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Angled_1x03_Pitch2.54mm" H 7650 750 50  0001 C CNN
F 3 "" H 7650 750 50  0001 C CNN
	1    7650 750 
	0    -1   -1   0   
$EndComp
$Comp
L R_PHOTO R3
U 1 1 59797B58
P 6650 1850
F 0 "R3" V 6750 1850 50  0000 L CNN
F 1 "R_PHOTO" H 6700 1800 50  0000 L TNN
F 2 "Opto-Devices:Resistor_LDR_5.1x4.3_RM3.4" V 6700 1600 50  0001 L CNN
F 3 "" H 6650 1800 50  0001 C CNN
	1    6650 1850
	1    0    0    -1  
$EndComp
$Comp
L R R1
U 1 1 597CE41F
P 6250 1400
F 0 "R1" V 6150 1400 50  0000 C CNN
F 1 "22.6K" V 6250 1400 39  0000 C CNN
F 2 "Resistors_SMD:R_0805_HandSoldering" V 6180 1400 50  0001 C CNN
F 3 "" H 6250 1400 50  0001 C CNN
	1    6250 1400
	-1   0    0    1   
$EndComp
$Comp
L R R2
U 1 1 597CE47C
P 6250 1850
F 0 "R2" V 6330 1850 50  0000 C CNN
F 1 "10K" V 6250 1850 50  0000 C CNN
F 2 "Resistors_SMD:R_0805_HandSoldering" V 6180 1850 50  0001 C CNN
F 3 "" H 6250 1850 50  0001 C CNN
	1    6250 1850
	1    0    0    -1  
$EndComp
Wire Wire Line
	6250 1550 6250 1700
Connection ~ 6250 1600
$Comp
L GND #PWR6
U 1 1 597CE63C
P 6250 2000
F 0 "#PWR6" H 6250 1750 50  0001 C CNN
F 1 "GND" H 6250 1850 50  0000 C CNN
F 2 "" H 6250 2000 50  0001 C CNN
F 3 "" H 6250 2000 50  0001 C CNN
	1    6250 2000
	1    0    0    -1  
$EndComp
$Comp
L VCC #PWR5
U 1 1 597CEF49
P 6250 1250
F 0 "#PWR5" H 6250 1100 50  0001 C CNN
F 1 "VCC" H 6250 1400 50  0000 C CNN
F 2 "" H 6250 1250 50  0001 C CNN
F 3 "" H 6250 1250 50  0001 C CNN
	1    6250 1250
	1    0    0    -1  
$EndComp
Text Label 6650 1400 3    60   ~ 0
A0
$Comp
L GND #PWR7
U 1 1 597D0A0F
P 6650 2000
F 0 "#PWR7" H 6650 1750 50  0001 C CNN
F 1 "GND" H 6650 1850 50  0000 C CNN
F 2 "" H 6650 2000 50  0001 C CNN
F 3 "" H 6650 2000 50  0001 C CNN
	1    6650 2000
	1    0    0    -1  
$EndComp
Wire Wire Line
	6650 1400 6650 1700
Connection ~ 6650 1600
$Comp
L GND #PWR12
U 1 1 597D0EF3
P 8250 2450
F 0 "#PWR12" H 8250 2200 50  0001 C CNN
F 1 "GND" H 8250 2300 50  0000 C CNN
F 2 "" H 8250 2450 50  0001 C CNN
F 3 "" H 8250 2450 50  0001 C CNN
	1    8250 2450
	1    0    0    -1  
$EndComp
Wire Wire Line
	7950 1700 7950 2450
Text Label 7950 1700 3    60   ~ 0
D5
Wire Notes Line
	7150 2750 7150 500 
Wire Notes Line
	6100 2750 6100 500 
Wire Notes Line
	2750 4450 10500 4450
Wire Notes Line
	7400 4450 7400 2750
$Comp
L CONN_01X02 J2
U 1 1 597D1FB0
P 5750 1150
F 0 "J2" H 5750 1300 50  0000 C CNN
F 1 "EXT BUTTON" V 5850 1150 50  0000 C CNN
F 2 "Pin_Headers:Pin_Header_Straight_1x02_Pitch2.54mm" H 5750 1150 50  0001 C CNN
F 3 "" H 5750 1150 50  0001 C CNN
	1    5750 1150
	0    -1   -1   0   
$EndComp
$Comp
L GND #PWR4
U 1 1 597D2087
P 5800 2000
F 0 "#PWR4" H 5800 1750 50  0001 C CNN
F 1 "GND" H 5800 1850 50  0000 C CNN
F 2 "" H 5800 2000 50  0001 C CNN
F 3 "" H 5800 2000 50  0001 C CNN
	1    5800 2000
	1    0    0    -1  
$EndComp
Wire Wire Line
	5800 1350 5800 2000
Wire Wire Line
	5700 1350 5700 1550
Text Label 5700 2000 1    60   ~ 0
D6
Wire Notes Line
	5400 2750 5400 500 
$Comp
L ATTINY85-20PU U3
U 1 1 597D0F49
P 5750 3400
F 0 "U3" H 4600 3800 50  0000 C CNN
F 1 "ATTINY85-20PU" H 6650 3000 50  0000 C CNN
F 2 "Housings_SOIC:SOIC-8_3.9x4.9mm_Pitch1.27mm" H 6750 3400 50  0001 C CIN
F 3 "" H 5750 3400 50  0001 C CNN
	1    5750 3400
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR9
U 1 1 597D1088
P 7100 3650
F 0 "#PWR9" H 7100 3400 50  0001 C CNN
F 1 "GND" H 7100 3500 50  0000 C CNN
F 2 "" H 7100 3650 50  0001 C CNN
F 3 "" H 7100 3650 50  0001 C CNN
	1    7100 3650
	1    0    0    -1  
$EndComp
$Comp
L AVR-ISP-6 ISP1
U 1 1 597D1114
P 4750 4050
F 0 "ISP1" H 4645 4290 50  0000 C CNN
F 1 "AVR-ISP-6" H 4485 3820 50  0000 L BNN
F 2 "Pin_Headers:Pin_Header_Straight_2x03_Pitch2.54mm" V 4230 4090 50  0001 C CNN
F 3 "" H 4725 4050 50  0001 C CNN
	1    4750 4050
	1    0    0    -1  
$EndComp
Wire Wire Line
	4600 4150 4100 4150
Wire Wire Line
	4100 4150 4100 3650
Wire Wire Line
	4100 3650 4400 3650
Wire Wire Line
	4600 4050 4300 4050
Wire Wire Line
	4300 4050 4300 3350
Wire Wire Line
	3400 3350 4400 3350
$Comp
L GND #PWR3
U 1 1 597D12FA
P 5200 4150
F 0 "#PWR3" H 5200 3900 50  0001 C CNN
F 1 "GND" H 5200 4000 50  0000 C CNN
F 2 "" H 5200 4150 50  0001 C CNN
F 3 "" H 5200 4150 50  0001 C CNN
	1    5200 4150
	1    0    0    -1  
$EndComp
Wire Wire Line
	5200 4150 4850 4150
Wire Wire Line
	4850 3950 5450 3950
Wire Wire Line
	4400 3250 4200 3250
Wire Wire Line
	4200 3250 4200 3950
Wire Wire Line
	4200 3950 4600 3950
Wire Wire Line
	4000 3150 4000 4400
Wire Wire Line
	3400 3150 4400 3150
Wire Wire Line
	4850 4050 5300 4050
Wire Wire Line
	5300 4050 5300 4400
Wire Wire Line
	5300 4400 4000 4400
Wire Wire Line
	4400 3550 3400 3550
Wire Wire Line
	4400 3450 3400 3450
Text Label 2800 3450 0    60   ~ 0
~RESET
Text Label 7550 2000 1    60   ~ 0
MOTION_GND
Wire Wire Line
	7550 2000 7550 950 
Wire Wire Line
	7650 2000 7650 950 
Wire Wire Line
	7750 1050 7750 950 
Text Label 7650 2000 1    60   ~ 0
MOTION_VCC
Text Label 7750 2000 1    60   ~ 0
MOTION_SIG
Text Label 8100 2450 1    60   ~ 0
MOTION_VCC
Wire Wire Line
	8100 2450 8100 1850
$Comp
L VCC #PWR10
U 1 1 597D3E37
P 8100 1850
F 0 "#PWR10" H 8100 1700 50  0001 C CNN
F 1 "VCC" H 8100 2000 50  0000 C CNN
F 2 "" H 8100 1850 50  0001 C CNN
F 3 "" H 8100 1850 50  0001 C CNN
	1    8100 1850
	1    0    0    -1  
$EndComp
Wire Wire Line
	8250 1900 8250 2450
Text Label 8250 1900 3    60   ~ 0
MOTION_GND
Text Label 7950 2450 1    60   ~ 0
MOTION_SIG
Text Label 3400 3550 0    60   ~ 0
MOTION_SIG
Text Label 5450 3950 2    60   ~ 0
VCC
$Comp
L R R5
U 1 1 5982A455
P 3250 3450
F 0 "R5" V 3330 3450 50  0000 C CNN
F 1 "1K" V 3250 3450 50  0000 C CNN
F 2 "Resistors_SMD:R_0805_HandSoldering" V 3180 3450 50  0001 C CNN
F 3 "" H 3250 3450 50  0001 C CNN
	1    3250 3450
	0    1    1    0   
$EndComp
Wire Wire Line
	3100 3450 2800 3450
$Comp
L R R6
U 1 1 5982A5C8
P 5700 1700
F 0 "R6" V 5780 1700 50  0000 C CNN
F 1 "1K" V 5700 1700 50  0000 C CNN
F 2 "Resistors_SMD:R_0805_HandSoldering" V 5630 1700 50  0001 C CNN
F 3 "" H 5700 1700 50  0001 C CNN
	1    5700 1700
	1    0    0    -1  
$EndComp
Wire Wire Line
	5700 1850 5700 2000
$Comp
L R R7
U 1 1 5982A87C
P 7750 1200
F 0 "R7" V 7830 1200 50  0000 C CNN
F 1 "1K" V 7750 1200 50  0000 C CNN
F 2 "Resistors_SMD:R_0805_HandSoldering" V 7680 1200 50  0001 C CNN
F 3 "" H 7750 1200 50  0001 C CNN
	1    7750 1200
	1    0    0    -1  
$EndComp
Wire Wire Line
	7750 2000 7750 1350
$Comp
L GND #PWR13
U 1 1 5986A206
P 9250 3800
F 0 "#PWR13" H 9250 3550 50  0001 C CNN
F 1 "GND" H 9250 3650 50  0000 C CNN
F 2 "" H 9250 3800 50  0001 C CNN
F 3 "" H 9250 3800 50  0001 C CNN
	1    9250 3800
	1    0    0    -1  
$EndComp
$Comp
L VCC #PWR8
U 1 1 5987EE9E
P 7100 3150
F 0 "#PWR8" H 7100 3000 50  0001 C CNN
F 1 "VCC" H 7100 3300 50  0000 C CNN
F 2 "" H 7100 3150 50  0001 C CNN
F 3 "" H 7100 3150 50  0001 C CNN
	1    7100 3150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6250 1600 6650 1600
Connection ~ 4000 3150
Connection ~ 4300 3350
Text Label 3400 3350 0    60   ~ 0
SCL
Text Label 3400 3150 0    60   ~ 0
SDA
$Comp
L VCC #PWR2
U 1 1 598F5087
P 3250 3800
F 0 "#PWR2" H 3250 3650 50  0001 C CNN
F 1 "VCC" H 3250 3950 50  0000 C CNN
F 2 "" H 3250 3800 50  0001 C CNN
F 3 "" H 3250 3800 50  0001 C CNN
	1    3250 3800
	1    0    0    -1  
$EndComp
Wire Wire Line
	3250 4100 3250 4300
Text Label 3250 4300 1    60   ~ 0
SCL
$Comp
L VCC #PWR1
U 1 1 598F54B3
P 3050 3800
F 0 "#PWR1" H 3050 3650 50  0001 C CNN
F 1 "VCC" H 3050 3950 50  0000 C CNN
F 2 "" H 3050 3800 50  0001 C CNN
F 3 "" H 3050 3800 50  0001 C CNN
	1    3050 3800
	1    0    0    -1  
$EndComp
Wire Wire Line
	3050 4100 3050 4300
Text Label 3050 4300 1    60   ~ 0
SDA
Wire Notes Line
	2750 2750 2750 4450
$Comp
L R R4
U 1 1 598F56B4
P 3050 3950
F 0 "R4" V 3130 3950 50  0000 C CNN
F 1 "4.7K" V 3050 3950 50  0000 C CNN
F 2 "" V 2980 3950 50  0001 C CNN
F 3 "" H 3050 3950 50  0001 C CNN
	1    3050 3950
	1    0    0    -1  
$EndComp
$Comp
L R R8
U 1 1 598F56F9
P 3250 3950
F 0 "R8" V 3330 3950 50  0000 C CNN
F 1 "4.7K" V 3250 3950 50  0000 C CNN
F 2 "" V 3180 3950 50  0001 C CNN
F 3 "" H 3250 3950 50  0001 C CNN
	1    3250 3950
	1    0    0    -1  
$EndComp
$EndSCHEMATC
