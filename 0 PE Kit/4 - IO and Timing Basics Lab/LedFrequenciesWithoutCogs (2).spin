''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
''File: LedFrequenciesWithoutCogs.spin
''Experience the discomfort of developing proceses that could otherwise run
''indendently in separate cogs.  In this example, LEDs blink at 1, 2, 3, 5,
''7, and 11 Hz.

CON

    _xinfreq = 5_000_000                     ' 5 MHz external crystal 
    _clkmode = xtal1 + pll16x                ' 5 MHz crystal multiplied → 80 MHz

    T_LED_P4 = 2310                          ' Time increment constants
    T_LED_P5 = 1155
    T_LED_P6 = 770
    T_LED_P7 = 462
    T_LED_P8 = 330
    T_LED_P9 = 210
    
PUB Blinks | T, dT, count

    dira[9..4]~~                             ' Set LED I/O pins to output

       dT := clkfreq / 4620                  ' Set time increment 
       T  := cnt                             ' Mark current time

    repeat                                   ' Main loop

       T += dT                               ' Set next cnt target
       waitcnt(T)                            ' Wait for target

       if ++ count == 2310                   ' Reset count every 2310
         count := 0                        

       ' Update each LED state at the correct count.
       if count // T_LED_P4 == 0             
         !outa[4]
       if count // T_LED_P5 == 0
         !outa[5]
       if count // T_LED_P6 == 0
         !outa[6]
       if count // T_LED_P7 == 0
         !outa[7]
       if count // T_LED_P8 == 0
         !outa[8]
       if count // T_LED_P9 == 0
         !outa[9]