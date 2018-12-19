.ifndef Switches
SWs:

.text
    
    .ent setupSWs
    setupSWs: # bottom JK
	LI $t0, 3 << 9 
	SW $t0, TRISASET
	SW $t0, LATACLR
	LI $t0, 1 << 12 
	SW $t0, TRISDSET
	SW $t0, LATDCLR
	LI $t0, 1 << 4
	SW $t0, TRISCSET
	SW $t0, LATCCLR
	JR $ra
    .end setupSWs
    
    .ent readSWs
    readSWs: # Bottom of JK
	# $v0 = switchStates
	MOVE $a0, $zero
	LW $t0, PORTC # reads the portD
	ANDI $t0, $t0, 1 << 4 # masks portD ($t0) with bit 13
	OR $v0, $v0, $t0 
	LW $t0, PORTD # reads the portD
	ANDI $t0, $t0, 1 << 12 # masks portD ($t0) with bit 8
	SRL $t0, $t0, 9
	OR $v0, $v0, $t0
	LW $t0, PORTA # reads the portD
	ANDI $t0, $t0, 3 << 9 
	SRL $t0, $t0, 9
	OR $a0, $a0, $t0
	
	JR $ra
    .end readSWs
    
    .ent writeSWtoLEDs
    writeSWtoLEDs: # Takes $a0 as SW states
	LI $t0, 0b1111
	ANDI $a0, $t0, 0b1111
	SLL $t0, $t0, 8
	SW $t0, LATBSET
	
	JR $ra
    .end writeSWtoLEDs
    
    .ent setupSWtoInt1
    setupSWtoInt1: # Sets up SW1 to external interrupt 1 at pin RE8
	LI $t0, 1 << 8 # Sets pin 8 of port E to input
	SW $t0, TRISESET
	SW $t0, LATECLR
	
	# Disable External interrupt in case it was on
	LI $t0, 0x80
	SW $t0, IEC0CLR
    
	# Set external interrupt priority 4, manipulating IPC<28:26> = 3 (0b011)
	LI $t0, 0b111 << 26
	SW $t0, IPC1CLR
	LI $t0, 3 << 26
	SW $t0, IPC1SET
	
	# Set when the interrupt happens (rising)
	LI $t0, 0b10
	SW $t0, INTCONSET
	
	# Enable external interrupt 1
	LI $t0, 0x80
	SW $t0, IEC0SET
    
	JR $ra
    .end setupSWtoInt1
    
    .ent setupSWtoInt0
    setupSWtoInt0: # Sets up SW1 to external interrupt 1 at pin RE8
	LI $t0, 1 # Sets pin 8 of port E to input
	SW $t0, TRISDSET
	SW $t0, LATDCLR
	
	# Disable External interrupt in case it was on
	LI $t0, 1 << 3
	SW $t0, IEC0CLR
    
	# Set external interrupt priority 4, manipulating IPC<28:26> = 3 (0b011)
	LI $t0, 0b111 << 26
	SW $t0, IPC0CLR
	LI $t0, 3 << 26
	SW $t0, IPC0SET
	
	# Set when the interrupt happens (rising)
	LI $t0, 0b10
	SW $t0, INTCONSET
	
	# Enable external interrupt 1
	LI $t0, 1 << 3
	SW $t0, IEC0SET
    
	JR $ra
    .end setupSWtoInt0
    
    .ent setupSWtoInt3
    setupSWtoInt3: # Sets up SW1 to external interrupt 1 at pin RE8
	LI $t0, 1 << 14 # Sets pin 8 of port E to input
	SW $t0, TRISASET
	SW $t0, LATACLR
	
	# Disable External interrupt in case it was on
	LI $t0, 1 << 15
	SW $t0, IEC0CLR
    
	# Set external interrupt priority 4, manipulating IPC<28:26> = 3 (0b011)
	LI $t0, 0b111 << 26
	SW $t0, IPC3CLR
	LI $t0, 3 << 26
	SW $t0, IPC3SET
	
	# Set when the interrupt happens (rising)
	LI $t0, 0b10
	SW $t0, INTCONSET
	
	# Enable external interrupt 1
	LI $t0, 1 << 15
	SW $t0, IEC0SET
    
	JR $ra
    .end setupSWtoInt3
    
.section .vector_3, code
    J handleExtInt0

.text
    
    .ent handleExtInt0
    handleExtInt0:
	DI
	
	ADDI $sp, $sp, -4
	SW $t0, 0($sp)
	
	LI $t0, 1 << 3 # IFS0<3>
	SW $t0, IFS0CLR # Clears flag bit
	
	# ===== Execute this code =====
	# - Flipping a switch, corresponding to INT1, from low to high triggers
	# - an interrupt to double the counter time
	# $s1 is the amount the tmer counts by
	LW $t0, PR2
	SLL $t0, $t0, 1 # Slows down counter
	SW $t0, PR2
	SW $zero, TMR2
	# ===== end of code executed in interrupt =====
	
	LW $t0, 0($sp)
	ADDI $sp, $sp, 4
	
	EI
    
	ERET
    .end handleExtInt0
    
.endif



