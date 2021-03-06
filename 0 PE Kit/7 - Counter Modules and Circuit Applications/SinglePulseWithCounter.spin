''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''SinglePulseWithCounter.spin
''Send a high pulse to the P4 LED that lasts exactly 80_000_000 clock ticks.

CON

  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000

PUB TestPwm | tc, tHa, tHb, ti, t
 
  ctra[30..26] := %00100                     ' Configure Counter A to NCO
  ctra[5..0] := 4
  frqa := 1
  dira[4]~~

  phsa := - clkfreq                          ' Send the pulse

  ' Keep the program running so the pulse has time to finish.
  repeat 