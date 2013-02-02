# FPGA-THINGIES 

A bunch of little hardware designs in synthesis-able VHDL. Designed to be
implemented on a Spartan3 FPGA, and done using Xilinx ISE webpack 14.3. The vhdl
code is intended to be as understandable as possible (e.g., process are written
to be as close as the rt diagram, instead of wrapping various components in one
process).

notice: most of the code is in Spanish. Make an issue if you want it translated.
Each design has attached pdfs with handmade rt diagrams.

## DESIGNS   
#### Chronometer
Simple start-stop chronometer, that counts seconds
MOD 60 and minutes MOD 60. It displays tenths of second on one 7-segment
display, and you can choose with a switch to display seconds or minutes in 2
more 7-segments displays.  With the start-stop push button, you can start-stop
the count at any time. With the clear button, you can clear the count to 0 at
any time.

It's done using a 50 Mhz clock, debouncers and synchronizers, and chained
counters.

#### Monophonic keyboard 
An electronic monophonic keyboard (it can only generate 1
note simultaneously). It generates 1 octave (13 notes), from the central C (Do
in latin notes), using an equal tempered scale. For input it uses a PS2
keyboard(keys: A, W, S, E, D, F, T, G, Y, H, U, J, K).

It's done using a PS2 interface (to deserialize the pressing/depressing
scancodes), a ROM (storing the needed cicles for the counter),  a counter with a
T flip-flop (the sound generator) and a FSM.

#### Pong
Typical all hardware game: you have a ball, and two rackets to play.
The VGA synchronism is made with two counters and combinatorial logic. The movement of the ball is rendered by two counters (horizontal and vertical), and each racket has a counter for its vertical movement. Collisions are made with combinatorial logic. A PS2 keyboard is connected to a PS2 module, the key presses from it are logged by a FSM.

pong video: http://youtu.be/23qtBYbF7Ng

#### Tron game
As seen in Tron films, two light bikes chase each other and try to lock/slash the opponent with their light trails
The VGA synchronism is made with two counters and combinatorial logic. A bike movement is rendered by two counters(horizontal and vertical). The trails are stored by two modules of  2x 16Kx1bit RAM memory (each module is for each trail, blue and red), which has two ports: port A iterates the memory at 50Mhzs and acts as the refresh memory, port B iterates at a tenth of a second, and stores the trail. A PS2 keyboard is connected to a PS2 module, the key presses from it are logged by a FSM with flags.

tron video: http://youtu.be/bUlfAbWu3ew

#### License 
All the source code present here is under the GPLv3 license. Please see the GPv3License.md attached to this repo for more information.
