───────────────────────────────────────
Parallax Semiconductor Propeller Chip Project Archive
───────────────────────────────────────

 Project :  "Package"

Archived :  Sunday, August 25, 2013 at 11:17:49 AM

    Tool :  Propeller Tool version 1.3.2


            Package.spin
              │
              ├──LEDSequencer_asm.spin
              │
              └──DisplaySequencer.spin
                   │
                   ├──Parallax Serial Terminal.spin
                   │
                   ├──MyLed.spin
                   │
                   └──GetButtons.spin


────────────────────
Parallax Inc., dba Parallax Semiconductor
www.parallaxsemiconductor.com
support@parallaxsemiconductor.com
USA 916.632.4664

Reference:
http://obex.parallax.com/object/399

Description from Reference:
This module is a modified copy of my module "Mother of all LED Sequencers" In simple terms this software takes bit patterns from memory and passes them to the I/O ports. It will work with the Propeller demo Board, The Quickstart board and the PropBOE board. It also works with an led driver based on a 74HC595 shift register of my own design (See MyLed object for details).The differences between this and the original OBEX module is that first this is all spin, second this uses a circular list, and third this is modified to be able to wait for an input rather than being strictly timed sequences.