{{
┌────────────────────────────┬──────────────────┬────────────────────────┐
│     FPU32_FFT_Demo v3.0    │ Author:I.Kövesdi │ Release:  30 Dec 2011  │
├────────────────────────────┴──────────────────┴────────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This terminal application demonstrates  procedures and the general    │
│ usage of the "FPU32_FFT_Driver.spin" object. The correctness and       │
│ accuracy of the FFT driver is verified with simple numeric examples,   │
│ then a complete Spectrum Analyzer calculation is displayed.            │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The FPU provides the user a comprehensive set of IEE 754 32-bit float,│
│ 32-bit LONG, string, FFT and matrix operations. It also has two 12-bit │
│ ADCs, a programmable serial TTL interface and an NMEA parser. The FPU  │
│ contains Flash memory and EEPROM for storing user defined functions and│
│ data and 128 32-bit registers for 32-bit FLOAT and 32-bit LONG data.   │
│  Mobilizing the User Defined Function capabilities of the FPU, compact │
│ code and fast data processing speed can be achieved with low-cost and  │
│ low power consumption in your embedded application.                    │
│                                                                        │    
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The FFT driver is a member of a family of drivers for the uM-FPU      │
│ v3.1 with 2-wire SPI connection. The family has been placed on OBEX:   │
│                                                                        │
│  FPU32_SPI     (Core driver of the FPU32 family)                       │
│  FPU32_ARITH   (Basic arithmetic operations)                           │
│  FPU32_MATRIX  (Basic and advanced matrix operations)                  │
│ *FPU32_FFT     (FFT with advanced options)                             │
│                                                                        │
│  The procedures and functions of these drivers can be cherry picked and│
│ used together to build application specific uM-FPU v3.1 drivers.       │
│  Other specialized drivers, as GPS, MEMS, IMU, MAGN, NAVIG, ADC, DSP,  │
│ ANN, STR are in preparation with similar cross-compatibility features  │
│ around the instruction set and with the user defined function ability  │
│ of the uM-FPU v3.1.                                                    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}

CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

{
Schematics

                                              5V(REG)           
                                               │                     
P   │                                   10K    │  
  A3├4────────────────────────────┳─────────┫   
R   │                              │           │
  A4├5────────────────────┐       │           │
O   │                      │       │           │ 
  A5├6────┳──────┐                        │
P   │       │      12     16       1           │
            │    ┌──┴──────┴───────┴──┐        │                               
          1K    │ SIN   SCLK   /MCLR │        │                  
            │    │                    │        │
            │    │                AVDD├18──────┫       
            └─11┤SOUT             VDD├14──────┘
                 │                    │         
                 │     uM-FPU 3.1     │
                 │                    │                                                                                           
            ┌───4┤CS                  │         
            ┣───9┤SIN                 │             
            ┣──17┤AVSS                │         
            ┣──13┤VSS                 │         
            │    └────────────────────┘
            
           GND

The CS pin(4) of the FPU is tied to LOW to select SPI mode at Reset and
must remain LOW during operation. For this Demo the 2-wire SPI connection
was used, where the SOUT and SIN pins were connected through a 1K resistor
and the DIO pin(6) of the Propeller was connected to the SIN pin(12) of
the FPU.
}


'--------------------------------Connections------------------------------
'            On Propeller                           On FPU
'-----------------------------------  ------------------------------------
'Sym.   A#/IO       Function            Sym.  P#/IO        Function
'-------------------------------------------------------------------------
_FCLR = 3 'Out  FPU Master Clear   -->  MCLR  1  In   Master Clear
_FCLK = 4 'Out  FPU SPI Clock      -->  CLK  16  In   SPI Clock Input     
_FDIO = 5 ' Bi  FPU SPI In/Out     -->  SIN  12  In   SPI Data In 
'       └─────────────────via 1K   <--  SOUT 11 Out   SPI Data Out


OBJ

PST     : "Parallax Serial Terminal"   'From Parallax Inc.
                                       'v1.0
                                       
FPU     : "FPU32_FFT_Driver"           'v3.0

  
VAR

LONG  cog_ID, okay, fpu32, char

LONG data[FPU#_MAX_FFT_SIZE << 1]    

LONG dataSize, fftSizem1, adcRate, maxF, binF, nFB

LONG f1, f2  


DAT '------------------------Start of SPIN code---------------------------

  
PUB Start_Application | addrCOG_ID_                                                     
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Start_Application │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: -Starts driver objects
''             -Makes a MASTER CLEAR of the FPU and
''             -Calls demo procedure
'' Parameters: None
''     Result: None
''+Reads/Uses: /FPU32, Hardware constants from CON section
''    +Writes: FPU32,
''      Calls: FullDuplexSerialPlus----------->PST.Start
''                                             PST.Stop
''             FPU32_FFT_Driver--------------->FPU.Start_Driver
''                                             FPU.Stop_Driver
''             FPU32_FFT_Demo 
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus PST terminal
PST.Start(57600)
  
WAITCNT(4 * CLKFREQ + CNT)

PST.Char(PST#CS)
PST.Str(STRING("Demo of FFT with uM-FPU v3.1 started..."))
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

addrCOG_ID_ := @cog_ID

fpu32 := FALSE

'FPU Master Clear...
PST.Str(STRING(10, "FPU Master Clear..."))
OUTA[_FCLR]~~ 
DIRA[_FCLR]~~
OUTA[_FCLR]~
WAITCNT(CLKFREQ + CNT)
OUTA[_FCLR]~~
DIRA[_FCLR]~

fpu32 := FPU.Start_Driver(_FDIO, _FCLK, addrCOG_ID_)

PST.Chars(PST#NL, 2)  

IF fpu32

  PST.Str(STRING("FPU32_FFT_Driver started in COG "))
  PST.Dec(cog_ID)
  PST.Chars(PST#NL, 2)
  WAITCNT(CLKFREQ + CNT)

  FPU32_FFT_Demo

  PST.Char(PST#NL)
  PST.Str(STRING("FPU32_FFT_Driver demo terminated normally."))

  FPU.Stop_Driver
   
ELSE

  PST.Char(PST#NL)
  PST.Str(STRING("FPU32_FFT_Driver start failed!"))
  PST.Chars(PST#NL, 2)
  PST.Str(STRING("Device not detected! Check hardware and try again..."))

WAITCNT(CLKFREQ + CNT)
  
PST.Stop  
'--------------------------End of Start_Application-----------------------    


PUB FPU32_FFT_Demo | i, f
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ FPU32_FFT_Demo │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Demonstrates uM-FPU32_FFT_Driver via some examples 
'' Parameters: None                                 
''     Result: None                    
''+Reads/Uses: PST/CONs and FPU/CONs
''    +Writes: okay
''      Calls: Parallax Serial Terminal---------->PST.Star
''                                                PST.Char
''                                                PST.Str
''                                                PST.Dec
''             FPU32_FFT_Driver------------------>FPU.Reset
''                                                FPU.ReadSyncChar 
''                                                FPU.WriteCmd
''                                                FPU.Wait
''                                                FPU.ReadStr
''                                                FPU.ReadReg
''                                                FPU.ReadInterVar
''                                                FPU.FFT   
''                                                FPU.Spectrum_Analyzer
''             WaitForKeyPress
''             GenerateData
'------------------------------------------------------------------------
PST.Str(STRING("--uM-FPU v3.1 FFT Driver with SPI connection--"))
PST.Chars(PST#NL, 2)

WAITCNT(CLKFREQ + CNT)

okay := FALSE
okay := Fpu.Reset  
IF okay
  PST.Str(STRING("FPU Software Reset done..."))
  PST.Char(PST#NL)
ELSE
  PST.Str(STRING("FPU Software Reset failed..."))
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

WAITCNT(CLKFREQ + CNT)

char := FPU.ReadSyncChar
PST.Char(PST#NL)
PST.Str(STRING("Response to _SYNC: $"))
PST.Hex(char, 2)
IF (char == FPU#_SYNC_CHAR)
  PST.Str(STRING("    (OK)"))
  PST.Char(PST#NL)  
ELSE
  PST.Str(STRING("   Not OK!"))   
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

PST.Char(PST#NL)
PST.Str(STRING("   Version String: "))
FPU.WriteCmd(FPU#_VERSION)
FPU.Wait
PST.Str(FPU.ReadStr) 

PST.Char(PST#NL)
PST.Str(STRING("     Version Code: $"))
FPU.WriteCmd(FPU#_LREAD0)
PST.Hex(FPU.ReadReg, 8) 
  
PST.Char(PST#NL)
PST.Str(STRING(" Clock Ticks / ms: "))
PST.Dec(FPU.ReadInterVar(FPU#_TICKS))
PST.Char(PST#NL) 

WaitForKeyPress

PST.Char(PST#CS)

GenerateData(1)

PST.Str(STRING("Numeric example 1."))
PST.Chars(PST#NL, 2)
PST.Str(STRING("5 input data with non-zero imaginary part:"))
PST.Chars(PST#NL, 2)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)   
REPEAT i FROM 0 TO (dataSize - 1)
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)  

WaitForKeyPress

'Do FFT with no windowing here 
FPU.FFT(@data, dataSize, FPU#_NOWINDOW, FALSE)

PST.Char(PST#CS)

PST.Str(STRING("Result of FFT:"))
PST.Chars(PST#NL, 2)

'Check result of FFT
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO fftSizem1
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)

WaitForKeyPress

'Use all frequency channels for inverse, not windowed of course
dataSize := 8

FPU.FFT(@data, dataSize, FPU#_NOWINDOW, TRUE)

PST.Char(PST#CS)

PST.Str(STRING("Result of inverse FFT:"))
PST.Chars(PST#NL, 2)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO fftSizem1
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)
  
WaitForKeyPress

GenerateData(2)

PST.Char(PST#CS)
PST.Str(STRING("Numeric example 2."))
PST.Chars(PST#NL, 2)
PST.Str(STRING("5 input data with all zero imaginary part:"))
PST.Chars(PST#NL, 2)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO (dataSize - 1)
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)  

WaitForKeyPress

'Do FFT with no windowing here
FPU.FFT(@data, dataSize, FPU#_NOWINDOW, FALSE)

PST.Char(PST#CS)

PST.Str(STRING("Result of FFT:"))
PST.Chars(PST#NL, 2)

'Check result of FFT
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO fftSizem1
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)

WaitForKeyPress

'Use all frequency channels for inverse, not windowed, of course
dataSize := 8

FPU.FFT(@data, dataSize, FPU#_NOWINDOW, TRUE)

PST.Char(PST#CS)

PST.Str(STRING("Result of inverse FFT:"))
PST.Chars(PST#NL, 2)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO fftSizem1
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)
  
WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Numeric example 3."))
PST.Chars(PST#NL, 2)
PST.Str(STRING("513 input data with all zero imaginary part:"))
PST.Chars(PST#NL, 2)

GenerateData(3)    

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO 9
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)
PST.Str(STRING("..."))
PST.Char(PST#NL)    

WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Processing 1K complex data..."))

'Do FFT with no windowing here
FPU.FFT(@data, dataSize, FPU#_NOWINDOW, FALSE)

PST.Char(PST#CS)

PST.Str(STRING("Result of FFT:"))
PST.Chars(PST#NL, 2)

'Check result of FFT
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO 9
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)
PST.Str(STRING("..."))
PST.Char(PST#NL)

WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Processing 1K complex data..."))

'Use all frequency channels for inverse, not windowed, of course
dataSize := 1024

FPU.FFT(@data, dataSize, FPU#_NOWINDOW, TRUE)

PST.Char(PST#CS)

PST.Str(STRING("Result of inverse FFT:"))
PST.Chars(PST#NL, 2)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO 9
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)
PST.Str(STRING("..."))
PST.Char(PST#NL)
  
WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Check shape of 1. window function for transients:"))
PST.Char(PST#NL)
PST.Str(STRING("Decaying exponential applied on const = 10 real signal"))
PST.Char(PST#NL)
PST.Str(STRING("of 16 data points. This shape improves S/N in spectrum."))
PST.Char(PST#NL)

GenerateData(5)

FPU.Window(FPU#_EXPONENTIAL)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO (dataSize - 1)
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)

WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Check shape of 2. window function for transients:"))
PST.Char(PST#NL)
PST.Str(STRING("First up, peak then down applied on const = 10 real signal"))
PST.Char(PST#NL)
PST.Str(STRING("of 16 data points. This shape increases frequency resolution."))
PST.Char(PST#NL)

GenerateData(5)

FPU.Window(FPU#_RESENHANCE)

'Check data
PST.Str(STRING("#     Real      Imag"))
PST.Char(PST#NL)
PST.Str(STRING("---------------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO (dataSize - 1)
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 93))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[(i << 1) + 1], 93))
  PST.Char(PST#NL)

WaitForKeyPress

PST.Char(PST#CS)

PST.Str(STRING("Frequency Analyzer:"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("Sum of 1 Vpp 430 Hz and 2 Vpp 440 Hz sinusoid signals and"))
PST.Char(PST#NL)
PST.Str(STRING("3 V DC is generated. The ADC rate is 2500 Hz, its scale"))
PST.Char(PST#NL)
PST.Str(STRING("is 4096/+-10V and 2000 datapoints are collected (0.8 sec)."))
PST.Char(PST#NL)
PST.Str(STRING("The Spectrum_Analyzer function of the driver will be used to"))
PST.Char(PST#NL)
PST.Str(STRING("process the generated integer data where Hanning window will"))
PST.Char(PST#NL)
PST.Str(STRING("be applied to decrease spectral leaking. The frequencies will"))
PST.Char(PST#NL)
PST.Str(STRING("be scanned only up to 500 Hz according to Tektronix's good"))
PST.Char(PST#NL) 
PST.Str(STRING("industry practice. (They say you need at least 5 points per"))
PST.Char(PST#NL)
PST.Str(STRING("cycle for reliable differentiation between harmonics.)"))
PST.Char(PST#NL)
PST.Str(STRING("Magnitude data will be displayed near signal frequencies."))
PST.Char(PST#NL)

f1 := 430.0
f2 := 440.0
adcRate := 2500 

GenerateData(4)

WaitForKeyPress  

PST.Char(PST#CS)

PST.Str(STRING("First samples from the integer input data:"))
PST.Chars(PST#NL, 2)

'Check data before complexise
PST.Str(STRING("#     ADC count"))
PST.Char(PST#NL)
PST.Str(STRING("---------------"))
PST.Char(PST#NL)  
REPEAT i FROM 0 TO 9
  PST.Dec(i)
  PST.Str(STRING("       "))
  PST.Str(FPU.L32_To_STR(data[i], 0))
  PST.Char(PST#NL)
PST.Str(STRING("..."))
PST.Char(PST#NL)

'Create complex data from array of LONG integers
FPU.Longs_To_Complexes(@data, dataSize)

WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Processing 2K complex data..."))  

'Do analyze
FPU.Spectrum_Analyzer(@data,dataSize,adcRate,FPU#_HANNING,FPU#_MAGN_PHASE,@maxF,@binF,@nFB)

PST.Char(PST#CS)

PST.Str(STRING("Maximum useful frequency = "))
PST.Str(FPU.F32_To_STR(maxF, 0))
PST.Str(STRING(" Hz"))
PST.Char(PST#NL)
PST.Str(STRING("    Frequency resolution = "))
PST.Str(FPU.F32_To_STR(binF, 52))
PST.Str(STRING(" Hz"))
PST.Char(PST#NL)
PST.Str(STRING(" # of frequency channels = "))
PST.Str(FPU.L32_To_STR(nFB, 0))
PST.Char(PST#NL)

WaitForKeyPress

PST.Char(PST#CS)
PST.Str(STRING("Signal intensity:"))
PST.Char(PST#NL)

'Check data
PST.Str(STRING("#bin  Freq     Magn   "))
PST.Char(PST#NL)
PST.Str(STRING("----------------------"))
PST.Char(PST#NL)
'Prepare frequency calculation
FPU.WriteCmdByte(FPU#_SELECTA, 1)
FPU.WriteCmdLong(FPU#_FWRITEA, binF)
FPU.WriteCmdByte(FPU#_SELECTA, 0) 
REPEAT i FROM 349 TO 365
  'Calculate frequency of bin
  FPU.WriteCmdLong(FPU#_LWRITEA, i)
  FPU.WriteCmd(FPU#_FLOAT)
  FPU.WriteCmdByte(FPU#_FMUL, 1)
  FPU.Wait
  FPU.WriteCmd(FPU#_FREADA)
  f := FPU.ReadReg
  'Display data   
  PST.Dec(i)
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_Str(f, 61))
  PST.Str(STRING(" "))
  PST.Str(FPU.F32_To_STR(data[i << 1], 91))
  PST.Char(PST#NL)
  
PST.Str(STRING("Note, that the two peaks are well separated and the"))       
PST.Char(PST#NL)
PST.Str(STRING("integral of the amplitudes around 440 Hz is twice as"))       
PST.Char(PST#NL)
PST.Str(STRING("much as of those around 430 Hz."))       
PST.Char(PST#NL)
'--------------------------End of FPU32_FFT_Demo--------------------------


PRI GenerateData(sw) | i
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ GenerateData │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Generates example data
'' Parameters: Case switch
''     Result: None
''     Effect: Data array filled appropriately
''+Reads/Uses: ownCOG                                      VAR/LONG
''    +Writes: - dataSize, fftSizem1                         VAR/LONG
''             - See effect
''      Calls: FPU32_FFT_Driver------->FPU.LongArray_To_ComplexFloatArray 
'-------------------------------------------------------------------------
CASE sw
  1:
    dataSize := 5
    fftSizem1 := 7
    REPEAT i FROM 0 TO (dataSize - 1)
      data[i << 1] := FPU.L32_To_F32(i * i)
      data[(i << 1) + 1] := FPU.L32_To_F32(-i)
  2:
    dataSize := 5
    fftSizem1 := 7
    REPEAT i FROM 0 TO (dataSize - 1)
      data[i] := 10
    FPU.Longs_To_Complexes(@data, dataSize)
  3:
    dataSize := 513
    fftSizem1 := 1023
    REPEAT i FROM 0 TO (dataSize - 1)
      data[i] := 10
    FPU.Longs_To_Complexes(@data, dataSize)
  4:
    dataSize := 2000
    fftSizem1 := 2047
    'Prepare FPU registers
    FPU.WriteCmdByte(FPU#_SELECTA, 0) 
    FPU.WriteCmd(FPU#_LOADPI)
    FPU.WriteCmdByte(FPU#_FMULI, 2)            'Reg(0) = 2 * PI
    FPU.WriteCmdByte(FPU#_SELECTA, 1)
    FPU.WriteCmdLong(FPU#_FWRITEA, f1)         'Freq for signal A
    FPU.WriteCmd(FPU#_FMUL0)                   'Reg(1) = omega for A
    FPU.WriteCmdByte(FPU#_SELECTA, 2)
    FPU.WriteCmdLong(FPU#_FWRITEA, f2)         'Freq for signal B
    FPU.WriteCmd(FPU#_FMUL0)                   'Reg(2) = omega for B
    FPU.WriteCmdByte(FPU#_SELECTA, 6)
    FPU.WriteCmdLong(FPU#_LWRITEA, adcRate)
    FPU.WriteCmd(FPU#_FLOAT)  
    FPU.WriteCmd(FPU#_FINV)                    'Reg(6) = 1 / adcRate 
    REPEAT i FROM 0 TO (dataSize - 1)          
      'Calculate t 
      FPU.WriteCmdByte(FPU#_SELECTA, 0)
      FPU.WriteCmdLong(FPU#_LWRITEA, i)
      FPU.WriteCmd(FPU#_FLOAT)
      FPU.WriteCmdByte(FPU#_FMUL, 6)           'Reg(0) = t [sec]          
      FPU.WriteCmdByte(FPU#_SELECTA, 3)
      FPU.WriteCmdByte(FPU#_FSET, 1)
      FPU.WriteCmdByte(FPU#_FMUL, 0)
      FPU.WriteCmd(FPU#_SIN)                   'Reg(3) = Signal A
      FPU.WriteCmdByte(FPU#_SELECTA, 4)
      FPU.WriteCmdByte(FPU#_FSET, 2)
      FPU.WriteCmdByte(FPU#_FMUL, 0)
      FPU.WriteCmd(FPU#_SIN)
      FPU.WriteCmdByte(FPU#_FMULI, 2)          'Reg(4) = Signal B
      FPU.WriteCmdByte(FPU#_SELECTA, 5)
      FPU.WriteCmdLong(FPU#_FWRITEA, 3.0)
      FPU.WriteCmdByte(FPU#_FADD, 3)                     
      FPU.WriteCmdByte(FPU#_FADD, 4)           'Reg(5) = Analog signal
      'Digitize
      FPU.WriteCmdByte(FPU#_FDIVI, 10)
      FPU.WriteCmdByte(FPU#_FMULI, 32)
      FPU.WriteCmdByte(FPU#_FMULI, 64)
      FPU.WriteCmd(FPU#_FIXR)                  'Reg(5) = ADC count
      'Read data
      FPU.Wait
      FPU.WriteCmd(FPU#_LREADA)
      data[i] := FPU.ReadReg
  5:
    dataSize := 16
    fftSizem1 := 15
    REPEAT i FROM 0 TO (dataSize - 1)
      data[i] := 10
    FPU.Longs_To_Complexes(@data, dataSize)      
'---------------------------End of GenerateData---------------------------


PRI WaitForKeyPress
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ WaitForKeyPress │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: - Waits for pressed key then continues
'' Parameters: None
''     Result: None
''+Reads/Uses: FullDuplexSerialPlus----------->PST#NL
''    +Writes: None
''      Calls: FullDuplexSerialPlus----------->PST.Char
''                                             PST.Str
''                                             PST.CharIn
'-------------------------------------------------------------------------
PST.Char(PST#NL)
PST.Str(STRING("Press any key to continue..."))
PST.Char(PST#NL)
REPEAT UNTIL PST.CharIn
'-------------------------End of WaitForKeyPress--------------------------


DAT '---------------------------MIT License------------------------------- 


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}