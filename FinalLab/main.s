# .include "Timers.s"
.include "Switches.s"
.include "ROBOFigureSkating.s"
.include "UART.s"
.include "Joystick.s"
.include "Keypad.s"
    
.global main # This is the main for the CONTROLLER board

.data
    # Data for LCD    
    specialty_char: .byte 0x1B
		    .ascii "[14;31;21;31;23;16;31;14;1d"

    prog_char_table: .byte 0x1B, '[', '3', 'p'

    # message: .asciiz "Hello Class! Having fun yet? "
    startMessage: # .byte 0x1B, '[', 'h'
		.asciiz "What mode? 1-RC 2-Line 3-Program"
    # message2: .byte 1, 0x00
    
    # Data for motors
    .align 2 # Aligns the memory to ensure it's in the correct spots
    programCounter:	.word 0
    instructions:	.space 100 # Provides 25 32bit word  values, .space proves a # amount of bytes (4 bytes for 32bit word)
    families:		.word ROBOnull, ROBOControl, ROBOBranch, ROBOFigureSkating
    ROBOControl:	.word ROBOForward, ROBOBackward, ROBOLeft, ROBORight, ROBOBrake, ROBOBankLeft, ROBOBankRight
    # ord left, right , forward , backward, brake, reverseLeft, reverseRight, pivotLeft, pivotRight, ROBOHALT
    # ord 4501  4601     4200      4300      4400      4502	    4602        4503	   4603	       3300
    ROBOBranch:		.word ROBOHalt, RCMode, LineFollowMode, ProgramMode
    ROBOFigureSkating:	.word ROBOCircle, ROBOSquare, ROBOTriangle, ROBOFig8
    
.section .vector_15, code
    J handleExtInt3
    
.text

.ent main
main:

    DI # Disable system wide interrupts; don't respond to spurious interrupts

    LI $t0, 1 << 12 # For INTCON<12> = 1
    SW $t0, INTCONSET # multivec
    # JAL setupPortsUsed # For motors

    # Right H-bridge connected to Cerebot MX4cK Port JD-06:01 (RD7, RD1, RD9, RC1, GND, VCC) right to left
    # Left H-bridge connected to Cerebot MX4cK Port JD-12:07 (RD6, RD2, RD10, RC2, GND, VCC) right to left
    # Set motor direction; DIR - RD07, DIR - RD06
    # Be careful not to change the direction at the same time the motor is pulsed; may cause short cirucit in H-bridge
#    LI $t0, 1 << 7
#    SW $t0, LATDCLR
#    LI $t0, 1 << 6
#    SW $t0, LATDSET
    # JAL setupOCs # OC2 for right motor and OC1 for left motor
    
    # LEDs
    LI $t0, 0x3C00
    SW $t0, TRISBCLR
    SW $zero, LATB

    # JAL setupTimer1 # Configure Timer 1 for 10 micro seconds
    # JAL setupTimer2 
    # JAL setup32Timer45 # .5 second timer used for motors
	
#     # Set the pins of the light sensors to input
#     LI $t0, 0x2101
#     SW $t0, TRISDSET
#     LI $t0, 1 << 8
#     SW $t0, TRISESET

    JAL setupUART1TX # Sets up LCD for UART transmitting to LCD
    JAL setupLeftJoystick # Sets up joystick for SPI receiving from joystick to board
    JAL setupRightJoystick
    JAL setupUART2BlueTX # Sets up bluetooth transmitting
    JAL setupKYPD # KYPD is used for changes modes, and sending instructions
    JAL setupSWtoInt3# Switches will be used for EXTERNAL interrupt 3 for changing modes
    
    EI	# Enable system wide interrupts

#     LI $t0, 10000000
#     waitloop: # Waits so that the reader doesn't miss the message if a button was pressed
# 	ADDI $t0, $t0, -1
# 	BEQZ $t0, endwaitloop
# 	
# 	J waitloop
#     endwaitloop:
    
    startProgram:
	LA $a0, all_data
	JAL sendUARTLCD
	LA $a0, startMessage
	JAL sendUARTLCD
	mainLoop:
	    # JAL receiveBlueData
	    JAL readKYPD # Returns hex of what was pressed (ie. 0xA)
	    MOVE $a0, $v0 # Will send as a parameter to Bluetooth once mode is selected
	    BEQ $a0, 0x1, RCMode # Goto RCMode when A is pressed
	    BEQ $a0, 0x2, LineFollowMode # Goto LineFollow mode when B is pressed
	    BEQ $a0, 0x3, ProgramMode # Goto ProgramMode when C is pressed
	
	    J mainLoop
    RCMode: # This is what is running when in RCMode
	# Readjoysticks, organize data from joysticks, send to robot
	# JAL sendToUART2 # Send the robot to determine what mode we're in
	LA $a0, all_data # Clear choosing mode screen
	JAL sendUARTLCD
	RCModeLoop:
	    JAL readLeftJoy # Returns $v0 as (y) position the joystick is in
	    MOVE $a0, $v0
	    JAL readRightJoy # Returns $v0 as Y position
	    MOVE $a1, $v0
	    JAL getDirection # gets and sends the instruction (ie. 0x1405)
 	    MOVE $a0, $v0
 	    JAL sendToUART2
    
	    J RCModeLoop
    LineFollowMode: # This is what is running when in LineFollowMode
	# Idle allowing the controller to not interfere with the robot UNLESS
	#   switch interrupt is triggered, go to initial loop where mode is chosen
	LA $a0, all_data # Clear choosing mode screen
	JAL sendUARTLCD
	LineFollowLoop:
    
	    J LineFollowMode
    ProgramMode: # This is what is running when in ProgramMode
	# Read kypd for 4 values, pack into instruction, send to 
	LA $a0, all_data # Clear choosing mode screen
	JAL sendUARTLCD
	ProgramModeLoop:
	    LI $t0, 4 # For the four digits
	    getInstruction:
	    JAL delayKYPD
	    JAL readKYPD # Returns hex 
	    BGT $v0, 0x9, getInstruction # If the input is A,B,C,D,E,F then readKYPD again for another number
# 	    ADDI $t0, $t0, -1 # Got a number
# 	    BEQZ $t0, fourthPart 
# 	    firstPart: # $t1 is the instruction being sent
# 		SLL $v0, $v0, 12
# 		OR $t1, $t1, $v0
# 		J getInstruction
# 	    secondPart:
# 		SLL $v0, $v0, 8
# 		OR $t1, $t1, $v0
# 		J getInstruction
# 	    thirdPart:
# 		SLL $v0, $v0, 4
# 		OR $t1, $t1, $v0
# 		J getInstruction
# 	    fourthPart:
# 		OR $t1, $t1, $v0 # No need to shift
	    MOVE $a0, $v0
	    JAL sendToUART2 # Send the robot to determine what mode we're in
	    BEQ $a0, 0x3300, startProgram # User must wait for ROBOT to finish
	    J ProgramMode
    
.end main
    
.ent fetch
fetch:
    LW $t2, programCounter
    # MOVE $t2, $zero
    LA $t1, instructions # Loads base address of instructions[]
    SLL $t0, $t2, 2 # Multiplies programCounter by 4 to get correct address
    ADD $t0, $t1, $t0 # Adds programCounter(* by 4) and instructions address into t0
    LW $v0, 0($t0) # Returns address families + offset
    ADDI $t2, $t2, 1
    SW $t2, programCounter # Updates program counter
	
    JR $ra
.end fetch
    
.ent decode
decode:
    ANDI $t0, $a0, 0xF000 # 1st hex digit (family)
    SRL $t0, $t0, 10 # SLL $t0, $t0, 2
    LA $t1, families
    ADD $t1, $t1, $t0 # families + 4i
    LW $t1, 0($t1) # This needs to load the sub group in families Breaks here

    # $t1 = ROBOData
    ANDI $t0, $a0, 0xF00 # 2nd hex digit (operation)
    SRL $t0, $t0, 6 # SLL $t0, $t0, 2
    ADD $t1, $t0, $t1 # Adds the number in $t0 to $t1 [0x0F00 + (families+4i)]
    LW $v1, 0($t1) # this needs to load the operation in operations grp v1 = operations grp
    # Returns function $v1 [ (JAL $v1) in the future ]
	
    ANDI $t0, $a0, 0xFF # 3rd and 4th hex digit (Data)
    MOVE $v0, $t0 # This moves the operands for the operation v0 = operation within operations grp
	
    JR $ra # Doesn't return to the correct spot
.end decode

.ent ROBOnull
ROBOnull:
    JR $ra
.end ROBOnull

.ent ROBOHalt
ROBOHalt:
    ADDI $sp, $sp, -4
    SW $ra, 0($sp)
    halt_loop:
	LI $t0, 0x3C00
	SW $t0, LATBSET
	JAL get_buttons
	MOVE $t1, $v0
	BEQ $t1, 0x40, endH
	BEQ $t1, 0x80, endH
	BEQ $t1, 0xC0, endH
	j halt_loop
    endH:
    LI $t0, 0x3C00
    SW $t0, LATBCLR
    SW  $zero, programCounter
    
    LW $ra, 0($sp)
    ADDI $sp, $sp, 4
    
    JR $ra
.end ROBOHalt
    
.ent get_buttons
get_buttons:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    MOVE $t0, $zero
    collect:    # waits for a button or buttons to be pressed
	LW $t0, PORTA
	ANDI $t0, $t0, 0xC0
	
    btn_release:  # waits for all buttons to be released
	LW $t1, PORTA
	ANDI $t1, $t1, 0xC0
	OR $t0, $t0, $t1
	BNEZ $t1, btn_release
    
    MOVE $v0, $t0
    
    Lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
.end get_buttons
    
.ent getDirection
getDirection:
    ADDI $sp, $sp, -4 # Preserve
    SW $ra, 0($sp)
    
    # ord left, right , forward , backward, brake, reverseLeft, reverseRight, pivotLeft, pivotRight
    # ord 4501  4601     4200      4300      4400      4502	    4602        4503	   4603
    
    MOVE $t0, $a0 # Data from Left joystick (0-1023)
    MOVE $t1, $a1 # Data from Right joystick (0-1023)
    MOVE $a0, $zero # Messes with the messages being sent?
    
    BGT $t0, 600, forwardL # Check left joystick
    BGT $t0, 400, stopL
    J backwardL # Less than 400
    
    forwardL: # Left forward
	BGT $t1, 600, bothForward # Both forward
	BGT $t1, 400, onlyLeftForward # Left forward and right stop
	oneBackOneForward: # Left forward and right back
	    LA $a0, pivotRightMessage
	    JAL sendUARTLCD
	    LA $t2, pivotRightHexMsg
	    J endDirection
	bothForward: # Both forward (Check for bank turn?)
	    LA $a0, forwardMessage
	    JAL sendUARTLCD
	    LA $t2, forwardHexMsg # The location of forward in array above (send this command)
	    J endDirection
	onlyLeftForward: # Turning right
	    LA $a0, rightMessage
	    JAL sendUARTLCD
	    LA $t2, rightHexMsg
	    J endDirection
    stopL:
	BGT $t1, 600, onlyRightForward
	BGT $t1, 400, bothStop
	oneBackOneStopped: # Left stopped and right back
	    LA $a0, doWhatMessage # Weird case (reverse right pivot)
	    JAL sendUARTLCD
	    LA $t2, reverseRightHexMsg
	    J endDirection
	onlyRightForward: # Left stopped and right forward (left)
	    LA $a0, leftMessage
	    JAL sendUARTLCD
	    LA $t2, leftHexMsg
	    J endDirection
	bothStop: # Left reverse and right reverse
	    LA $a0, stopMessage
	    JAL sendUARTLCD
 	    LA $t2, stopHexMsg
	    J endDirection
    backwardL:
	BGT $t1, 600, oneForwardOneBack
	BGT $t1, 400, oneStoppedOneBack
	bothBack: # Reverse
	    LA $a0, backwardMessage
	    JAL sendUARTLCD
	    LA $t2, backwardHexMsg
	    J endDirection
	oneForwardOneBack: # Pivot left
	    LA $a0, pivotLeftMessage
	    JAL sendUARTLCD
	    LA $t2, pivotLeftHexMsg
	    J endDirection
	oneStoppedOneBack: # Weird Case (reverse left pivot?)
	    LA $a0, doWhatMessage
	    JAL sendUARTLCD
	    LA $t2, reverseLeftHexMsg
	    J endDirection
    endDirection:
    MOVE $v0, $t2 # Returns the instruction to send via bluetooth
    LW $ra, 0($sp) # Pop
    ADDI $sp, $sp, 4
    JR $ra
.end getDirection
    
.ent handleExtInt3
handleExtInt3:
    DI
	
    ADDI $sp, $sp, -4
    SW $t0, 0($sp)
	
    LI $t0, 1 << 15 # IFS0<15>
    SW $t0, IFS0CLR # Clears flag bit
	
    # ===== Execute this code =====
    # Branch to the beggining of the program where the mode is chosen
    # This is done at the end of the handler
    # ===== end of code executed in interrupt =====
	
    LW $t0, 0($sp)
    ADDI $sp, $sp, 4
	
    EI
    
    J startProgram
.end handleExtInt3

    