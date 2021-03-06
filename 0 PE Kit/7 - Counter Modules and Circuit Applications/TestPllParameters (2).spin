''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
{{ 
TestPllParameters.spin

Tests PLL frequencies up to 40 MHz.  PHS register and PLLDIV bit field values are
entered into Parallax Serial Terminal.  The Program uses these to synthesize square wave with PLL mode using counter module A.  Counter module B counts the cycles in 1 s
and reports it.
}}

CON
   
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000

OBJ
   
  SqrWave  : "SquareWave"
  pst      : "Parallax Serial Terminal"

PUB TestFrequency | delay, cycles 
  
  pst.Start(115_200)

  ' Configure counter modules.
  ctra[30..26] := %00010                     'ctra module to PLL single-ended mode
  ctra[5..0] := 15
   
  ctrb[30..26] := %01110                     'ctrb module to NEGEDGE detector         
  ctrb[5..0] := 15
  frqb:= 1
   
  repeat
  
    pst.Str(String("Enter frqa: "))        'frqa and PLLDIV are user input
    frqa := pst.DecIn

    pst.Str(String("Enter PLLDIV: "))
    ctra[25..23] := pst.DecIn

    dira[15]~~                               'P15 → output
    delay := clkfreq + cnt                   'Precalculate delay ticks
    phsb~                                    'Wait 1 s.
    waitcnt(delay)
    cycles := phsb                           'Store cycles
    dira[15]~                                'P15 → input
     
    pst.Str(String("f = "))                'Display cycles as frequency
    pst.Dec(cycles)
    pst.Str(String(" Hz", pst#NL, pst#NL))                     
