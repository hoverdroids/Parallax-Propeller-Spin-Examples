''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' TestRcDecay (Modified for Concurrent Measurements).spin
'' Test RC decay measurements on two circuits concurrently.

CON
   
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000

OBJ
   
  pst : "Parallax Serial Terminal"           ' Use with Parallax Serial Terminal to
                                             ' display values 
   
PUB Init

  'Start Parallax Serial Terminal; waits 1 s for you to click Enable button

  pst.Start(115_200)

  ' Configure counter modules.

  ctra[30..26] := %01000                     ' Set CTRA mode to "POS detector"
  ctra[5..0] := 17                           ' Set APIN to 17 (P17)
  frqa := 1                                  ' Increment phsa by 1 for each clock tick

  ctrb[30..26] := %01000                     ' Set CTRB mode to "POS detector"
  ctrb[5..0] := 25                           ' Set APIN to 25 (P25)
  frqb := 1                                  ' Increment phsb by 1 for each clock tick

  main                                       ' Call the Main method

PUB Main | time[2]

'' Repeatedly takes and displays P17 RC decay measurements.

  repeat

     ' Charge RC circuits.

     dira[17] := outa[17] := 1               ' Set P17 to output-high
     dira[25] := outa[25] := 1               ' Set P25 to output-high
     waitcnt(clkfreq/10_000 + cnt)           ' Wait for circuit to charge
      
     ' Start RC decay measurements...

     phsa~                                   ' Clear the phsa register
     dira[17]~                               ' Pin to input stops charging circuit
     phsb~                                   ' Clear the phsb register
     dira[25]~                               ' Pin to input stops charging circuit

     ' Optional - do other things during the measurement.

     pst.Str(String(pst#NL, pst#NL, "Working on other tasks", pst#NL))
     repeat 22
       pst.Char(".")
       waitcnt(clkfreq/60 + cnt)        

     ' Measurement has been ready for a while.  Adjust ticks between phsa~
     ' and dira[17]~.  Repeat for phsb~ and dira[25]~.
 
     time[0] := (phsa - 624) #> 0                
     time[1] := (phsb - 624) #> 0                
     
     ' Display Results                                  

     pst.Str(String(pst#NL, "time[0] = "))
     pst.Dec(time[0])
     pst.Str(String(pst#NL,"time[1] = "))
     pst.Dec(time[1])
     waitcnt(clkfreq/2 + cnt)