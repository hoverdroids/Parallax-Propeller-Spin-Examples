''This code example is from Propeller Education Kit Labs: Fundamentals, v1.2.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
{{
Top File: CogObjectExampleWithSchematic.spin
Blinks an LED circuit for 20 repetitions.  The P4 LED
blink period is determined by how long the P23 pushbutton
is pressed and held.

  LED                     Pushbutton           
 ──────────────────────   ──────────────────────
                                                
       (all)                      3.3 V         
       100 Ω  LED                              
  P4 ──────────┐               │           
                    │              ┤Pushbutton 
                                   │           
                   GND    P23 ───┫           
                               100 Ω│           
                                    │           
                                     10 kΩ     
                                    │           
                                               
                                   GND          
 ──────────────────────   ──────────────────────
}}

OBJ

    Blinker : "Blinker"
    Button  : "Button"


PUB ButtonBlinkTime | time

    repeat

       time := Button.Time(23)
       Blinker.Start(4, time, 20)