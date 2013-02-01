# Chronometer
Simple start-stop chronometer, that counts seconds MOD 60
and minutes MOD 60. It displays tenths of second on one 7-segment display, and
you can choose with a switch to display seconds or minutes in 2 more 7-segments
displays.  With the start-stop push button, you can start-stop the count at any
time. With the clear button, you can clear the count to 0 at any time.

It's done using a 50 Mhz clock, debouncers and synchronizers, and chained
counters.

See the attached pdfs for the hardware design.
