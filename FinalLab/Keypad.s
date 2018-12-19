.ifndef Keypad # When using these functions, just use a JAL just like you 
		# would if it was inside the main.s
BTNs: # This is desigend to have the Keypad plugged into PortE ONLY!!!
    
.data
    # jumpTable: .word equalsA, equalsB, equalsC, equalsD, equalsE, equalsF, equals0, equals1, equals2, equals3, equals4, equals5, equals6, equals7, equals8, equals9
    # I could have used a jump table like the one above, but I didn't know how I wanted to manage the incrementing so I just did it this way
    
.text
    
    .ent setupKYPD
    setupKYPD:
	# Make 4-7 PORTE as inputs
	LI $t0, 0xF0
	SW $t0, TRISESET
	# Make 0-3 PORTE as outputs
	LI $t0, 0xF # Loads bit 10-13 into t0
	SW $t0, TRISECLR # Sets bits 10-13 to 0
	SW $t0, LATESET # Writes 10-13 a 0 initializing them to the off state
	JR $ra # Return to where the function was called from
	
    .end setupKYPD
	
    .ent readKYPD
    readKYPD: # Return $v0 as what button was pressed in hex value (0xA, 0x5, etc)
	# Keypad reads the rows and columns that are in the low state
	# $t0 = keypad_state so we should initialize
	ADDI $sp, $sp, -8
	SW $t1, 4($sp)
	SW $t0, 0($sp)
	
	KYPDLoop:
	MOVE $v0, $zero
        MOVE $t0, $zero
        # $t1 = keypad_temp we should initialize but we dont have to?
	MOVE $t1, $zero
	
        # With the KYPD, you need to read one column at a time, first row (left-right)
	LI $t2, 0b1110 # first column (right-left)
        SW $t2, LATESET # writes 0b1110 to portE
        LI $t2, 0b0001
        SW $t2, LATECLR # writes 0s to bits 0b1
        # Read from PORTE in case something changed?
        LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Read each row
	# Jump table?
	ANDI $t2, $t1, 0x80 # masks to see if A was pressed
	BEQ $t2, $zero, equalsA
	ANDI $t2, $t1, 0x40 # masks to see if B was pressed
	BEQ $t2, $zero, equalsB
	ANDI $t2, $t1, 0x20 # masks to see if C was pressed
	BEQ $t2, $zero, equalsC
	ANDI $t2, $t1, 0x10 # masks to see if D was pressed
	BEQ $t2, $zero, equalsD
	
	LI $t2, 0b1101 # second column (right-left)
        SW $t2, LATESET # writes 0b1101 to portE
        LI $t2, 0b0010
        SW $t2, LATECLR # writes 0s to bits 0b10
	# Read from PORTE in case something changed?
	LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Each Row
	ANDI $t2, $t1, 0x80 # masks to see if 3 was pressed
	BEQ $t2, $zero, equals3
	ANDI $t2, $t1, 0x40 # masks to see if 6 was pressed
	BEQ $t2, $zero, equals6
	ANDI $t2, $t1, 0x20 # masks to see if 9 was pressed
	BEQ $t2, $zero, equals9
	ANDI $t2, $t1, 0x10 # masks to see if E was pressed
	BEQ $t2, $zero, equalsE
	
	LI $t2, 0b1011 # third column (right-left)
        SW $t2, LATESET # writes 0b1101 to portE
        LI $t2, 0b0100
        SW $t2, LATECLR # writes 0s to bits 0b10
	# Read from PORTE in case something changed?
	LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Each Row
	ANDI $t2, $t1, 0x80 # masks to see if 2 was pressed
	BEQ $t2, $zero, equals2
	ANDI $t2, $t1, 0x40 # masks to see if 5 was pressed
	BEQ $t2, $zero, equals5
	ANDI $t2, $t1, 0x20 # masks to see if 8 was pressed
	BEQ $t2, $zero, equals8
	ANDI $t2, $t1, 0x10 # masks to see if F was pressed
	BEQ $t2, $zero, equalsF
	
	LI $t2, 0b0111 # second column (right-left)
        SW $t2, LATESET # writes 0b1101 to portE
        LI $t2, 0b1000
        SW $t2, LATECLR # writes 0s to bits 0b10
	# Read from PORTE in case something changed?
	LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Each Row
	ANDI $t2, $t1, 0x80 # masks to see if 3 was pressed
	BEQ $t2, $zero, equals1
	ANDI $t2, $t1, 0x40 # masks to see if 6 was pressed
	BEQ $t2, $zero, equals4
	ANDI $t2, $t1, 0x20 # masks to see if 9 was pressed
	BEQ $t2, $zero, equals7
	ANDI $t2, $t1, 0x10 # masks to see if E was pressed
	BEQ $t2, $zero, equals0
	J KYPDLoop
	
	# The branches currently branch and don't come back to check if any of
	# the other buttons in the column were pressed
	
	equalsA:
	    # ORI $t0, $t0, 0b10000000000 # Set keypadState to the correct key pressed in bits
	    ORI $t0, $t0, 0xA
	    J jumpReturn
	equalsB:
	    # ORI $t0, $t0, 0b100000000000
	    ORI $t0, $t0, 0xB
	    J jumpReturn
	equalsC:
	    # ORI $t0, $t0, 0b1000000000000
	    ORI $t0, $t0, 0xC
	    J jumpReturn
	equalsD:
	    # ORI $t0, $t0, 0b10000000000000
	    ORI $t0, $t0, 0xD
	    J jumpReturn
	equalsE:
	    # ORI $t0, $t0, 0b100000000000000
	    ORI $t0, $t0, 0xE
	    J jumpReturn
	equalsF:
	    # ORI $t0, $t0, 0b1000000000000000
	    ORI $t0, $t0, 0xF
	    J jumpReturn
	equals0:
	    # ORI $t0, $t0, 0b1
	    ORI $t0, $t0, 0x0
	    J jumpReturn
	equals1:
	    # ORI $t0, $t0, 0b10
	    ORI $t0, $t0, 0x1
	    J jumpReturn
	equals2:
	    # ORI $t0, $t0, 0b100
	    ORI $t0, $t0, 0x2
	    J jumpReturn
	equals3:
	    # ORI $t0, $t0, 0b1000
	    ORI $t0, $t0, 0x3
	    J jumpReturn
	equals4:
	    # ORI $t0, $t0, 0b10000
	    ORI $t0, $t0, 0x4
	    J jumpReturn
	equals5:
	    # ORI $t0, $t0, 0b100000
	    ORI $t0, $t0, 0x5
	    J jumpReturn
	equals6:
	    # ORI $t0, $t0, 0b1000000
	    ORI $t0, $t0, 0x6
	    J jumpReturn
	equals7:
	    # ORI $t0, $t0, 0b10000000
	    ORI $t0, $t0, 0x7
	    J jumpReturn
	equals8:
	    # ORI $t0, $t0, 0b100000000
	    ORI $t0, $t0, 0x8
	    J jumpReturn
	equals9:
	    # ORI $t0, $t0, 0b1000000000
	    ORI $t0, $t0, 0x9
	    J jumpReturn
	jumpReturn:
	    MOVE $v0, $t0 # Moves keypadState into a register used for parameter (writeKYPDtoLEDs)
	    LW $t1, 4($sp)
	    LW $t0, 0($sp)
	    ADDI $sp, $sp, 8
	    JR $ra
    .end readKYPD
    
    .ent readKYPDASCII
    readKYPDASCII: # Return $v0 as what button was pressed in hex value (0xA, 0x5, etc)
	# Keypad reads the rows and columns that are in the low state
	# $t0 = keypad_state so we should initialize
	ADDI $sp, $sp, -8
	SW $t1, 4($sp)
	SW $t0, 0($sp)
	
	KYPDLoopA:
	MOVE $v0, $zero
        MOVE $t0, $zero
        # $t1 = keypad_temp we should initialize but we dont have to?
	MOVE $t1, $zero
	
        # With the KYPD, you need to read one column at a time, first row (left-right)
	LI $t2, 0b1110 # first column (right-left)
        SW $t2, LATESET # writes 0b1110 to portE
        LI $t2, 0b0001
        SW $t2, LATECLR # writes 0s to bits 0b1
        # Read from PORTE in case something changed?
        LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Read each row
	# Jump table?
	ANDI $t2, $t1, 0x80 # masks to see if A was pressed
	BEQ $t2, $zero, equalsAA
	ANDI $t2, $t1, 0x40 # masks to see if B was pressed
	BEQ $t2, $zero, equalsBA
	ANDI $t2, $t1, 0x20 # masks to see if C was pressed
	BEQ $t2, $zero, equalsCA
	ANDI $t2, $t1, 0x10 # masks to see if D was pressed
	BEQ $t2, $zero, equalsDA
	
	LI $t2, 0b1101 # second column (right-left)
        SW $t2, LATESET # writes 0b1101 to portE
        LI $t2, 0b0010
        SW $t2, LATECLR # writes 0s to bits 0b10
	# Read from PORTE in case something changed?
	LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Each Row
	ANDI $t2, $t1, 0x80 # masks to see if 3 was pressed
	BEQ $t2, $zero, equals3A
	ANDI $t2, $t1, 0x40 # masks to see if 6 was pressed
	BEQ $t2, $zero, equals6A
	ANDI $t2, $t1, 0x20 # masks to see if 9 was pressed
	BEQ $t2, $zero, equals9A
	ANDI $t2, $t1, 0x10 # masks to see if E was pressed
	BEQ $t2, $zero, equalsEA
	
	LI $t2, 0b1011 # third column (right-left)
        SW $t2, LATESET # writes 0b1101 to portE
        LI $t2, 0b0100
        SW $t2, LATECLR # writes 0s to bits 0b10
	# Read from PORTE in case something changed?
	LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Each Row
	ANDI $t2, $t1, 0x80 # masks to see if 2 was pressed
	BEQ $t2, $zero, equals2A
	ANDI $t2, $t1, 0x40 # masks to see if 5 was pressed
	BEQ $t2, $zero, equals5A
	ANDI $t2, $t1, 0x20 # masks to see if 8 was pressed
	BEQ $t2, $zero, equals8A
	ANDI $t2, $t1, 0x10 # masks to see if F was pressed
	BEQ $t2, $zero, equalsFA
	
	LI $t2, 0b0111 # second column (right-left)
        SW $t2, LATESET # writes 0b1101 to portE
        LI $t2, 0b1000
        SW $t2, LATECLR # writes 0s to bits 0b10
	# Read from PORTE in case something changed?
	LW $t1, PORTE # read all 32 bits
        ANDI $t1, $t1, 0xF0 # masks the 4 bits that I'm concerned with
	# Each Row
	ANDI $t2, $t1, 0x80 # masks to see if 3 was pressed
	BEQ $t2, $zero, equals1A
	ANDI $t2, $t1, 0x40 # masks to see if 6 was pressed
	BEQ $t2, $zero, equals4A
	ANDI $t2, $t1, 0x20 # masks to see if 9 was pressed
	BEQ $t2, $zero, equals7A
	ANDI $t2, $t1, 0x10 # masks to see if E was pressed
	BEQ $t2, $zero, equals0A
	J KYPDLoopA
	
	# The branches currently branch and don't come back to check if any of
	# the other buttons in the column were pressed
	
	equalsAA:
	    # ORI $t0, $t0, 0b10000000000 # Set keypadState to the correct key pressed in bits
	    LB $t0, 'A'
	    J jumpReturn
	equalsBA:
	    # ORI $t0, $t0, 0b100000000000
	    LB $t0, 'B'
	    J jumpReturn
	equalsCA:
	    # ORI $t0, $t0, 0b1000000000000
	    LB $t0, 'C'
	    J jumpReturn
	equalsDA:
	    # ORI $t0, $t0, 0b10000000000000
	    LB $t0, 'D'
	    J jumpReturn
	equalsEA:
	    # ORI $t0, $t0, 0b100000000000000
	    LB $t0, 'E'
	    J jumpReturn
	equalsFA:
	    # ORI $t0, $t0, 0b1000000000000000
	    LB $t0, 'F'
	    J jumpReturn
	equals0A:
	    # ORI $t0, $t0, 0b1
	    LB $t0, '0'
	    J jumpReturn
	equals1A:
	    # ORI $t0, $t0, 0b10
	    LB $t0, '1'
	    J jumpReturn
	equals2A:
	    # ORI $t0, $t0, 0b100
	    LB $t0, '2'
	    J jumpReturn
	equals3A:
	    # ORI $t0, $t0, 0b1000
	    LB $t0, '3'
	    J jumpReturn
	equals4A:
	    # ORI $t0, $t0, 0b10000
	    LB $t0, '4'
	    J jumpReturn
	equals5A:
	    # ORI $t0, $t0, 0b100000
	    LB $t0, '5'
	    J jumpReturn
	equals6A:
	    # ORI $t0, $t0, 0b1000000
	    LB $t0, '6'
	    J jumpReturn
	equals7A:
	    # ORI $t0, $t0, 0b10000000
	    LB $t0, '7'
	    J jumpReturn
	equals8A:
	    # ORI $t0, $t0, 0b100000000
	    LB $t0, '8'
	    J jumpReturn
	equals9A:
	    # ORI $t0, $t0, 0b1000000000
	    LB $t0, '9'
	    J jumpReturn
	jumpReturnA:
	    MOVE $v0, $t0 # Moves keypadState into a register used for parameter (writeKYPDtoLEDs)
	    LW $t1, 4($sp)
	    LW $t0, 0($sp)
	    ADDI $sp, $sp, 8
	    JR $ra
    .end readKYPDASCII
	
    .ent writeKYPDtoLEDs
    writeKYPDtoLEDs:
	# $a0 is keypadState/operationResult
	LI $t0, 0x3C00
	SW $t0, LATBCLR
	ANDI $a0, $a0, 0b1111
	SLL $a0, $a0, 10
	SW $a0, LATBSET
	
	JR $ra
	
    .end writeKYPDtoLEDs

    .ent delayKYPD
    delayKYPD:
    # Used in the case that you want to delay the inputs of the button to ensure
    # you don't receive more than 2 buttons within "one" press
    ADDI $sp, $sp, -4
    SW $t0, 0($sp)
    
    LI $t0, 500000
    kypdDelayLoop:
	ADDI $t0, $t0, -1
	BEQZ $t0, endkypdDelayLoop
	J kypdDelayLoop
    endkypdDelayLoop:
	LW $t0, 0($sp)
	ADDI $sp, $sp, 4
	JR $ra
    .end delayKYPD
    
.endif

