CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000          'or 5_000_000 based on your crystal

OBJ
  router   :       "(HoverDroids) SerialPorts 128Byte Banks 0-3"

CON
  numports = 4  'actual number of ports we are using (needs to match info in DAT below)

DAT   '                   0      1         2        3     Port
  inputpins      byte    31,    31,       31,      31    'Hardware input pin
  outputpins     byte    30,    30,       30,      30    'Hardware output pin
  inversions     byte %0000, %0000,    %0000,   %0000    'Signal flags (open collector, inversion etc.)
  baudrates      long   300,  9600,   115200,  250000    'Baud rate

PUB Main | port, mystr
  'Always initialize the router
  router.init

  'Add each of the ports listed in the DAT section above
  repeat numports
    if (byte[@inputpins+port] < 32) and (byte[@outputpins+port] < 32)
      router.AddPortNoHandshake(port,byte[@inputpins+port],byte[@outputpins+port],byte[@inversions+port],long[@baudrates+port*4])
    port++

  'Start the router so we can send data between ports
  router.start

  'Send
  repeat
    router.str(3,string("ABCDEF1"))
    'router.dec(0,1.4)
    'router.beep(0)
                                                              'Set Parallax Serial Terminal to 115200 baud
{{

  pst.Start(115_200)

  '-------- Demo 1 --------
  pst.Str(@DemoHeader)                                                          'Print header; uses string in DAT section.
  pst.Chars("-", strsize(@DemoHeader))                                          'Use Chars method to output hyphens "-"
  pst.Str(String(pst#NL, pst#NL, "*** Number Feedback Example ***"))
  repeat
    pst.Chars(pst#NL, 3)                                                        'Output multiple new lines
    pst.Str(String("Enter a decimal value: "))                                  'Prompt user to enter a number; uses immediate string.
    value := pst.DecIn                                                          'Get number (in decimal).
    pst.Str(String(pst#NL, "Your value is..."))                                 'Announce output
    pst.Str(String(pst#NL, " (Decimal):"))                                      'In decimal
    pst.PositionX(16)                                                           'Move cursor to column 16
    pst.Dec(value)
    pst.Str(String(pst#NL, " (Hexadecimal):", pst#PX, 16))                      'In hexadecimal.  We used PX control code to
    pst.Hex(value, 8)                                                           '  move cursor (alternative to PositionX method).
    pst.Str(String(pst#NL, " (Binary):"))                                       'In binary.
    pst.MoveRight(6)                                                            'Used MoveRight to move cursor (alternative
    pst.Bin(value, 32)                                                          '  to features used above).
    pst.Str(String(pst#NL, pst#NL, "Try again? (Y/N):"))                        'Prompt to repeat
    value := pst.CharIn
  while (value == "Y") or (value == "y")                                        'Loop back if desired


  '-------- Demo 2 --------
  repeat
    pst.Clear                                                                   'Clear screen
    pst.Str(@DemoHeader)                                                        'Print header.
    pst.Chars("-", strsize(@DemoHeader))                                        'Use Chars method to output hyphens "-"
    pst.Str(String(pst#NL, pst#NL, "*** Pseudo-Random Number Example ***"))    
    pst.Chars(pst#NL, 2)                                                        'Output multiple new lines
    pst.Str(String("Enter 'seed' value: "))                                     'Prompt for seed value
    value := pst.DecIn                                                          
    pst.Str(String(pst#NL, "Display decimal, hexadecimal, or binary? (D/H/B)")) 'Prompt for base size
    base := pst.CharIn
    pst.Str(@RandomHeader)                                                      'Output table header
    pst.Dec(value)
    base := lookdownz(base & %11011111: "B", "H", "D") <# 2                     'Convert base to number (B=0, H=1, else = 2)
    offset := ColPos + 4 + width := lookupz(base: 32, 8, 11)                    'Calculate column offset and field width
    pst.Chars(pst#NL, 2)                                                        'New lines
    pst.PositionX(ColPos)                                                       'Position and display first column heading
    pst.Str(@Forward)
    pst.PositionX(offset)                                                       'Position and display second column heading
    pst.Str(@Backward)
    pst.NewLine                                                                 'Draw underlines
    pst.PositionX(ColPos)
    pst.Chars("-", width)
    pst.PositionX(offset)
    pst.Chars("-", width)
    pst.NewLine
     
    'Pseudo-Random Number (Forward)
    repeat 10                                                                   
      waitcnt(clkfreq / 6 + cnt)                                                'Wait 1/6 second
      pst.PositionX(ColPos)                                                     'Position to first column
      ?value                                                                    'Generate random number forward
      case base                                                                 'Output in binary, hexadecimal, or decimal
        0: pst.Bin(value, width) {binary}                                       
        1: pst.Hex(value, width) {hex}
        2: pst.Dec(value)        {decimal}
      pst.MoveDown(1)                                                           'Move to next line
     
    'Pseudo-Random Number (Backward)
    repeat 10
      waitcnt(clkfreq / 6 + cnt)                                                'Wait 1/6 second                          
      pst.MoveUp(1)                                                             'Move to previous line                    
      pst.PositionX(offset)                                                     'Position to second column                
      case base                                                                 'Output in binary, hexadecimal, or decimal
        0: pst.Bin(value, width) {binary}                                                                                 
        1: pst.Hex(value, width) {hex}                                                                                    
        2: pst.Dec(value)        {decimal}                                                                                
      value?                                                                    'Generate random number backward
          
    pst.Position(0, 23)                                                         'Position below table
    pst.Str(String("Try again? (Y/N):"))                                        'Prompt to repeat
    value := pst.CharIn
  while (value == "Y") or (value == "y")                                        'Loop back if desired

  pst.Clear
  pst.Str(String("Thanks for playing."))  
  
DAT

DemoHeader    byte "Parallax Serial Terminal Demonstration", pst#NL, 0
RandomHeader  byte pst#NL, pst#NL, "Pseudo-Random Numbers Generated by Seed Value ", 0
Forward       byte "Forward", 0
Backward      byte "Backward", 0
}}
