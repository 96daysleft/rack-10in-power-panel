// Six-output panel for the assembled carrier board (pcb/six-carrier): all six Pis
// and the GS308 on one brick. The tray has four standoffs for the board; the
// front-panel DC jack sits on the right, over the board's empty front corner,
// so it clears the fuse holder and terminals (vents skip around it).
include <rack-power-panel.scad>
role         = "six-pcb";
jack_side    = "front";
jack_front_x = 150;
