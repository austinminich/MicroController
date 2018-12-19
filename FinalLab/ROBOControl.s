.include "LCD.s"
    
.ifndef ROBOControl
ControlOPs:
    
.data
    forwardMessage:	.asciiz "Forward"
    forwardHexMsg:	.asciiz "4200"
    backwardMessage:	.asciiz "Backward"
    backwardHexMsg:	.asciiz "4300"
    leftMessage:	.asciiz "Left"
    leftHexMsg:		.asciiz "4501"
    rightMessage:	.asciiz "Right"
    rightHexMsg:	.asciiz "4601"
    bankLeftMessage:	.asciiz "Bank Right"
    bankRightMessage:	.asciiz "Bank Left"
    stopMessage:	.asciiz "Stopped"
    stopHexMsg:		.asciiz "4400"
    pivotRightMessage:	.asciiz "PivotRight"
    pivotRightHexMsg:	.asciiz "4603"
    pivotLeftMessage:	.asciiz "Pivot Left"
    pivotLeftHexMsg:	.asciiz "4503"
    reverseLeftHexMsg:	.asciiz "4502"
    reverseRightHexMsg:	.asciiz "4602"
    
    doWhatMessage:	.asciiz "Reverse Pivot?"
    
.text # a0 = operation
    
    .ent setupHBridges
    setupHBridges: # Uses OC3 and OC2 in port D with OC3 = left motor and OC2 = right motor
	# Right H-bridge (right wheel) DIR - RD07; EN - RD01, OC2 - Yes, the enable is controlled by output channel 2
	# Left H-bridge (left wheel) DIR - RD06; EN - RD02, OC1 - Yes, the enable is controlled by output channel 1
	# Set these two pins to outputs
	LI $t0, 0b11000110
	SW $t0, TRISDCLR
	SW $zero, LATD
    
	JR $ra
    .end setupHBridges
    
    
    # LI $t1, 273 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle)
    # SW $t1, OC2RS
    # SW $t1, OC3RS
    # Whenever you do a direction change or break:
	# turn off the H bridge, change pin direction of motor, turn on h bridge
    .ent ROBOForward
    ROBOForward:	
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	LI $t0, 1 << 7
	SW $t0, LATDCLR # Setting pin direction of left and right motors
	LI $t0, 1 << 6
	SW $t0, LATDSET
	
    	# Send message to LCD
    	ADDI $sp, $sp, -8
    	SW $ra, 0($sp)
    	SW $a0, 4($sp)
	LA $a0, forwardMessage
    	JAL sendUARTLCD
    	LW $a0, 4($sp)
    	LW $ra, 0($sp)
	ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	
	# Duty cycle % (go forward for $s0 seconds in timer above)
	LI $t0, 75 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle) 273
	SW $t0, OC2RS
	SW $t0, OC3RS
	
	# Turn off motor
	startForward:
	    BEQ $s0, $a0, endForward # a0 seconds
	    J startForward
	endForward: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    # Send message to LCD
	    ADDI $sp, $sp, -4
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8
	    
	JR $ra
    .end ROBOForward
    
    .ent ROBOBackward
    ROBOBackward:
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	LI $t0, 1 << 7
	SW $t0, LATDSET # Setting pin direction of left and right motors
	LI $t0, 1 << 6
	SW $t0, LATDCLR
	
	# Send message to LCD
    	ADDI $sp, $sp, -8
    	SW $ra, 0($sp)
    	SW $a0, 4($sp)
	LA $a0, backwardMessage
    	JAL sendUARTLCD
    	LW $a0, 4($sp)
    	LW $ra, 0($sp)
	ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	
	# Duty cycle % (go forward for $s0 seconds in timer above)
	LI $t0, 75 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle) 273
	SW $t0, OC2RS
	SW $t0, OC3RS
	
	# Turn off motor
	startBackward:
	    BEQ $s0, $a0, endBackward # 1 seconds
	    J startBackward
	endBackward: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    
	    # Send message to LCD
	    ADDI $sp, $sp, -8
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8

	JR $ra
    .end ROBOBackward
    
    .ent ROBOLeft
    ROBOLeft:
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	LI $t0, 1 << 7
	SW $t0, LATDCLR # Setting pin direction of left and right motors
	
	# Send message to LCD
    	ADDI $sp, $sp, -8
    	SW $ra, 0($sp)
    	SW $a0, 4($sp)
	LA $a0, leftMessage
    	JAL sendUARTLCD
    	LW $a0, 4($sp)
    	LW $ra, 0($sp)
	ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	
	# Duty cycle % (go forward for $s0 seconds in timer above)
	LI $t0, 75 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle) 273
	SW $t0, OC2RS
	
	# Turn off motor
	startLeft:
	    BEQ $s0, $a0, endLeft # $a0 seconds
	    J startLeft
	endLeft: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    
	    # Send message to LCD
	    ADDI $sp, $sp, -8
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8
    
	JR $ra
    .end ROBOLeft
    
    .ent ROBORight
    ROBORight:
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	LI $t0, 1 << 6 
	SW $t0, LATDSET # Setting pin direction of left and right motors
	
	# Send message to LCD
    	ADDI $sp, $sp, -8
    	SW $ra, 0($sp)
    	SW $a0, 4($sp)
	LA $a0, rightMessage
    	JAL sendUARTLCD
    	LW $a0, 4($sp)
    	LW $ra, 0($sp)
	ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	
	# Duty cycle % (go forward for $s0 seconds in timer above)
	LI $t0, 75 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle) 273
	SW $t0, OC3RS
	
	# Turn off motor
	startRight:
	    BEQ $s0, $a0, endRight # 1 seconds
	    J startRight
	endRight: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    
	    # Send message to LCD
	    ADDI $sp, $sp, -8
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8
    
	JR $ra
    .end ROBORight
    
    .ent ROBOBrake
    ROBOBrake: # wait for $a0, seconds
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	
	# Send message to LCD
    	ADDI $sp, $sp, -8
    	SW $ra, 0($sp)
    	SW $a0, 4($sp)
	LA $a0, stopMessage
    	JAL sendUARTLCD
    	LW $a0, 4($sp)
    	LW $ra, 0($sp)
	ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	# LEDs
	LI $t0, 0x3C00
	SW $t0, LATBSET
	
	startBrake:
	    BEQ $s0, $a0, endBrake # 1 seconds
	    J startBrake
	endBrake: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    LI $t0, 0x3C00
	    SW $t0, LATBCLR
	    
	    # Send message to LCD
	    ADDI $sp, $sp, -8
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8
    
	JR $ra
    .end ROBOBrake
    
    .ent ROBOBankLeft
    ROBOBankLeft:
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	LI $t0, 1 << 7
	SW $t0, LATDCLR
	LI $t0, 1 << 6 
	SW $t0, LATDSET # Setting pin direction of left and right motors
	
	# Send message to LCD
    	ADDI $sp, $sp, -8
    	SW $ra, 0($sp)
    	SW $a0, 4($sp)
	LA $a0, bankLeftMessage
    	JAL sendUARTLCD
    	LW $a0, 4($sp)
    	LW $ra, 0($sp)
	ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	
	# Duty cycle % (go forward for $s0 seconds in timer above)
	LI $t0, 75 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle) 273
	SW $t0, OC3RS
	LI $t0, 80
	SW $t0, OC2RS
	
	# Turn off motor
	startBankLeft:
	    BEQ $s0, $a0, endBankLeft 
	    J startBankLeft
	endBankLeft: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    
	    # Send message to LCD
	    ADDI $sp, $sp, -8
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8
    
	JR $ra
    .end ROBOBankLeft
    
    .ent ROBOBankRight
    ROBOBankRight:
	# Set pin direction of motors and turn on motors (OCxCON<15> = on/off, RD07 & RD06 = DIR, RD01 & RD02 = Enable)
	SW $zero, OC2RS
	SW $zero, OC3RS # Turning off motors
	LI $t0, 1 << 7
	SW $t0, LATDCLR
	LI $t0, 1 << 6 
	SW $t0, LATDSET # Setting pin direction of left and right motors
	
	# Send message to LCD
	ADDI $sp, $sp, -8
	SW $ra, 0($sp)
	SW $a0, 4($sp)
        LA $a0, bankRightMessage
        JAL sendUARTLCD
	LW $a0, 4($sp)
	LW $ra, 0($sp)
        ADDI $sp, $sp, 8
	
	# Turn on timer
	MOVE $s0, $zero # $s0 will be used for counting how long a ROBOControl cmd lasts
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET # Used for 32bit Timer, using timers 4 and 5
	
	# Duty cycle % (go forward for $s0 seconds in timer above)
	LI $t0, 80 # dutyCycle% * 341 = OC2/OC3 (this line is 80% duty cycle) 273
	SW $t0, OC3RS
	LI $t0, 75
	SW $t0, OC2RS
	
	# Turn off motor
	startBankRight:
	    BEQ $s0, $a0, endBankRight
	    J startBankRight
	endBankRight: 
	    # Stop timer
	    LI $t0, 1 << 15 # <15> bit for enabling timer
	    SW $t0, T4CONCLR # Used for 32bit Timer, using timers 4 and 5
	    SW $zero, TMR4
	    MOVE $s0, $zero
	    SW $zero, OC2RS # Stops right motor speed
	    SW $zero, OC3RS # Stops left motor speed
	    
	    # Send message to LCD
	    ADDI $sp, $sp, -8
	    SW $ra, 0($sp)
	    SW $a0, 4($sp)
	    LA $a0, clear_disp
	    JAL sendUARTLCD
	    LW $a0, 4($sp)
	    LW $ra, 0($sp)
	    ADDI $sp, $sp, 8
    
	JR $ra
    .end ROBOBankRight
    
.endif
