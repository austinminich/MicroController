.include "ROBOControl.s"
    
.ifndef ROBOFigureSkating
FigureSkating:
    
.text # $a0 are the operands that are passed into 
    
    .ent ROBOCircle
    ROBOCircle: # $a0 could be used for how big the circle is but for now it's not used
	ADDI $sp, $sp, -4 # Jumping within a function
	SW $ra, 0($sp) # Preserve $ra
	
	LI $a0, 7 # The amount of HALF seconds, should've just used timer 3 and count in miliseconds
	JAL ROBOBankLeft
	
	LW $ra, 0($sp)
	ADDI $sp, $sp, 4 # Pop $ra
    
	JR $ra
    .end ROBOCircle
    
    .ent ROBOSquare
    ROBOSquare: # $a0 is how far the edges 
	ADDI $sp, $sp, -4 # Jumping within a function
	SW $ra, 0($sp) # Preserve $ra
	
	LI $a0, 4 # The amount of HALF seconds, should've just used timer 3 and count in miliseconds
	JAL ROBOForward
	LI $a0, 2
	JAL ROBOLeft
	LI $a0, 4
	JAL ROBOForward
	LI $a0, 2
	JAL ROBOLeft
	LI $a0, 4
	JAL ROBOForward
	LI $a0, 2
	JAL ROBOLeft
	LI $a0, 4
	JAL ROBOForward
	
	LW $ra, 0($sp)
	ADDI $sp, $sp, 4 # Pop $ra
	
	JR $ra
    .end ROBOSquare
    
    .ent ROBOTriangle
    ROBOTriangle:
	ADDI $sp, $sp, -4 # Jumping within a function
	SW $ra, 0($sp) # Preserve $ra
	
	LI $a0, 4 # The amount of HALF seconds, should've just used timer 3 and count in miliseconds
	JAL ROBOForward
	LI $a0, 3
	JAL ROBOLeft
	LI $a0, 4
	JAL ROBOForward
	LI $a0, 3
	JAL ROBOLeft
	LI $a0, 4
	JAL ROBOForward
	
	LW $ra, 0($sp)
	ADDI $sp, $sp, 4 # Pop $ra
    
	JR $ra
    .end ROBOTriangle
    
    .ent ROBOFig8
    ROBOFig8:
	ADDI $sp, $sp, -4 # Jumping within a function
	SW $ra, 0($sp) # Preserve $ra
	
	LI $a0, 4 # The amount of HALF seconds, should've just used timer 3 and count in miliseconds
	JAL ROBOBankLeft
	JAL ROBOForward
	JAL ROBOBankRight
	JAL ROBOForward
	
	LW $ra, 0($sp)
	ADDI $sp, $sp, 4 # Pop $ra
    
	JR $ra
    .end ROBOFig8
    
.endif



