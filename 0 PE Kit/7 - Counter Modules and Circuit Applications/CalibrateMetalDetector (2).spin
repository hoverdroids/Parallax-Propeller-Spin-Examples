''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' CalibrateMetalDetector.spin

CON
   
  _clkmode = xtal1 + pll16x            ' Set up 80 MHz system clock
  _xinfreq = 5_000_000

OBJ                                   
   
  pst     : "Parallax Serial Terminal"
  frq     : "SquareWave"


PUB Init | count, f, fstart, fstep, c

  'Start Parallax Serial Terminal
  pst.Start(115_200)

  'Configure ctra module for 50 MHz square wave
  ctra[30..26] := %00010
  ctra[25..23] := %110            
  ctra[5..0] := 15                    
  frq.Freq(0, 15, 50_000_000)                         
  dira[15]~~
  
  'Configure ctrb module for negative edge counting
  ctrb[30..26] := %01000               
  ctrb[5..0] := 13
  frqb := 1

  c := "S"

  repeat until c == "Q" or c == "q" 

    case c 
      "S", "s":
        pst.Str(String("Starting Frequency: "))
        f := pst.DecIn
        pst.Str(String("Step size: "))
        fstep := pst.DecIn
         
    case c
      "S", "s", 13, 10, "M", "m":
        repeat 22
          frq.Freq(0, 15, f)   
          count := phsb
          waitcnt(clkfreq/10000 + cnt)                      
          count := phsb - count
          pst.Str(String(pst#NL, "Freq = "))
          pst.Dec(f)
          pst.Str(String("  count = "))
          pst.Dec(count)
          waitcnt(clkfreq/20 + cnt)
          f += fstep
         
        pst.Str(String(pst#NL,"Enter->more, Q->Quit, S->Start over, R->repeat: "))
        c := pst.CharIn
        pst.NewLine

      "R", "r":
        f -= (22 * fstep)
        c := "m"
     
      "Q", "q": quit

  pst.Str(String(pst#NL, "Bye!"))                  

