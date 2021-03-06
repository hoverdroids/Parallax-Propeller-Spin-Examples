{{
   ***************************************
   * API_Base                            *
   ***************************************
   *  See end of file for terms of use.  *               
   ***************************************

   Interacts with XBee for various API modes supported by
   the API_Object. Use a remote node on USB Adapter for testing.
   
   *******************************************************
   * Martin Hebel, Electronic Systems Technologies, SIUC *
   * Version 1.0                                         *
   *******************************************************
     
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' Set pins and Baud rate for XBee comms  
  XB_Rx     = 0    ' XBee DOUT
  XB_Tx     = 1    ' XBee DIN
  XB_Baud   = 9600 ' XBee Baud Rate

  ' Set pins and baud rate for PC comms 
  PC_Rx     = 31  
  PC_Tx     = 30
  PC_Baud   = 9600
   
  CR = 13          ' Carriage Return
     
OBJ
   XB    : "XBee_Object"
   PC    : "XBee_Object" ' Using XBee object on PC side for more versatility
   Num   : "Numbers"  

VAR
  Long Stack[100]
  Byte strIn[105]   

Pub  Start | DataIn 
  XB.Delay(3000)
  PC.start(PC_Rx, PC_Tx, 0, PC_Baud) ' Initialize comms for PC
  PC.str(string("Configuring XBee...",CR)) 
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  XB.AT_Init                         ' Set for fast Command mode
  XB.SetFrameID(1)

  XB.AT_Config(string("ATAP 1",13))  ' Configure XBee for API Mode
  
  cognew(AcceptData,@stack)
  Menu
  


Pub Menu | Choice, Value, Addr,  ptr
  Repeat
    PC.rxFlush
    PC.str(string(13,13," \\\\\\\\\\\\ MENU ///////////// "))
    PC.str(string(13," 1 - Send Character"))
    PC.str(string(13," 2 - Send Value "))
    PC.str(string(13," 3 - Send String "))
    PC.str(string(13," 4 - Send string + value"))
    PC.str(string(13," 5 - Configure local "))
    PC.str(string(13," 6 - Query Local "))
    PC.str(string(13," 7 - Configure Remote"))
    PC.str(string(13," 8 - Query Remote"))
    PC.str(string(13," 9 - Set Frame ID (0 for no response)"))
    PC.str(string(13," 0 - Measure PWM in counter counts"))
    PC.str(string(13," Any other key to repeat menu "))
    Choice := PC.rx 
    Case Choice
       "1":  ' Send character
             PC.str(string(13,13,"Enter address of remote node (Hex): "))
             Addr := PC.RxHex
             PC.str(string("Enter character to send: "))
             Value := PC.Rx
             XB.API_Tx(Addr, Value)
             PC.str(string(13,"Character sent!"))
             XB.Delay(2000)

       "2":  ' Send value
             PC.str(string(13,13,"Enter address of remote node (Hex): "))
             Addr := PC.RxHex
             PC.str(string("Enter Value to send (Decimal): "))
             Value := PC.RxDec
             XB.API_str(Addr, num.toStr(Value,num#dec))
             PC.str(string("Value sent!"))
             XB.Delay(2000)
             
       "3":  ' Send string
             PC.str(string(13,13,"Enter address of remote node (Hex): "))
             Addr := PC.RxHex
             PC.str(string("Enter string to send: "))
             ptr := 0
             repeat
                strIn[ptr++] := PC.Rx
             while (strIn[ptr-1] <> 13) and (ptr < 100)
             strIn[ptr-1] := 0                     
             XB.API_str(Addr, @strIn)
             PC.str(string("String Sent!"))
             XB.Delay(2000)

       "4":  ' Send string and value
             PC.str(string(13,13,"Enter address of remote node (Hex): "))
             Addr := PC.RxHex
             PC.str(string("Enter string to send: "))
             ptr := 0
             repeat
                strIn[ptr++] := PC.Rx
             while (strIn[ptr-1] <> 13) and (ptr < 100)
             strIn[ptr-1] := 0                     
             PC.RxFlush
             PC.str(string("Enter Value to Send (Decimal): "))
             Value := PC.RxDec
             XB.API_NewPacket
             XB.API_AddStr(@strIn)
             XB.API_AddStr(num.toStr(Value,num#dec))
             XB.API_AddByte(13)
             XB.API_str(Addr,XB.API_Packet)
             PC.str(string("String & Value Sent!"))
             XB.Delay(2000)

       "5":  ' Configure local
             PC.str(string(13,13,"Enter 2-letter Command Code: "))
             strIn[0] := PC.rx
             strIn[1] := PC.rx
             strIn[2] := 0
             PC.str(string(13,"Enter Value (Hex): "))
             Value := PC.RxHex
             XB.API_Config(@StrIn, value)
             PC.str(string("Configuration Sent!"))
             XB.Delay(2000)
    
       "6":  ' Query local
             PC.str(string(13,13,"Enter 2-letter Command Code: "))
             strIn[0] := PC.rx
             strIn[1] := PC.rx
             strIn[2] := 0
             XB.API_Query(@StrIn)
             PC.str(string(13,"Query Sent!"))
             XB.Delay(2000)

       "7":  ' Configure remote
             PC.str(string(13,13,"Enter address of remote node (Hex): "))
             Addr := PC.RxHex
             PC.str(string(13,"Enter 2-letter Command Code: "))
             strIn[0] := PC.rx
             strIn[1] := PC.rx
             PC.str(string(13,"Enter Value (Hex): "))
             Value := PC.RxHex
             XB.API_RemConfig(Addr,@StrIn, value)
             PC.str(string(13,"Remote Configuration Sent!"))
             XB.Delay(2000)
    
       "8":  ' Query remote
             PC.str(string(13,13,"Enter address of remote node (Hex): "))
             Addr := PC.RxHex
             PC.str(string(13,"Enter 2-letter Command Code: "))
             strIn[0] := PC.rx
             strIn[1] := PC.rx
             XB.API_RemQuery(Addr, @StrIn)
             PC.str(string(13,"Remote Query Sent!"))
             XB.Delay(2000)                

       "9":  ' Set frame ID
             PC.str(string(13,13,"Enter Frame ID: "))
             value := PC.RxDec
             XB.SetFrameID(value)
             PC.str(string("Frame ID Set"))
             XB.Delay(2000)

       "0":  ' Read PWM on pin
             PC.str(string(13,13,"Enter Pin for PWM measurement"))
             PC.str(string(13,13,"Press any key to exit")) 
             Value := PC.RxDec
             repeat while PC.RxCheck == -1
                PC.str(string("PWM duration in clock counts = "))
                PC.DEC(PulsIn_Clk(Value,0))
                PC.CR
                PC.Delay(250)
                
    
   
Pub AcceptData| DataIn,Value, Ch
' Accept incoming frames of data from XBee
  repeat
    XB.API_Rx
    PC.Str(string(13,13,"***** Rx Data Ident: $"))
    PC.Hex(XB.RxIdent,2)
    case XB.RxIdent

      $81:                    ' 16-Bit Rx Data
         PC.str(string(13,"16-Bit Addr Rx data"))
         PC.str(string(13," From Address:  "))
         PC.hex(XB.srcAddr,4)
         PC.str(string(13," RSSI Level:    ")) 
         PC.Dec(-XB.RxRSSI)
         PC.str(string(13," Data Length:   "))
         PC.dec(XB.RxLen)
         PC.str(string(13," Data Contents: "))
         PC.Str(XB.RxData)                     ' Display whole message
         PC.Str(string(13,"   1st Value:   "))
         Value := XB.ParseDec(XB.RxData,1)     ' Display 1st decimal value
         PC.Dec(Value)
         PC.Str(string(13,"   2nd Value:   "))
         Value := XB.ParseDec(Xb.RxData,2)     ' Display 2nd decimal value
         PC.Dec(Value)
         XB.API_str(XB.srcAddr,string("OK"))

      $83:                     ' ADC / Digital I/O Data
         PC.str(string(13,"ADC/Digitial data"))
         PC.str(string(13," From Address:  "))
         PC.hex(XB.srcAddr,4)
         PC.str(string(13," RSSI Level:    ")) 
         PC.Dec(-XB.RxRSSI)
         PC.str(string(13," Data Length:   "))
         PC.dec(XB.RxLen)
         PC.str(string(13," Data Contents: "))
         repeat ch from 0 to XB.RxLen - 1        ' Loop through each data byte
           PC.Hex(byte[XB.RxData][ch],2)         ' Show hex value of each data byte
           PC.Tx(" ")
         repeat ch from 0 to 5                   ' loop through ADC Channels
           If XB.rxADC(ch) <> -1                 ' If not -1, data on channel
             PC.str(string(13,"      ADC CH "))
             PC.Dec(ch)                          ' display channel
             PC.str(string(": "))
             PC.Dec(XB.rxADC(Ch))                ' display channel data
             PC.str(string(" = "))
             PC.Dec(XB.rxADC(Ch) * 3300 / 1023)  ' display in millivolts
             PC.str(string(" mV"))
         PC.str(string(13,"      Dig Data: "))
         PC.Bin(XB.RxDig,8)          
         repeat ch from 0 to 8                   ' loop through Digital Channels
           If XB.rxBit(ch) <> -1                 ' if not 0, data present
             PC.str(string(13,"      Dig Bit:"))
             PC.Dec(ch)                          ' display channel
             PC.str(string(": "))
             PC.Dec(XB.rxBit(Ch))                ' display channel data 

      $89:                     ' Tx Status
         PC.str(string(13,"Transmit Status"))  
         PC.str(string(13,"   Status: "))
         PC.Dec(XB.Status)
         Case XB.Status                          ' Display status
            0: PC.str(string("- ACK"))     
            1: PC.str(string("- NO ACK"))
            2: PC.str(string("- CCA Failure"))
            0: PC.str(string("- Purged"))

      $88:                     ' Command Response
         PC.str(string(13,"Local Config/Query Response"))
         PC.str(string(13," Status:         "))
         PC.Dec(XB.Status)
         Case XB.Status
            0:  PC.str(string(" - OK"))
            1:  PC.str(string(" - Error"))
            2:  PC.str(string(" - Invalid Command"))
            3:  PC.Str(string(" - Invalid Parameter"))
         PC.str(string(13," Command Response")) 
         PC.str(string(13,"   Command Sent:         "))
         PC.str(XB.RxCmd)
         PC.str(string(13,"   Data (valid on Query):"))
         PC.hex(XB.RxValue,4)

      $97:
         PC.str(string(13,"Remote Query/Configuration"))
         PC.str(string(13," From Address:    "))
         PC.hex(XB.srcAddr,4)
         PC.str(string(13," Status:          "))
         PC.Dec(XB.Status)
         Case XB.Status
            0:  PC.str(string(" - OK"))
            1:  PC.str(string(" - Error"))
            2:  PC.str(string(" - Invalid Command"))
            3:  PC.Str(string(" - Invalid Parameter"))
            4:  PC.str(string(" - No Response"))
         PC.str(string(13," Command Response")) 
         PC.str(string(13,"   Command Sent:          "))
         PC.str(XB.RxCmd)
         PC.str(string(13,"   Data (valid on Query): "))
         PC.hex(XB.RxValue,4)
         
    PC.CR

PUB PULSIN_CLK(Pin, State) : Duration 
{{
  Reads duration of Pulse on pin defined for state, returns duration in 1/clkFreq increments - 12.5nS at 80MHz
  Note: Absence of pulse can cause cog lockup if watchdog is not used.
}}

  DIRA[pin]~
  ctra := 0
  if state == 1
    ctra := (%11010 << 26 ) | (%001 << 23) | (0 << 9) | (PIN) ' set up counter, A level count
  else
    ctra := (%10101 << 26 ) | (%001 << 23) | (0 << 9) | (PIN) ' set up counter, !A level count
  frqa := 1
  waitpne(State << pin, |< Pin, 0)                         ' Wait for opposite state ready
  phsa:=0                                                  ' Clear count
  waitpeq(State << pin, |< Pin, 0)                         ' wait for pulse
  waitpne(State << pin, |< Pin, 0)                         ' Wait for pulse to end
  Duration := phsa                                         ' Return duration as time
  ctra :=0                      
                
    
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