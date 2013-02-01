# Monophonic keyboard 
An electronic monophonic keyboard (it can only generate 1
note simultaneously). It generates 1 octave (13 notes), from the central C (Do
in Latin notes), using an equal tempered scale.  scale. For input it uses a PS2
keyboard(keys: A, W, S, E, D, F, T, G, Y, H, U, J, K).

It's done using a PS2 interface (to deserialize the pressing/depressing
scancodes), a ROM (storing the needed cicles for the counter),  a counter with a
T flip-flop (the sound generator) and a FSM.

See the attached pdfs for the hardware design.