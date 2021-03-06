{{
OBEX LISTING:
  http://obex.parallax.com/object/700

  Includes Spin-based and PASM-based open-drain and push-pull drivers, with methods for reading and writing any number of bytes, words, and longs in big-endian or little-endian format.  All drivers tested with the 24LC256 EEPROM, DS1307 real time clock, MMA7455L 3-axis accelerometer, L3G4200D gyroscope module, MS5607 altimeter module, and BMP085 pressure sensor.  Includes a demo programs for each.

  Also includes a polling routine that displays the device address and name of everything on the I2C bus.

  Also includes a slave object that runs in a PASM cog with a Spin handler, and provides 32 byte-sized registers for a master running on another device to write to and read from.  Tested okay up to 1Mbps (max speed of my PASM push-pull object).  Includes demo for the slave object.

  Newly added multi-master object that can share the bus with other masters, provided of course that the other masters also allow sharing.
}}
{{┌──────────────────────────────────────────┐
  │ BMP085 pressure sensor demo              │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2014 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  
Demonstrates how to use the BMP085 pressure sensor
                                                                                                                                                                                 
  The BMP085 pressure sensor uses the 7-bit device code $77
  Registers $AA through $BF contain calibration coefficients, stored as big-endian 16-bit words

      AAh     AC1-H    signed  
      ABh     AC1-L    
      ACh     AC2-H    signed         
      ADh     AC2-L                   
      AEh     AC3-H    signed         
      AFh     AC3-L                   
      B0h     AC4-H    unsigned       
      B1h     AC4-L                   
      B2h     AC5-H    unsigned
      B3h     AC5-L
      B4h     AC6-H    unsigned       
      B5h     AC6-L                   
      B6h     B1-H     signed         
      B7h     B1-L                    
      B8h     B2-H     signed         
      B9h     B2-L                    
      BAh     MB-H     signed         
      BBh     MB-L                    
      BCh     MC-H     signed         
      BDh     MC-L                    
      BEh     MD-H     signed         
      BFh     MD-L                    
                                                                                                            Max conversion time                 
  Register $F4 is the control register, writing $2E starts a temperature measurement                           4.5ms                                                                     
                                                $34 starts pressure measurement with 0 oversample setting      4.5ms          0011_1000         
                                                $74 starts pressure measurement with 1 oversample setting      7.5ms          0111_1000         
                                                $B4 starts pressure measurement with 2 oversample setting     13.5ms          1011_1000         
                                                $F4 starts pressure measurement with 3 oversample setting     25.5ms          1111_1000         
                                                                                                                             ($34 | oss << 6)   

  The measurement, either temperature or pressure as commanded by the write to $F4, is returned as a big-endian 16-bit word in register $F6                                       
  Pressure can be returned as a 19-bit value when using oversampling, the lowest bits are contained in register $F8

      F6h     measurement-H
      F7h     measurement-L
      F8h     measurement-XLSB

}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                      
  _xinfreq = 5_000_000

  SCL = 28
  SDA = 29

CON

  BMP      = $77 ' 7-bit I2C address
  ADC      = $F6 ' Temp and pressure are returned as big-endian 16-bit words - optional 19-bit not supported in this code
  CONTROL  = $F4 ' Control register, writing $34 to this register begins a pressure measurement, $2E starts a temperature measurement
  PRESSURE = $34 ' Written into the control register
  TEMP     = $2E ' Written into the control register
  PROM     = $AA ' Calibration coefficients are stored in registers $AA through $BE as big-endian 16-bit words, read into AC1 through MD
  
VAR
  long  UT,UP                                                                   ' uncalibrated readings from BMP085
  long  T, P                                                                    ' calibrated temperature and pressure
  word  AC1,AC2,AC3,AC4,AC5,AC6,B1,B2,MB,MC,MD                                  ' calibration coefficients

OBJ
  I2C  : "I2C SPIN driver v1.4od"
  FDS  : "FullDuplexSerial"

PUB Main 
  FDS.start(31,30,0,115_200)
  waitcnt(cnt + clkfreq * 2)
  FDS.tx($00)

  if not ina[SCL]
    FDS.str(string("No pullup detected on SCL",$0D))                            
  if not ina[SDA]                                                               
    FDS.str(string("No pullup detected on SDA",$0D))
  if not ina[SDA] or not ina[SCL]
    FDS.str(string(" Use I2C Spin push_pull driver",$0D,"Halting"))                                                              
    repeat                                                                      

  I2C.init(SCL,SDA)

  if not \BMP085_demo                                                           ' The Spin-based I2C drivers abort if there's no response
    FDS.str(string($0D,"BMP085 not responding"))                                '  from the addressed device within 10ms
                                                                                ' An abort trap \ must be used somewhere in the calling code
                                                                                '  or bad things happen if the I2C device fails to respond                  

PUB BMP085_demo

  get_coeffs
  repeat
    get_measurements
    convert_measurements        

    FDS.tx($00)
    FDS.str(string("Temperature: "))
    decF(T,10,2)                                           
    FDS.str(string("°C",$09))
    decf(T * 9 / 5 + 320,10,2)                                                  ' Temperature is converted in 0.1°C
    FDS.str(string("°F",$0D))                                                                

    FDS.str(string("Pressure: "))                                             
    decf(P,100,2)                                                               ' Pressure is converted in Pa
    FDS.str(string(" mb",$0D))

PRI get_coeffs                                                                  '' read calibration coefficients into AC1 through MD

  I2C.readWordsB(BMP,PROM,@AC1,11)                                                                                                                     

PRI get_measurements                                                            '' reads temperature and pressure into UT and UP

  I2C.writeByte(BMP,CONTROL,TEMP)                                               ' start a temperature measurement
  waitcnt(cnt + clkfreq / 10000 * 45)                                           ' wait 4.5ms
  UT := I2C.readWordB(BMP,ADC)                                                  ' read temperature
  I2C.writeByte(BMP,CONTROL,PRESSURE)                                           ' start a pressure measurement - 0 oversampling
  waitcnt(cnt + clkfreq / 10000 * 45)                                           ' wait 4.5ms
  UP := I2C.readWordB(BMP,ADC)                                                  ' read pressure 

PRI convert_measurements | X1, X2, X3, B3, B4, B5, B6, B7, oss                  '' converts uncalibrated UT and UP into calibrated temperature T and pressure P

    X1 := ((UT - AC6) * AC5) ~> 15                                              ' X1 := (UT - AC6) * AC5 / 2^15
    X2 := ~~MC << 11 / (X1 + ~~MD)                                              ' X2 := MC * 2^11 / (X1 + MD)
    B5 := X1 + X2                                                               ' B5 := X1 + X2
    T := (B5 + 8) ~> 4                                                          ' T  := (B5 + 8) / 2^4

    oss := 0                                

    B6 := B5 - 4000                                                             ' B6 := B5 - 4000
    X1 := (B2 * ((B6 * B6) ~> 12)) ~> 11                                        ' X1 := (B2 * (B6 * B6 / 2^12)) / 2^11
    X2 := (~~AC2 * B6) ~> 11                                                    ' X2 := AC2 * B6 / 2^11                                    
    X3 := X1 + X2                                                               ' X3 := X1 + X2                                            
    B3 := (AC1 * 4 + X3) ~> 2            '*                                     ' B3 := ((AC1 * 4 + X3) << oss + 2) / 4
    X1 := (~~AC3 * B6) ~> 13                                                    ' X1 := AC3 * B6 / 2^13
    X2 := (B1 * ((B6 * B6) ~> 12)) ~> 16                                        ' X2 := (B1 * (B6 * B6 / 2^12)) / 2^16                     
    X3 := ((X1 + X2) + 2) ~> 2                                                  ' X3 := ((X1 + X2) + 2) / 2^2                              
    B4 := (AC4 * (X3 + 32768)) ~> 15                                            ' B4 := AC4 * {(unsigned long)}(X3 + 32768) / 2^15
    B7 := (UP - B3) * (50000 >> oss)     '*                                     ' B7 := {((unsigned long))}(UP - B3) * (50000 >> oss)      
    if (B7 < $8000_0000)                                                        ' if (B7 < $8000_0000)                                     
      P := (B7 << 1) / B4                                                       '    p := (B7 * 2) / B4                                    
    else                                                                        ' else                                                     
      P := (B7 / B4) << 1                                                       '    p := (B7 / B4) * 2
    X1 := (P ~> 8) * (P ~> 8)                                                   ' X1 := (p / 2^8) * (p/2^8)                                
    X1 := (X1 * 3038) ~> 16                                                     ' X1 := (X1 * 3038) / 2^16                                 
    X2 := (-7357 * P) / 65536                                                   ' X2 := (-7357 * p) / 2^16                                 
    P := P + (X1 + X2 + 3791) ~> 4                                              ' p := p + (X1 + X2 + 3791) / 2^4

PRI DecF(value,divider,places) | i, x
{
  DecF(1234,100,3) displays "12.340"
}

  if value < 0
    || value                                                                    ' If negative, make positive                   
    fds.tx("-")                                                                 ' and output sign                              
  else                                                                                                                         
    fds.tx(" ")                                                                                                                
                                                                                                                               
  i := 1_000_000_000                                                            ' Initialize divisor                           
  x := value / divider                                                                                                         
                                                                                                                               
  repeat 10                                                                     ' Loop for 10 digits                           
    if x => i                                                                                                                  
      fds.tx(x / i + "0")                                                       ' If non-zero digit, output digit              
      x //= i                                                                   ' and remove digit from value                  
      result~~                                                                  ' flag non-zero found                          
    elseif result or i == 1                                                                                                    
      fds.tx("0")                                                               ' If zero digit (or only digit) output it      
    i /= 10                                                                     ' Update divisor                               
                                                                                                                               
  fds.tx(".")                                                                                                                  
                                                                                                                               
  i := 1                                                                                                                       
  repeat places                                                                                                                
    i *= 10                                                                                                                    
                                                                                                                               
  x := value * i / divider                                                                                                     
  x //= i                                                                       ' limit maximum value                          
  i /= 10                                                                                                                      
    
  repeat places
    fds.Tx(x / i + "0")
    x //= i
    i /= 10    

DAT '=======================================================================================================================================================
' methods borrowed from the Parallax 29124_altimeter object
 
PRI _umultdiv(x, num, denom) | producth, productl

  {{ Multiply `x and `num, then divide the resulting unsigned, 64-bit product by
     `denom to yield a 32-bit unsigned result. `x ** `num must be less than (unsigned) `denom.
  }}

  _umult(@producth, x, num)
  return _udiv(producth, productl, denom)   

PRI _umult(productaddr, mplr, mpld) | producth, productl

  {{ Multiply `mplr by `mpld and store the unsigned 64-bit product at `productaddr.
  }}

  producth := (mplr & $7fff_ffff) ** (mpld & $7fff_ffff)
  productl := (mplr & $7fff_ffff) * (mpld & $7fff_ffff)
  if (mplr < 0)
    _dadd(@producth, mpld >> 1, mpld << 31)
  if (mpld < 0)
    _dadd(@producth, mplr << 1 >> 2, mplr << 31)
  longmove(productaddr, @producth, 2)

PRI _udiv(dvndh, dvndl, dvsr) | carry, quotient

  {{ Divide the unsigned 64-bit number `dvndh:`dvndl by `dvsr, returning an unsigned 32-bit quotient.
     Saturate result to $ffff_ffff if it's too big to fit 32 bits.
  }}

  quotient~
  ifnot (_ult(dvndh, dvsr))
    return $ffff_ffff
  repeat 32
    carry := dvndh < 0
    dvndh := (dvndh << 1) + (dvndl >> 31)
    dvndl <<= 1
    quotient <<= 1
    if (not _ult(dvndh, dvsr) or carry)
      quotient++
      dvndh -= dvsr
  return quotient

PRI _dsub(difaddr, subh, subl)

  {{ Subtract the 64-bit value `subh:`subl from the 64-bit value stored at `difaddr.
  }}
  
  _dadd(difaddr, -subh - 1, -subl)

PRI _dadd(sumaddr, addh, addl) | sumh, suml

  {{ Add the 64-bit value `addh:`addl to the 64-bit value stored at `sumaddr.
  }}

  longmove(@sumh, sumaddr, 2)
  sumh += addh
  suml += addl
  if (_ult(suml, addl))
    sumh++
  longmove(sumaddr, @sumh, 2)

PRI _ult(x, y)

  {{ Test for unsigned `x < unsigned `y. Return `true if less than; `false, otherwise. 
  }}

  return x ^ $8000_0000 < y ^ $8000_0000
    
DAT                     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                
