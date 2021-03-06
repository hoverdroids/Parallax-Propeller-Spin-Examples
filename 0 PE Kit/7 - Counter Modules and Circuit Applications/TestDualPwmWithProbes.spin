''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
{{
TestDualPwmWithProbes.spin
Demonstrates how to use an object that uses counters in another cog to measure (probe) I/O
pin activity caused by the counters in this cog.
}}

CON
   
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000

  ' Parallax Serial Terminal constants
  CLS = 16, CR = 13, CLREOL = 11, CRSRXY = 2

OBJ

  debug : "FullDuplexSerialPlus"
  probe : "MonitorPWM"

PUB TestPwm | tc, tHa, tHb, t, tHprobe, tLprobe, pulseCnt 

  ' Start MonitorServoControlSignal.
  probe.start(8, @tHprobe, @tLprobe, @pulseCnt)

  'Start FullDuplexSerialPlus.
  Debug.start(31, 30, 0, 57600)
  waitcnt(clkfreq * 2 + cnt)
  Debug.str(String(CLS, "Cycle Times", CR, "(12.5 ns clock ticks)", CR))

  Debug.str(String("tH = ", CR))
  Debug.str(String("tL = ", CR))
  Debug.str(String("reps = "))

  ctra[30..26] := ctrb[30..26] := %00100     ' Counters A and B → NCO single-ended
  ctra[8..0] := 4                            ' Set pins for counters to control
  ctrb[8..0] := 6       
  frqa := frqb := 1                          ' Add 1 to phs with each clock tick
                         
  dira[4] := dira[6] := 1                    ' Set I/O pins to output

  tC := clkfreq                              ' Set up cycle time
  tHa := clkfreq/2                           ' Set up high times for both signals
  tHb := clkfreq/5
  t := cnt                                   ' Mark current time.
  
  repeat                                     ' Repeat PWM signal
    phsa := -tHa                             ' Define and start the A pulse
    phsb := -tHb                             ' Define and start the B pulse
    t += tC                                  ' Calculate next cycle repeat

    ' Display probe information
    debug.str(String(CLREOL, CRSRXY, 5, 2))
    debug.dec(tHprobe)
    debug.str(String(CLREOL, CRSRXY, 5, 3))
    debug.dec(tLprobe)
    debug.str(String(CLREOL, CRSRXY, 7, 4))
    debug.dec(pulseCnt)
     
    waitcnt(t)                               ' Wait for next cycle