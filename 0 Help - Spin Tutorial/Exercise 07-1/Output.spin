{{ Output.spin }}

VAR
  long  Stack[9]                      'Stack space for new cog
  byte  Cog                           'Hold ID of cog in use, if any


PUB Start(Pin, Delay, Count): Success
{{Start new blinking process in new cog; return TRUE if successful}}

  Stop
  Success := (Cog := cognew(Toggle(Pin, Delay, Count), @Stack) + 1)


PUB Stop
{{Stop toggling process, if any.}}

  if Cog
    cogstop(Cog~ - 1)


PUB Active: YesNo
{{Return TRUE if process is active, FALSE otherwise.}}

  YesNo := Cog > 0


PUB Toggle(Pin, Delay, Count)
{{Toggle Pin, Count times with Delay clock cycles in between.
  If Count = 0, toggle Pin forever.}}

  dira[Pin]~~                          'Set I/O pin to output…
  repeat                               'Repeat the following
    !outa[Pin]                         '  Toggle I/O Pin
    waitcnt(Delay + cnt)               '  Wait for Delay cycles
  while Count := --Count #> -1         'While not 0 (make min -1) 
  Cog~                                 'Clear Cog ID variable