''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''BetterCountEdges.spin

CON
   
  _clkmode = xtal1 + pll16x                   'System clock → 80 MHz
  _xinfreq = 5_000_000


OBJ
   
  SquareWave      : "SquareWave"

PUB TestFrequency | a, b, c 
  
  ' Configure counter modules.

  ctra[30..26] := %00100                     'ctra module to NCO mode
  ctra[5..0] := 27  
  outa[27]~                                  'P27 → output-low
  dira[27]~~             

  ctrb[30..26] := %01010                     'ctrb module to POSEDGE detector         
  ctrb[5..0] := 27
  frqb := 1                                  'Add 1 for each cycle
  phsb := -3000                              'Start the count at -3000

  a := |< 27                                 'Set up a pin mask for the waitpeq command
  
  frqa := SquareWave.NcoFrqReg(3000)         'Start the square wave
  repeat while phsb[31]                      'Wait for 3000th low→high transition
  waitpeq(0, a, 0)                           'Wait for low signal
  frqa~                                      'Stop the signal