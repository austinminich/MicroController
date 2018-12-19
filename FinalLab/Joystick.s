.ifndef Joystick
Joystick:
    
.data
    
.text
    
    .ent setupRightJoystick # Uses SPI
    setupRightJoystick:
	# Reset SPI1 control register
	SW $zero, SPI1CON # Reset SPI2
	
	# Setup baud rate of SPI2 module, f_PBCLK/(2*(1+SPI2BRG)) = f_SPI2
	LI $t0, 2082
	SW $t0, SPI1BRG
	# No interrupts right now
	# Ensure receive overflow flag is cleared
	LI $t0, 1 << 6
	SW $t0, SPI1STATCLR
	
	# Setup the slave select pin as an output. ----- Switch this to what SPI1 is
	# As we have only 1 slave (joystick), force high, i.e. always receive from joystick
	LI $t0, 1 << 9
	SW $t0, TRISDCLR
	SW $t0, LATDSET

	# Set the MCU to master, turn on SPI2, and set correct mode for the Joystick
	# Mode: (15, 8, 6, 5 for Joystick)
	LI $t0, 1 << 5
	ORI $t0, 1 << 8
	ORI $t0, 1 << 6
	ORI $t0, 1 << 15
	SW $t0, SPI1CON
    
	JR $ra
    .end setupRightJoystick
    
    .ent setupLeftJoystick # Uses SPI
    setupLeftJoystick:
	# Reset SPI2 control register
	SW $zero, SPI2CON # Reset SPI2
	
	# Setup baud rate of SPI2 module, f_PBCLK/(2*(1+SPI2BRG)) = f_SPI2
	LI $t0, 2082
	SW $t0, SPI2BRG
	# No interrupts right now
	# Ensure receive overflow flag is cleared
	LI $t0, 1 << 6
	SW $t0, SPI2STATCLR
	
	# Setup the slave select pin as an output.
	# As we have only 1 slave (joystick), force high, i.e. always receive from joystick
	LI $t0, 1 << 9
	SW $t0, TRISGCLR
	SW $t0, LATGSET

	# Set the MCU to master, turn on SPI2, and set correct mode for the Joystick
	# Mode: (15, 8, 6, 5 for Joystick)
	LI $t0, 1 << 5
	ORI $t0, 1 << 8
	ORI $t0, 1 << 6
	ORI $t0, 1 << 15
	SW $t0, SPI2CON
    
	JR $ra
    .end setupLeftJoystick
    
#     .ent readRightJoystick
#     readRightJoystick: # Returns $v0 as the (x,y) position that the joystick is in
# 	# The Pmod JSTK2 communicates with the host board via the SPI protocol with SPI Mode 0,
# 	# CS active low, a 1 MHz clock, and each data byte organized MSb first.
# 	# With the Pmod JSTK2, there are two types of data packet protocols:
# 	    # the standard data packet of 5 bytes and an extended data packet with 6 or 7 bytes in total
# 	LI $t1, 1 << 9
#         SW $t1, LATGCLR
#         LI $t5, 5 # For the 5 bytes in joystick
# 	startJoyReadR:
# #       LI $a3, 1
# #       JAL delay
# 	    LI $t7, 50000
# 	    dummyLoop2:
# 		ADDI $t7, $t7, -1
# 		BNEZ $t7, dummyLoop2
# 		BEQZ $t5, endJoyReadR
# 	    waitJoyReadR:
# 		# Is the SPI2 Module busy? If so, wait to send the next char
# 		LW $t0, SPI1STAT
# 		ANDI $t0, $t0, 1 << 11
# 		BNEZ $t0, waitJoyReadR
# 		BEQ $t5, 5, readJoyR1
# 		BEQ $t5, 4, readJoyR2
# 		BEQ $t5, 3, readJoyR3
# 		BEQ $t5, 2, readJoyR4
# 		BEQ $t5, 1, readJoyR5
# 		J waitJoyReadR
# 	    readJoyR1:
# 		SB $zero, SPI1BUF # Clear the read buffer
# 		LB $s0, SPI1BUF # send next char
# 		ADDI $t5, $t5, -1
# 		J startJoyReadR
# 	    readJoyR2:
# 		SB $zero, SPI1BUF 
# 		LB $t0, SPI1BUF 
# 		ADDI $t5, $t5, -1
# 		J startJoyReadR
# 	    readJoyR3:
# 		SB $zero, SPI1BUF 
# 		LB $t0, SPI1BUF 
# 		ADDI $t5, $t5, -1
# 		J startJoyReadR
# 	    readJoyR4:
# 		SB $zero, SPI1BUF 
# 		LB $t0, SPI1BUF 
# 		ADDI $t5, $t5, -1
# 		ANDI $t2, $t0, 0xFF
# 		J startJoyReadR
# 	    readJoyR5:
# 		SB $zero, SPI1BUF 
# 		LB $t0, SPI1BUF 
# 		ADDI $t5, $t5, -1
# 		ANDI $t3, $t0, 0x3
# 		SLL $t3, $t3, 8
# 		OR $v0, $t2, $t3
# 		J startJoyReadR
# 	    endJoyReadR:
# 		LI $t1, 1 << 9
# 		SW $t1, LATGSET
# 	
# 	LW $ra, 0($sp)
# 	ADDI $sp, $sp, 4
#     
# 	JR $ra
#     .end readRightJoystick
    
.ent readRightJoy # $a0 is the information being sent to LCD this doesn't work. it sends trash
readRightJoy: 
    
    ADDI $sp, $sp, -4 # Preserve any register you are using
    SW $ra, 0($sp)
	
    LI $t1, 1 << 9
    SW $t1, LATDCLR
    LI $t5, 5
    startSPISendR:
#         LI $a3, 1
#         JAL delay
	LI $t7, 30000
	dummyLoopR:
	    addi $t7, $t7, -1
	    bnez $t7, dummyLoopR
	    BEQZ $t5, endSPISendR
    waitSPISendR:
        # Is the SPI2 Module busy? If so, wait to send the next char
        LW $t0, SPI1STAT
        ANDI $t0, $t0, 1 << 11
        BNEZ $t0, waitSPISendR
        BEQ $t5, 5, readSPI1R
        BEQ $t5, 4, readSPI2R
        BEQ $t5, 3, readSPI3R
        BEQ $t5, 2, readSPI4R
        BEQ $t5, 1, readSPI5R
        J waitSPISendR
    readSPI1R:
        # Even though we don't care about the data coming from the LCD
        # still want to read so a read buffer overflow doesn't happen
        SB $zero, SPI1BUF # Clear the read buffer
        LB $s0, SPI1BUF # send next char
        ADDI $t5, $t5, -1
	
        J startSPISendR
    readSPI2R:
        SB $zero, SPI1BUF # Clear the read buffer
        LB $t0, SPI1BUF # send next char
        ADDI $t5, $t5, -1
        J startSPISendR
    
    readSPI3R:
	SB $zero, SPI1BUF # send next char
        LB $t0, SPI1BUF # Clear the read buffer
        ADDI $t5, $t5, -1
        J startSPISendR
    
    readSPI4R:
        SB $zero, SPI1BUF # Clear the read buffer
        LB $t0, SPI1BUF # send next char
        ADDI $t5, $t5, -1
	ANDI $t2, $t0, 0xFF
        J startSPISendR
    
    readSPI5R:
	SB $zero, SPI1BUF # Clear the read buffer
	LB $t0, SPI1BUF # send next char
	ADDI $t5, $t5, -1
	ANDI $t3, $t0, 0x3
	SLL $t3, $t3, 8
	OR $v0, $t2, $t3
	J startSPISendR
	
    endSPISendR:
        LI $t1, 1 << 9
        SW $t1, LATDSET
	
    LW $ra, 0($sp)
    ADDI $sp, $sp, 4 
    
        JR $ra
.end readRightJoy 
    
.ent readLeftJoy # $a0 is the information being sent to LCD this doesn't work. it sends trash
readLeftJoy: 
    
    ADDI $sp, $sp, -4 # Preserve any register you are using
    SW $ra, 0($sp)
	
    LI $t1, 1 << 9
    SW $t1, LATGCLR
    LI $t5, 5
    startSPISendj:
#         LI $a3, 1
#         JAL delay
	LI $t7, 30000
	dummyLoop:
	    addi $t7, $t7, -1
	    bnez $t7, dummyLoop
	    BEQZ $t5, endSPISendj
    waitSPISendj:
        # Is the SPI2 Module busy? If so, wait to send the next char
        LW $t0, SPI2STAT
        ANDI $t0, $t0, 1 << 11
        BNEZ $t0, waitSPISendj
        BEQ $t5, 5, readSPI1
        BEQ $t5, 4, readSPI2
        BEQ $t5, 3, readSPI3
        BEQ $t5, 2, readSPI4
        BEQ $t5, 1, readSPI5
        J waitSPISendj
    readSPI1:
        # Even though we don't care about the data coming from the LCD
        # still want to read so a read buffer overflow doesn't happen
        SB $zero, SPI2BUF # Clear the read buffer
        LB $s0, SPI2BUF # send next char
        ADDI $t5, $t5, -1
	
        J startSPISendj
    readSPI2:
        SB $zero, SPI2BUF # Clear the read buffer
        LB $t0, SPI2BUF # send next char
        ADDI $t5, $t5, -1
        J startSPISendj
    
    readSPI3:
	SB $zero, SPI2BUF # send next char
        LB $t0, SPI2BUF # Clear the read buffer
        ADDI $t5, $t5, -1
        J startSPISendj
    
    readSPI4:
        SB $zero, SPI2BUF # Clear the read buffer
        LB $t0, SPI2BUF # send next char
        ADDI $t5, $t5, -1
	ANDI $t2, $t0, 0xFF
        J startSPISendj
    
    readSPI5:
	SB $zero, SPI2BUF # Clear the read buffer
	LB $t0, SPI2BUF # send next char
	ADDI $t5, $t5, -1
	ANDI $t3, $t0, 0x3
	SLL $t3, $t3, 8
	OR $v0, $t2, $t3
	J startSPISendj
	
    endSPISendj:
        LI $t1, 1 << 9
        SW $t1, LATGSET
	
    LW $ra, 0($sp)
    ADDI $sp, $sp, 4 
    
        JR $ra
.end readLeftJoy 
    
#     .ent readLeftJoystick
#     readLeftJoystick: # Returns $v0 as the (x,y) position that the joystick is in
# 	# The Pmod JSTK2 communicates with the host board via the SPI protocol with SPI Mode 0,
# 	# CS active low, a 1 MHz clock, and each data byte organized MSb first.
# 	# With the Pmod JSTK2, there are two types of data packet protocols:
# 	    # the standard data packet of 5 bytes and an extended data packet with 6 or 7 bytes in total
# 	LI $t1, 1 << 9
#         SW $t1, LATGCLR
#         LI $t5, 5 # For the 5 bytes in joystick
# 	startJoyRead:
# #       LI $a3, 1
# #       JAL delay
# 	    LI $t7, 3
# 	    dummyLoop:
# 		ADDI $t7, $t7, -1
# 		BNEZ $t7, dummyLoop
# 		# OP
# 		BEQZ $t5, endJoyRead
# 	    waitJoyRead:
# 		# Is the SPI2 Module busy? If so, wait to send the next char
# 		LW $t0, SPI2STAT
# 		ANDI $t0, $t0, 1 << 11
# 		BNEZ $t0, waitJoyRead
# 		BEQ $t5, 5, readSPI1
# 		BEQ $t5, 4, readSPI2
# 		BEQ $t5, 3, readSPI3
# 		BEQ $t5, 2, readSPI4
# 		BEQ $t5, 1, readSPI5
# 		J waitJoyRead
# 	    readSPI1:
# 		SB $zero, SPI2BUF # Clear the read buffer
# 		LB $s0, SPI2BUF # send next char
# 		ADDI $t5, $t5, -1
# 		J startJoyRead
# 	    readSPI2:
# 		SB $zero, SPI2BUF 
# 		LB $t0, SPI2BUF 
# 		ADDI $t5, $t5, -1
# 		J startJoyRead
# 	    readSPI3:
# 		SB $zero, SPI2BUF 
# 		LB $t0, SPI2BUF 
# 		ADDI $t5, $t5, -1
# 		J startJoyRead
# 	    readSPI4:
# 		SB $zero, SPI2BUF 
# 		LB $t0, SPI2BUF 
# 		ADDI $t5, $t5, -1
# 		ANDI $t2, $t0, 0xFF
# 		J startJoyRead
# 	    readSPI5:
# 		SB $zero, SPI2BUF 
# 		LB $t0, SPI2BUF 
# 		ADDI $t5, $t5, -1
# 		ANDI $t3, $t0, 0x3
# 		SLL $t3, $t3, 8
# 		OR $v0, $t2, $t3
# 		J startJoyRead
# 	    endJoyRead:
# 		LI $t1, 1 << 9
# 		SW $t1, LATGSET
# 	    
# # 	# I had a classmate help me with reading from the joystick
# # 	ADDI $sp, $sp, -4
# # 	SW $ra, 0($sp)
# # 	
# # 	LI $t0, 1 << 9
# # 	SW $t0, LATGCLR # Drive low
# # 	
# # 	JAL delayJoystick # Delay as required
# # 	readByte1:
# # 	    LW $t0, SPI2STAT
# # 	    ANDI $t0, $t0, 1 << 11 # Check is the bus is busy
# # 	    BNEZ $t0, readByte1
# # 	    MOVE $t0, $zero
# # 	    SB $t0, SPI2BUF # zero the first byte then read
# # 	    LB $t0, SPI2BUF
# # 	    
# # 	    JAL delayJoystick # Delay between each byte read
# # 	    
# # 	readByte2:
# # 	    LW $t0, SPI2STAT
# # 	    ANDI $t0, $t0, 1 << 11
# # 	    BNEZ $t0, readByte2
# # 	    MOVE $t0, $zero
# # 	    SB $t0, SPI2BUF
# # 	    LB $t0, SPI2BUF
# # 	    
# # 	    JAL delayJoystick
# # 	    
# # 	readByte3:
# # 	    LW $t0, SPI2STAT
# # 	    ANDI $t0, $t0, 1 << 11
# # 	    BNEZ $t0, readByte3
# # 	    MOVE $t0, $zero
# # 	    SB $t0, SPI2BUF
# # 	    LB $t0, SPI2BUF
# # 	    
# # 	    JAL delayJoystick
# # 	    
# # 	readByte4:
# # 	    LW $t0, SPI2STAT
# # 	    ANDI $t0, $t0, 1 << 11
# # 	    BNEZ $t0, readByte4
# # 	    MOVE $t0, $zero
# # 	    SB $t0, SPI2BUF
# # 	    LB $t0, SPI2BUF
# # 	    
# # 	    # Pack into $v0
# # 	    LI $t1, 0b11111111
# # 	    AND $v0, $v0, $t1
# # 	    
# # 	    JAL delayJoystick
# # 	    
# # 	readByte5:
# # 	    LW $t0, SPI2STAT
# # 	    ANDI $t0, $t0, 1 << 11
# # 	    BNEZ $t0, readByte5
# # 	    MOVE $t0, $zero
# # 	    SB $t0, SPI2BUF
# # 	    LB $t0, SPI2BUF
# # 	    
# # 	    # Pack into $v0
# # 	    LI $t1, 0b11111111
# # 	    AND $v0, $v0, $t1
# # 	    SLL $t0, $t0, 8
# # 	    OR $v0, $v0, $t0
# # 	    
# # 	    JAL delayJoystick
# # 	    
# # 	LI $t1, 0b11111111
# # 	AND $t0, $t0, $t1
# # 	
# # 	SLL $t0, 8
# # 	OR $v0, $v0, $t0
# # 	    
# # 	LI $t0, 1 << 9
# # 	SW $t0, LATGSET # Drive high after you've received data
# 	
# 	LW $ra, 0($sp)
# 	ADDI $sp, $sp, 4
#     
# 	JR $ra
#     .end readLeftJoystick
    
    .ent delayJoystick
    delayJoystick:
	LI $t0, 500000
	joystickLoop:
	    ADDI $t0, $t0, -1
	    BEQZ $t0, endJoyLoop
	    J joystickLoop
	endJoyLoop:
    
	JR $ra
    .end delayJoystick
    
.endif
    

# .global main
# 
# .data
# clear_disp:		.byte 0x1B, '[', 'j', 0
# timer1Counter:		.word 0
# forwardMessage:		.asciiz "Forward"
# backwardMessage:	.asciiz "Backward"
# stopMessage:		.asciiz "Stopped"
#     
# .text
# 
# .ent main
# main:
#     DI
#     JAL setupTimer1
#     JAL setupJoystick
#     JAL setupUART1LCD
#     JAL setupTimer45
#     JAL setupMultiVec
#     EI
#     
#     loop:
# 	JAL sendSPILCD
# 	MOVE $a1, $v0
# 	JAL choice
# 	
#     J loop
# .end main
#     
# .ent setupJoystick # Uses SPI
# setupJoystick:
#     # Reset SPI2 control register
#     SW $zero, SPI2CON # Reset SPI2
# 
#     # Setup baud rate of SPI2 module, f_PBCLK/(2*(1+SPI2BRG)) = f_SPI2
#     LI $t0, 19    #  2082 is 9600 freq   255
#     SW $t0, SPI2BRG
#     # No interrupts right now
#     # Ensure receive overflow flag is cleared
# #     LI $t0, 1 << 6
# #     SW $t0, SPI2STATCLR
# 	
#     # Setup the slave select pin as an output.
#     # As we have only 1 slave (joystick), force high, i.e. always receive from joystick
#     LI $t0, 1 << 9
#     SW $t0, TRISGCLR
#     SW $t0, LATGSET
# 
#     # Set the MCU to master, turn on SPI2, and set correct mode for the Joystick
#     # Mode: (15, 8, 6, 5 for Joystick)
#     LI $t0, 1 << 5
#     ORI $t0, 1 << 8
#     # ORI $t0, 1 << 6
#     ORI $t0, 1 << 15
#     SW $t0, SPI2CON
#     
#     JR $ra
# .end setupJoystick
# 

# 
# .ent setupTimer1
# setupTimer1: # Using timer 4 and timer 5
#     # enable timer interrupt
#     LI $t0, 1 << 4
#     SW $t0, IEC0SET
#     
#     # set timer to 16bit, 8 prescaler, internal clk
#     LI $t0, 0x10
#     SW $t0, T1CON
# 
#     # set interrupt priority to 5
#     LI $t0, 0x14
#     SW $t0, IPC1SET
# 
#     # f_PBCLK DIV prescalar = f_timer
#     # f_timer * 1 second (amount of time in seconds between interrupts) = PR2
#     LI $t0, 5000 # Hard coded way for timer to count to .25 sec
#     SW $t0, PR1 # Used $t0 initially for hardcoded, using variable allows for change
#     
#     SW $zero, TMR1
# 
#     JR $ra
# .end setupTimer1
#     
#         
# .section .vector_4, code # .vector_20 refers to the <20> in the vector table for Timer5
#     J timer1Int
# 
# .text
# 
# .ent timer1Int
# timer1Int:
#     DI
# 
#     ADDI $sp, $sp, -4 # Preserve any register you are using
#     SW $t0, 0($sp)
#     
#     LI $t0, 1 << 4 # Clears flag bit
#     SW $t0, IFS0CLR
# 
#     LW $t0, timer1Counter
#     ADDI $t0, $t0, -1
#     SW $t0, timer1Counter
#     
#     LW $t0, 0($sp)
#     ADDI $sp, $sp, 4 # Pop registers used in interrupts
# 	
#     EI
#     
#     ERET
# 
# .end timer1Int
# 
# .ent delay
# delay:
#     
#     ADDI $sp, $sp, -4 
#     SW $ra, 0($sp)
#     
#     SW $a3, timer1Counter
#     LI $t7, 1 << 15
#     SW $t7, T1CONSET
#     delayLoop:
# 	LW $t6, timer1Counter   
# 	BNEZ $t6, delayLoop
#     eDelayLoop:
# 	SW $t7, T1CONCLR
# 	SW $zero, TMR1
# 	
#     LW $ra, 0($sp)
#     ADDI $sp, $sp, 4 
#     
#     JR $ra
# .end delay
# 	
# .ent setupUART1LCD
# setupUART1LCD:
#     # Sets up UART1 for the LCD screen
#     # Transmitting UART
#     # 1: U1BRG = 259, gives a baud rate of ~9600Hz
#     LI $t0, 259
#     SW $t0, U1BRG
#     # 2: UART serial frame == 8 data bits, 1 stop bit, no parity (all 0)
#     SW $zero, U1MODE # Reset UART
#     SW $zero, U1STA
#     # 3: No interrupts right now
#     # 4: Enable UART Transmission
#     LI $t0, 1 << 10
#     SW $t0, U1STA
#     # 5: Enable UART Module
#     LI $t0, 1 << 15
#     SW $t0, U1MODE
#     
#     JR $ra
# .end setupUART1LCD
#     
# .ent setupTimer45
# setupTimer45: # Using timer 4 and timer 5
#     # enable timer interrupt
#     LI $t0, 0x100000
#     SW $t0, IEC0SET
# 
#     # set timer to 32bit, 256 prescaler, internal clk
#     LI $t0, 0x78
#     SW $t0, T4CON
# 
#     # set interrupt priority to 5
#     LI $t0, 0x14
#     SW $t0, IPC5SET
# 
#     # f_PBCLK DIV prescalar = f_timer
#     # f_timer * 1 second (amount of time in seconds between interrupts) = PR2
#     LI $t0, 39063 # Hard coded way for timer to count to .25 sec
#     SW $t0, PR4 # Used $t0 initially for hardcoded, using variable allows for change
# 
#     SW $zero, TMR4
#     SW $zero, TMR5
# 
#     JR $ra
# .end setupTimer45
#     
#     
# .section .vector_20, code # .vector_20 refers to the <20> in the vector table for Timer5
#     J timer45Int
# 
# .text
# 
# .ent timer45Int
# timer45Int:
#     DI # Always disable all incoming interrupts while handling one
# 
#     ADDI $sp, $sp, -4 # Preserve any register you are using
#     SW $t0, 0($sp)
# 
#     LI $t0, 0x100000 # Clears flag bit
#     SW $t0, IFS0CLR
# 	
#     # ===== Execute this code =====
#     ADDI $s0, $s0, 1
#     SW $zero, TMR4 # Resets the current counter in Timer 2
#     # ===== End of code executed in interrupt =====
# 
#     LW $t0, 0($sp)
#     ADDI $sp, $sp, 4 # Pop registers used in interrupts
#     
#     EI
# 	
#     ERET
# .end timer45Int
#     
#     
# .ent sendData
# sendData: # $a0 is the message being passed to send
#     MOVE $t0, $a2
#     startSend:
# 	LB $t1, 0($t0)
# 	ADDI $t0, $t0, 1 # Increment by one because bytes are being loaded
# 	BEQZ $t1, endSend
#     waitToSend:
#         LW $t2, U1STA
#         ANDI $t2, $t2, 1 << 9 # Transmit buffer bit
#         BEQZ $t2, endWaitToSend
#         J waitToSend
#     endWaitToSend:
# 	SB $t1, U1TXREG
# 	J startSend
#     endSend:
#         JR $ra
# .end sendData
# 	
# 	
# 	
# .ent setupMultiVec
# setupMultiVec:
#     LI $t0, 1 << 12 # For INTCON<12> = 1
#     SW $t0, INTCONSET
#     
#     JR $ra
# .end setupMultiVec
#     
#     
# .ent choice
# choice:
#     MOVE $t0, $a1
#     
#     BGT $t0, 600, forward
#     BGT $t0, 400, stop
#     J backward
#     
#     forward:
# 	LA $a2, forwardMessage
#     	JAL sendData
# 
# 	J endChoice
# 	
#     stop:
# 	LA $a2, stopMessage
#     	JAL sendData
# 	J endChoice
# 	
#     backward:
# 	LA $a2, backwardMessage
#     	JAL sendData
#     
#     endChoice:
# 	
#     JR $ra
# .end choice

    


