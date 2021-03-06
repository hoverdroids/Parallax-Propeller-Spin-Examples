''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' IrObjectDetection.spin
'' Detect objects with IR LED and receiver and display with Parallax Serial Terminal.

CON
   
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000
VAR
byte sqrPin
byte detectPin
OBJ
   
  pst        : "Parallax Serial Terminal"
  SqrWave    : "SquareWave"

PUB IrDetect | state
sqrPin:=8
detectPin:=9

  'Start 38 kHz square wave
  SqrWave.Freq(0, sqrPin, 38000)                  ' 38 kHz signal → P8
  dira[sqrPin]~                                   ' Set I/O pin to input when no signal needed

  'Start Parallax Serial Terminal
  pst.Start(115_200)                          

  repeat

    ' Detect object.
    dira[sqrPin]~~                                ' I/O pin → output to transmit 38 kHz
    waitcnt(clkfreq/1000 + cnt)              ' Wait 1 ms
    state := ina[detectPin]                          ' Store I/R detector output
    dira[sqrPin]~                                 ' I/O pin → input to stop signal

    ' Display detection (0 detected, 1 not detected)
    pst.Str(String(pst#HM, "State = "))
    pst.Dec(state)
    pst.Str(String(pst#NL, "Object "))
    if state == 1
      pst.Str(String("not "))
    pst.str(String("detected.", pst#CE))
    waitcnt(clkfreq/10 + cnt)
