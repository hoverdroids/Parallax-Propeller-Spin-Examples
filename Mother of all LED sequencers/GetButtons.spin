{{
OBEX LISTING:
  http://obex.parallax.com/object/399

  This module is a modified copy of my module "Mother of all LED Sequencers"
  In simple terms this software takes bit patterns from memory and passes them to the I/O ports.
  It will work with the Propeller demo Board, The Quickstart board and the PropBOE board.
  It also works with an led driver based on a 74HC595 shift register of my own design
  (See MyLed object for details).The differences between this and the original OBEX module is that
  first this is all spin, second this uses a circular list, and third this is modified to be able
  to wait for an input rather than being strictly timed sequences.

}}
{{         ===== Get Buttons ======

    The quickstart board has 8 "switches" connected to the i/o pins 0 to 7 with
    button 7 on the left and button 0 on the right as follows :

          ┌──── ────────── Propeller I/O pin
               
                └─────── This is a capacitive switch, in use, we first charge the capacitor
                         by making the i/o pin an output,  then we make the i/o pin an
                         input and fetch its state.  If the capacitor was discharged by
                         someone placing a finger across it, it will read low otherwise high
                         So a zero indicates button pressed and a high is not pressed. 

      GetButtons ---  When called, this module reads and returns the state of the buttons.
                      All the details about how the buttons work and any constants needed
                      are now contained in this module.

         State        This is the routine that fetches the state of the buttons
                      it returns an 8 bit pattern representing the state of the
                      buttons.   A one indicates button pressed.
                                   
}}
  _CLKMODE = XTAL1 + PLL16X
  _CLKFREQ = 80_000_000
  
  Clock    = 80000000                ' Precalculated time delays in clocks
  ms1      = Clock / 1000

  ButtonsOn    = $000000FF           ' Numbers with $ in front are in hexadecimal
  ButtonsOff   = $FFFFFF00           ' Numbers with % in front are in binary

Pub State                       ' This reads the state of all 8 buttons
    Outa |= ButtonsOn           ' Set button pins high but remain as inputs
    Dira |= ButtonsOn           ' Briefly make all the buttons an output to charge the cap
    Dira &= ButtonsOff          ' Now make all the buttons back to inputs
    waitcnt(ms1+cnt)            ' Wait 1 millisecond  (allow time to discharge cap)
    return (!ina[0..7] & ButtonsOn)
{ In the return statement above, the ! operator inverts the results because we want a high
  to represent button pressed and a low not pressed. The & operator removes all but the right
  8 bits.  Button 7 is on the left.
}
                                
