''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''LedSweepWithSpr.spin
''Cycle P4 and P5 LEDs through off, gradually brighter, brightest at different rates.

CON

  scale = 16_777_216                               ' 2³²÷ 256

PUB TestDuty | apin, duty[2], module

  'Configure both counter modules with a repeat loop that indexes SPR elements.

  repeat module from 0 to 1                        ' 0 is A module, 1 is B.
    apin := lookupz (module: 4, 6)
    spr[8 + module] := (%00110 << 26) + apin
    dira[apin]~~

  'Repeat duty sweep indefinitely.

  repeat                                                     
    repeat duty from 0 to 255                      ' Sweep duty from 0 to 255
      duty[1] := duty[0] * 2                       ' duty[1] twice as fast
      repeat module from 0 to 1                    
        spr[10 + module] := duty[module] * scale   ' Update frqa register
      waitcnt(clkfreq/128 + cnt)                   ' Delay for 1/128th s