.ifndef UART
UARTFuncs:
    
.data
    # Bluetooth commands
    # enterCommandMode:	.asciiz "$$$"
    # exitCommandMode:	.byte '-', '-', '-', 13, 0
    # setMasterMode:	.asciiz "SM,1"
    
.text
    
    .ent setupUART1TX
    setupUART1TX: # Top of JE port
	# Sets up UART1 for trasnmitting data at 9,600 bps
    
	# Transmitting UART
	# 1: U1BRG = 259, gives a baud rate of ~9600Hz
	LI $t0, 259
	SW $t0, U1BRG
	# 2: UART serial frame == 8 data bits, 1 stop bit, no parity (all 0)
	SW $zero, U1MODE # Reset UART
	SW $zero, U1STA
	# 3: No interrupts right now
	# 4: Enable UART Transmission
	LI $t0, 1 << 10
	SW $t0, U1STA
	# 5: Enable UART Module
	LI $t0, 1 << 15
	SW $t0, U1MODE
    
	JR $ra
    .end setupUART1TX
    
    .ent setupUART1RX
    setupUART1RX:
	# Sets up UART1 for receiving at 9,600 bps
    
	# Transmitting UART
	# 1: U1BRG = 259, gives a baud rate of ~9600Hz
	LI $t0, 259
	SW $t0, U1BRG
	# 2: UART serial frame == 8 data bits, 1 stop bit, no parity (all 0)
	SW $zero, U1MODE # Reset UART
	SW $zero, U1STA
	# 3: No interrupts right now
	# 4: Enable UART Receiving
	LI $t0, 1 << 12
	SW $t0, U1STA
	# 5: Enable UART Module
	LI $t0, 1 << 15
	SW $t0, U1MODE
    
	JR $ra
    .end setupUART1RX
    
    .ent setupUART2BlueRX # Slave, auto discover, RN-42 chip
    setupUART2BlueRX: 
	# Sets up UART2 for the Bluetooth module to receive at 115.2 kbps
	
	# 1: U1BRG = 259, gives a baud rate of ~9600Hz, 21 = 115.2kHz
	LI $t0, 21
	SW $t0, U2BRG
	# 2: UART serial frame == 8 data bits, 1 stop bit, no parity (all 0)
	SW $zero, U2MODE # Reset UART
	SW $zero, U2STA
	# 3: No interrupts right now
	# 4: Enable UART Receiver
	LI $t0, 1 << 12
	SW $t0, U2STA
	# 5: Enable UART Module
	LI $t0, 1 << 15
	SW $t0, U2MODE
    
	JR $ra
    .end setupUART2BlueRX
    
    .ent setupUART2BlueTX # Master, pair, RN-42 chip, must set to master because by defualt its in slave
    # <cr> = 13 decimal
    # SM,1 # If this is sent, this makes the bluetooth go into master mode
    
    setupUART2BlueTX: # JH port
	# Sets up UART2 for the Bluetooth module to transmit at 115.2 kbps
	# 1: U1BRG = 259, gives a baud rate of ~9600Hz, 21 = 115.2kHz
	LI $t0, 259
	SW $t0, U2BRG
	# 2: UART serial frame == 8 data bits, 1 stop bit, no parity (all 0)
	SW $zero, U2MODE # Reset UART
	SW $zero, U2STA
	# 3: No interrupts right now
	# 4: Enable UART Transmitter
	LI $t0, 1 << 10
	SW $t0, U2STASET
	LI $t0, 1 << 12
	SW $t0, U2STASET
	
	# 5: Enable UART Module
	LI $t0, 1 << 15
	SW $t0, U2MODE
	
	# Was attempting to enter master mode by coding but changed to just connect
	# the two bluetooths via putty
# 	ADDI $sp, $sp, -8
# 	SW $ra, 0($sp)
# 	SW $a0, 4($sp)
# 	# Setup to being a master
# 	LA $a0, enterCommandMode
# 	JAL sendToUART2
# 	NOP
# 	JAL UARTdelay # IMPORTANT
# 	
# 	LA $a0, setMasterMode
# 	JAL sendToUART2
# 	NOP
# 	JAL UARTdelay # IMPORTANT
# 	
# 	LA $a0, exitCommandMode
# 	JAL sendToUART2
# 	NOP
# 	JAL UARTdelay # IMPORTANT
# 	LW $ra, 0($sp)
# 	LW $a0, 4($sp)
	
	JR $ra
    .end setupUART2BlueTX
    
    .ent sendToUART2
    sendToUART2: # $a0 is the message being passed to send
	MOVE $t0, $a0
	startSendU2:
	    LB $t1, 0($t0)
	    ADDI $t0, $t0, 1 # Increment by one because bytes are being loaded
	    BEQZ $t1, endSendU2
	waitToSendU2:
	    LW $t2, U2STA
	    ANDI $t2, $t2, 1 << 9 # Transmit buffer bit
	    BEQZ $t2, endWaitToSendU2
	    J waitToSendU2
	endWaitToSendU2:
	    SB $t1, U2TXREG
	    J startSendU2
	endSendU2:
	    JR $ra
    .end sendToUART2
    
    .ent receiveBlueData
    receiveBlueData: # Returns instruction as 0xabcd as $v0
	# Used with Bluetooth
	
	MOVE $v0, $zero # Clear v0
	LI $t1, 4 # Number of digits required
	waitReceive:
	# Receive byte, perform decode to correct character, continue until
	#   recieved 4 digits, then add the instruction to the intstruction data memory
	
	LW $t0, U2STA
	ANDI $t0, $t0, 1 # Receive buffer data available, 1 = has data, 0 = empty
	BEQZ $t0, waitReceive # If the receive buffer is empty, loop back and wait for it to contain something. If the receive buffer has contents then continue
	MOVE $t0, $zero # Clears t0 for each loop
	LB $t0, U2RXREG # Loads the byte from U2RXREG
	# BEQZ $t0, waitReceive # If there's nothing in the byte, keep looping
	
	# Which
	BEQ $t1, 4, firstDigit
	BEQ $t1, 3, secondDigit
	BEQ $t1, 2, thirdDigit
	BEQ $t1, 1, fourthDigit
	
	firstDigit:
	SLL $t0, $t0, 12 # Shifts the hex to it's appropriate spot
	OR $v0, $v0, $t0 # ORs the digit with the instruction v0
	ADDI $t1, $t1, -1 # One less digit required
	J waitReceive
	
	secondDigit:
	SLL $t0, $t0, 8 # Shifts hex to the 3rd hex spot
	OR $v0, $v0, $t0 # Combine instruction
	ADDI $t1, $t1, -1 # One less digit
	J waitReceive
	
	thirdDigit:
	SLL $t0, $t0, 4 # Shifts hex to 2nd hex spot
	OR $v0, $v0, $t0 # Combine instruction
	ADDI $t1, $t1, -1 # One less digit
	J waitReceive
	
	fourthDigit:
	# No need to shift
	OR $v0, $v0, $t0
	# No need to decrement since it's last digit
	
	endReceive:
	JR $ra
    .end receiveBlueData
    
    .ent UARTdelay
    UARTdelay:
	# Just delay for some time to allow settings to change
	LI $t0, 100000
	UARTdelayLoop:
	    ADDI $t0, $t0, -1
	    BEQZ $t0, endUARTdelayLoop
	endUARTdelayLoop:
	    JR $ra
    .end UARTdelay
    
.endif





