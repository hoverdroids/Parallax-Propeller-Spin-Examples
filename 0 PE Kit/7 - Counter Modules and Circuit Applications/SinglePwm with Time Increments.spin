''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''SinglePwm with Time Increments.spin

CON
   
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000

PUB TestPwm | tc, tHa, t, tInc

  ctra[30..26] := %00100                     ' Configure Counter A to NCO
  ctra[5..0] := 4                            ' Set counter output signal to P4
  frqa := 1                                  ' Add 1 to phsa with each clock cycle
  dira[4]~~                                  ' P4 → output

  tInc := clkfreq/1_000_000                  ' Determine time increment
  tC := 500_000 * tInc                       ' Use time increment to set up cycle time
  tHa := 100_000 * tInc                      ' Use time increment to set up high time

  ' The rest is the same as 1Hz25PercentDutyCycle.spin

  t := cnt                                   ' Mark counter time
  
  repeat                                     ' Repeat PWM signal
    phsa := -tHa                             ' Set up the pulse
    t += tC                                  ' Calculate next cycle repeat
    waitcnt(t)                               ' Wait for next cycle