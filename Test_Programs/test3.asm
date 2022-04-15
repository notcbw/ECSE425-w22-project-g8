###############################################
# This program tests div and sub instructions
			
	addi $10,  $0, 8		# put 8 in $10
	addi $1,   $0, 2		# put 2 in $1
    addi $9,   $0, 1		# put 1 in $9
	sub  $2,   $10, $1		# $2 = 8-2
    sub  $2,   $2, $9       # $2 = 6-1
	div  $2, $1             # 5/2
    mfhi $4                 # load reminder (1) into r4
    mflo $5                 # load quotient (2) into r5
			
EoP:	beq	 $11, $11, EoP 	#end of program (infinite loop)
###############################################
