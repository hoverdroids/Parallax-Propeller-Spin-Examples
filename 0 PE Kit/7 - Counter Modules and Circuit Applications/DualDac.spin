''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
{{
''DualDac.spin

''Provides the two counter module channels from another cog for D/A conversion

How to Use this Object in Your Application
------------------------------------------
1) Declare variables to hold D/A values.  Example:
   
   VAR 
     ch[2]

2) Declare the DualDac object.  Example:
   
   OBJ 
     dac : DualDac

3) Call the start method.  Example:

   PUB MethodInMyApp
     '... 
     dac.start

4) Set D/A outputs.  Example:
     ch[0] := 3000
     ch[1] := 180

5) Configure the DAC Channel(s).  Example:
     'Channel 0, pin 4, 12-bit DAC, ch[0] stores the DAC value.  
     dac.Config(0,4,12,@ch[0])
     'Since ch[0] was set to 3000 in Step 4, the DAC's P4 output will be
     '3.3V * (3000/4096)

     'Channel 1, pin 6, 8-bit DAC, ch[1] stores the DAC value.  
     dac.Config(1,6,8,@ch[1])
     'Since ch[1] was set to 180 in Step 4, the DAC's P6 output will be
     ' 3.3V * (180/256)

6) Methods and features in this object also make it possible to:
       - remove a DAC channel
       - change a DAC channel's:
           o I/O pin
           o Resolution
           o Control variable address
           o Value stored by the control variable
     
See Also
--------
TestDualDac.spin for an application example.

}}

VAR                                         ' Global variables
  long cog, stack[30]                       ' For object
  long cmd, ch, pin[2], dacAddr[2], bits[2] ' For cog info exhcanges

PUB Start : okay

  '' Launches a new D/A cog.  Use Config method to set up a dac on a given pin.

  okay := cog := cognew(DacLoop, @stack) + 1

PUB Stop

  '' Stops the DAC process and frees a cog.

  if cog
    cogstop(cog~ - 1)

PUB Config(channel, dacPin, resolution, dacAddress)

  '' Configure a DAC.  Blocks program execution until other cog completes command.
  ''   channel    - 0 = channel 0, 1 = channel 1
  ''   dacPin     - I/O pin number that performs the D/A
  ''   resolution - bits of D/A conversion (8 = 8 bits, 12 = 12 bits, etc.)
  ''   dacAddress - address of the variable that holds the D/A conversion level, 
  ''                a value between 0 and (2^resolution) - 1.

  ch                :=  channel             ' Copy paramaters to global variables. 
  pin[channel]      :=  dacPin
  bits[channel]     :=  |<(32-resolution)
  dacAddr[channel]  :=  dacAddress
  cmd               :=  4                   ' Set command for PRI DacLoop.
  repeat while cmd                          ' Block execution until cmd completed.

PUB Remove(channel)

  '' Remove a channel. Sets channels I/O pin to input & clears the counter module.
  '' Blocks program execution until other cog completes command.
  
  ch   :=  channel                          ' Copy parameter to global variable.
  cmd  :=  5                                ' Set command for PRI DacLoop.
  repeat while cmd                          ' Block execution until cmd completed.
  
PUB Update(channel, attribute, value)

  '' Update a DAC channel configuration.
  '' Blocks program execution until other cog completes command.
  ''   channel    - 0 = channel 0, 1 = channel 1
  ''   attribute  - the DAC attribute to update
  ''     0 -> dacPin
  ''     1 -> resolution
  ''     2 -> dacAddr
  ''     3 -> dacValue
  ''   value      - the value of the attribute to be updated

  ch  := channel                            ' Copy parameter to global variable. 
  case attribute                            ' attribute param decides what to do.
    0 :                                     ' 0 = change DAC pin.
      cmd := attribute + (value << 16)      ' I/O pin in upper 16 bits, lower 16
                                            ' cmd = 0.
    ' Options 1 through 3 do not require a command for PRI DacLoop -> PRI DacConfig.
    ' They just require that certain global variables be updated.
    1 : bits[ch] := |<(32-value)            ' 1 = Change resolution.
    2 : dacAddr[channel] := value           ' 2 = Change control variable address. 
    3 : long[dacAddr] := value              ' 3 = Change control variable value.
  repeat while cmd                          ' Block execution until cmd completed.

PRI DacLoop | i                             ' Loop checks for cmd, then updates
                                            '   DAC output values.
  repeat                                    ' Main loop for launched cog.
    if cmd                                  ' If cmd <> 0
       DacConfig                            '   then call DatConfig
    repeat i from 0 to 1                    ' Update counter module FRQA & FRQB.                        
       spr[10+i] := long[dacAddr][i] * bits[i]
       
PRI DacConfig | temp                        ' Update DAC configuration based on cmd.

  temp := cmd >> 16                         ' If update attribute = 0, temp gets 
                                            '   pin.
  case cmd & $FF                            ' Mask cmd and evalueate case by case.
    4:                                      ' 4 -> Configure DAC.
      spr[8+ch] := (%00110 << 26) + pin[ch] ' Store mode and pin in CTR register.
      dira[pin[ch]]~~                       ' Pin direction -> outpup.
    5:                                      ' 5 -> Remove DAC.
      spr[8+ch]~                            ' Clear CTR register.
      dira[pin[ch]]~                        ' Make I/O pin input.
    0:                                      ' 0 -> update pin.
      dira[pin[ch]]~                        ' Make old pin input.
      pin[ch] := temp                       ' Get new pin from temp local
                                            '  variable.
      spr[8+ch] := (%00110 << 26) + pin[ch] ' Update CTR with new pin.
      dira[pin[ch]]~~                       ' Update new I/O pin direction -> 
                                            '   output.
  cmd := 0                                  ' Clear cmd to stop blocking in 
                                            '   other cog.