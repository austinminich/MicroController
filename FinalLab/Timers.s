.ifndef Timers
Timers:
    
.text
    
    .ent setupTimer1
    setupTimer1: # Timer for 10micro seconds
	# T2CON - Control Register for Timer 2
	# Bit 15 - ON Timer On bit, 1 = timer enabled, 0 = disabled
	SW $zero, T1CON
	SW $zero, TMR1
	
	LI $t0, 1 << 4
	SW $t0, IFS0CLR # Clears the interrupt flag
	SW $t0, IEC0SET # Enables the interrupt for Timer 1
	LI $t0, 6 << 2
	SW $t0, IPC1SET
	
	LI $t0, 0x8000 # PBCLK / 1 prescalar, Timer 1 on, 16-bit timer mode, use PBCLK
	SW $t0, T1CON
	# PR2 register contains 16-bit period match value, i.e. TMR2 value == PR2 value ==> timer resets
	LI $t0, 400 # Counts to 4, making the timer have a 10 micro seconds
	SW $t0, PR1
    
	JR $ra
    .end setupTimer1
    
    .ent setup32Timer
    setup32Timer: # Using timer 2 and timer 3
	# enable timer interrupt
	LI $t0, 0x1000
	SW $t0, IEC0SET

	# set timer to 32bit, 256 prescaler, internal clk
	LI $t0, 0x78
	SW $t0, T2CON

	# set interrupt priority to 6
	LI $t0, 0x18
	SW $t0, IPC3SET

	# f_PBCLK DIV prescalar = f_timer
	# f_timer * 1 second (amount of time in seconds between interrupts) = PR2
	# LI $t0, 156250 # Hard coded way for timer to count to
	SW $a0, PR2 # Used $t0 initially for hardcoded, using variable allows for change

	SW $zero, TMR2
	SW $zero, TMR3

	JR $ra
    .end setup32Timer
    
    .ent setup32Timer45
    setup32Timer45: # Using timer 4 and timer 5
	# enable timer interrupt
	LI $t0, 0x100000
	SW $t0, IEC0SET

	# set timer to 32bit, 256 prescaler, internal clk
	LI $t0, 0x78
	SW $t0, T4CON

	# set interrupt priority to 5
	LI $t0, 0x14
	SW $t0, IPC5SET

	# f_PBCLK DIV prescalar = f_timer
	# f_timer * 1 second (amount of time in seconds between interrupts) = PR2
	LI $t0, 39063 # Hard coded way for timer to count to .25 sec
	SW $t0, PR4 # Used $t0 initially for hardcoded, using variable allows for change

	SW $zero, TMR4
	SW $zero, TMR5

	JR $ra
    .end setup32Timer45
    
#     .ent setupTimer2
#     setupTimer2: # Sets up timer 2. Should be used for outputCompareMod and motors
# 	# Disables timer, then re-enables it
# 	LI $t0, 0x1000
# 	SW $t0, IEC0CLR
# 	SW $t0, IEC0SET
# 	
# 	# Set the timer with 8 prescalar, internal clock
# 	# LI $t0, 0x
# 	# SW $t0, T2CON
# 	
# 	# Sets the priority to 6
# 	LI $t0, 0x18
# 	SW $t0, IPC3SET
# 	
# 	# f_PBCLK DIV prescalar = f_timer
# 	# f_timer * 1 second (amount of time in seconds between interrupts) = PR2
# 	# LI $t0, 156250
# 	# SW $t0, PR2 # Sets the number the counter counts to
#     
# 	JR $ra
#     .end setupTimer2

# interrupt section
.section .vector_12, code # .vector_12 refers to the <12> spot in the vector table 
    J handleTimer32Int 
    
.section .vector_20, code # .vector_20 refers to the <20> in the vector table for Timer5
    J handleTimer45Int
    
.section .vector_4, code # .vector_20 refers to the <20> in the vector table for Timer5
    J handleTimer1Int

.text

    .ent handleTimer1Int
    handleTimer1Int:
	DI # Disable all incoming interrupts while handling
	ADDI $sp, $sp, -4 # Preserve any registers used
	SW $t0, 0($sp)
	
	LI $t0, 1 << 4
	SW $t0, IFS0CLR # Clears flag bit
	# ===== Execute this code =====
	
	SW $zero, TMR2
	# ===== End execute code =====
    
	LW $t0, 0($sp)
	ADDI $sp, $sp, 4 # Pop registers
	
	EI
	
	ERET
    .end handleTimer1Int
    
    .ent handleTimer32Int
    handleTimer32Int:
	DI # Always disable all incoming interrupts while handling one

	ADDI $sp, $sp, -4 # Preserve any register you are using
	SW $t0, 0($sp)

	LI $t0, 0x1000 # Clears flag bit
	SW $t0, IFS0CLR
	
	# ===== Execute this code =====
	ADD $s0, $s0, $s1 # Took $a0 from the start of program and adds variable $s1 (1 at start)
	MOVE $t0, $s0 # $t0 for LED display
	SLL $t0, $t0, 10
	SW $t0, LATB # Writes the counter to LEDs
	SW $zero, TMR2 # Resets the current counter in Timer 2
	# ===== End of code executed in interrupt =====

	LW $t0, 0($sp)
	ADDI $sp, $sp, 4 # Pop registers used in interrupts
	
	EI
	
	ERET
    .end handleTimer32Int
    
    .ent handleTimer45Int
    handleTimer45Int:
	DI # Always disable all incoming interrupts while handling one

	ADDI $sp, $sp, -4 # Preserve any register you are using
	SW $t0, 0($sp)

	LI $t0, 0x100000 # Clears flag bit
	SW $t0, IFS0CLR
	
	# ===== Execute this code =====
	ADDI $s0, $s0, 1
	SW $zero, TMR4 # Resets the current counter in Timer 2
	# ===== End of code executed in interrupt =====

	LW $t0, 0($sp)
	ADDI $sp, $sp, 4 # Pop registers used in interrupts
	
	EI
	
	ERET
    .end handleTimer45Int

    .ent start32Timer
    start32Timer:
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T2CONSET
	
	JR $ra
    .end start32Timer

    .ent stop32Timer
    stop32Timer:
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T2CONCLR
	
	JR $ra
    .end stop32Timer
    
    .ent reset32Timer
    reset32Timer:
	SW $zero, TMR2 # Resets the TMR2 counter
	LI $t0, 15 << 10
	SW $t0, LATBCLR
	
	JR $ra
    .end reset32Timer
    
    .ent start32Timer45
    start32Timer45:
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONSET
	
	JR $ra
    .end start32Timer45

    .ent stop32Timer45
    stop32Timer45:
	LI $t0, 1 << 15 # <15> bit for enabling timer
	SW $t0, T4CONCLR
	
	JR $ra
    .end stop32Timer45
    
    .ent setupMultiVec
    setupMultiVec:
        LI $t0, 1 << 12 # For INTCON<12> = 1
	SW $t0, INTCONSET
    
	JR $ra
    .end setupMultiVec
    
.endif







