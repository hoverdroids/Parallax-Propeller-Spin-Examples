''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' TestIrDutyDistanceDetector.spin
'' Test distance detection with IrDetector object.

CON

  _xinfreq = 5_000_000                      
  _clkmode = xtal1 + pll16x

  CLS = 16, CRSRX = 14, CLREOL = 11

OBJ

  ir     : "IrDetector"
  debug  : "FullDuplexSerialPlus"
  

PUB TestIr | dist

  'Start serial communication, and wait 2 s for Parallax Serial Terminal connection.

  debug.Start(31, 30, 0, 57600)
  waitcnt(clkfreq * 2 + cnt)
  debug.tx(CLS)
  debug.str(string("Distance = "))
  'Configure IR detectors.
  ir.init(1, 2, 0)                   

  repeat            
    'Get and display distance.
    debug.str(string(CRSRX, 11))
    dist := ir.Distance
    debug.dec(dist)
    debug.str(string("/256", CLREOL))
    waitcnt(clkfreq/3 + cnt)