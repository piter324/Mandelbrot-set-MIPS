.data
name: .asciiz "512x512.bmp"
out: .asciiz "out.bmp"
header: .space 54
#obrazek: .space 49152 # 128x128 pikseli, 3 bajty na piksel
width: .word 0
height: .word 0
size: .space 4 # bmp file size
offset: .word 0 # bmp offset
pixelAreaSize: .word 0
padding: .word 0
welcomePrompt: .asciiz "Program generujacy Zbiory Mandelbrota. Bitmapa wyjsciowa ma zawsze nazwe: out.bmp\n\n"
iterPrompt: .asciiz "Podaj liczbe iteracji przy generowaniu zbioru Mandelbrota: "
iterCount: .word 0
openPrompt: .asciiz "Pomyslnie otwarto plik\n"
closePrompt: .asciiz "Pomyslnie zamknieto plik\n"
fileErrorPrompt: .asciiz "Blad otwierania pliku\n"
obrazek: .space 786432
heapAddress: .word 0

.text
.globl main
main:	
# -------- File opening 
		
	li $v0, 4 # print welcomePrompt prompt
	la $a0, welcomePrompt
	syscall
	
	li $v0, 4 # print iterCount prompt
	la $a0, iterPrompt
	syscall
	li $v0, 5 # load iterations count
	syscall
	
	sw $v0, iterCount

	la $k0, header
	#addiu $k0, $k0, 2
	
	li $v0, 13 # Open file
	la $a0, name
	li $a1, 0 # 0 - read-only
	li $a2, 0        	
	syscall
	move $s0, $v0 # $s0 holds file descriptor

	blez $s0,fileError
	li $v0, 4 # display file opened prompt
	la $a0, openPrompt
	syscall
	
	li $v0, 14 # load bitmap file header (till 14th byte)
	move $a0, $s0
	move $a1, $k0
	li $a2, 14
	syscall
					
	move $t0, $k0 # $s1 holds offset
	addiu $t0, $t0, 10
	lwr $s1, ($t0)
	sw $s1,	offset
  
	li $v0, 14 # Load bitmap info header
	move $a0, $s0
	addiu $a1, $t0, 4
	addi $a2, $s1, -14
	syscall
		
	move $t0, $k0	# $s3 holds image width
	addiu $t0, $t0, 18
	lwr $s3, ($t0)
	sw $s3,	width
		
	addiu $t0, $t0, 4 # $s2 holds image height
	lwr $s2, ($t0)
	sw $s2,	height
	
	and $s5, $s3, 3 # $s5 holds number of padding pixels
	sw $s5,	padding
	
	mul $t2,$s3,3
	add $t2,$t2,$s5
	mul $t2,$t2,$s2
	sw $t2,pixelAreaSize
	
	#li $v0,9
	#lw $a0,pixelAreaSize
	#syscall
	#sw $v0,heapAddress
	# $v0 - address of allocated memory
	
	move $a0,$s0 # load image and allocate in memory
	la $a1,obrazek
	lw $a2,pixelAreaSize
	li $v0,14
	syscall
	
	#move $t1,$v0 #number of loaded bytes into t1
	
	li $v0,16
	move $a0,$s0
	syscall #close file for reading
	
	
	#li $s0,128 #max value for width and height
	#sb $s0,width
	#sb $s0,height
	
#--------------------HERE FILE READING ENDS--------------------------
	
	la $t0,obrazek
	li $t1,0 #width (x) counter
	li $t2,0 #height (y) counter
	
# for Q notation 8 oldest bits for integer, the rest (24) for fractional part
	li $s3, -2
	sll $s3,$s3,24 # $s3 holds minimum value for both axis
	li $s4, 4
	sll $s4,$s4,24
	lw $s5,width
	div $s4,$s4,$s5 #ratioX (0.03125)
	
	li $s6, 4
	sll $s6,$s6,24
	lw $s5,height
	div $s6,$s6,$s5 #ratioY (0.03125)
	
	li $s2,4 #boudary for x^2+y^2
	sll $s2,$s2,24
	
loop:
	move $t4,$s6 #load Y ratio
	mul $t4,$t4,$t2 #multiply ratio by y counter
	add $t4,$t4,$s3 #add minY to multiplied ratio
	move $t9,$t4
	#t4,t9 contains initial imaginary part (y) of the number
	
	move $t3,$s4 #load X ratio
	mul $t3,$t3,$t1 #multiply ratio by x counter
	add $t3,$t3,$s3 #add minX to multiplied ratio
	move $t8,$t3
	#t3,t8 contains initial real part (x) of the number
	lw $s7, iterCount #s7 holds number of iterations to be performed
	li $s0,0
iter:
	mul $t5,$t3,$t3 #x^2
	mfhi $s1
	sll $s1,$s1,8
	srl $t5,$t5,24
	or $t5,$s1,$t5
	
	mul $t6,$t4,$t4 #y^2
	mfhi $s1
	sll $s1,$s1,8
	srl $t6,$t6,24
	or $t6,$s1,$t6
	
	sub $t7,$t5,$t6 #x^2-y^2
	add $t7,$t7,$t8 #Re(x2)+x0
	#t7 contains x2
	
	mul $t5,$t3,$t4 #x*y
	mfhi $s1
	sll $s1,$s1,8
	srl $t5,$t5,24
	or $t5,$s1,$t5
	sll $t5,$t5,1 #2xy = xy+xy
	add $t5,$t5,$t9 #Im(y2)+y0
	#t5 contains y2
	move $t3,$t7
	move $t4,$t5
	#t3 contains x2, t4 contains y2
	
	mul $t7,$t7,$t7
	mfhi $s1
	sll $s1,$s1,8
	srl $t7,$t7,24
	or $t7,$s1,$t7
	
	mul $t5,$t5,$t5
	mfhi $s1
	sll $s1,$s1,8
	srl $t5,$t5,24
	or $t5,$s1,$t5
	
	add $t6,$t7,$t5 #x^2+y^2
	#t6 should be compared with boundary $s2
	sub $s7,$s7,1 # --remaining iterations count
	add $s0,$s0,1

	blt $s0,2,lessThan2
	blt $s0,3,lessThan3
	blt $s0,4,lessThan4
	blt $s0,5,lessThan5
	blt $s0,10,lessThan10
	blt $s0,15,lessThan15
	blt $s0,25,lessThan25
	j more
lessThan2:
	move $k0,$t0
	li $s1,0xD1
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0x00
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x2A
	sb $s1,($k0) #FINISH coloring
	j conditions
lessThan3:
	move $k0,$t0
	li $s1,0xDE
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0x21
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x47
	sb $s1,($k0) #FINISH coloring
	j conditions
lessThan4:
	move $k0,$t0
	li $s1,0xEB
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0x3B
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x5E
	sb $s1,($k0) #FINISH coloring
	j conditions
lessThan5:
	move $k0,$t0
	li $s1,0xEB
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0xB6
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x3B
	sb $s1,($k0) #FINISH coloring
	j conditions
lessThan10:
	move $k0,$t0
	li $s1,0xD5
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0xFF
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x00
	sb $s1,($k0) #FINISH coloring
	j conditions
lessThan15:
	move $k0,$t0
	li $s1,0xEA
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0xFF
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x82
	sb $s1,($k0) #FINISH coloring
	j conditions
lessThan25:
	move $k0,$t0
	li $s1,0xEE
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0xF0
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0x89
	sb $s1,($k0) #FINISH coloring
	j conditions
more:
	move $k0,$t0
	li $s1,0xF4
	sb $s1,($k0) #START coloring
	add $k0,$k0,1
	li $s1,0xF5
	sb $s1,($k0)
	add $k0,$k0,1
	li $s1,0xC1
	sb $s1,($k0) #FINISH coloring
	
conditions:
	bge $t6,$s2,nextpix
	bgtz $s7,iter

color:
	#la $t0,obrazek
	#lw $s0,width
	#mul $s0,$s0,3 #because each pixel we travel through has 3 colors on 3 bytes
	#lw $t5,padding
	#add $t5,$s0,$t5 #add padding to each line
	#mul $t5,$t2,$t5 #$t5 is y position = limit*counterY
	#move $s0,$t1
	#mul $s0,$s0,3
	#add $t5,$t5,$s0 #$t5 is x,y position = limit*counterY+counterX
	#add $t0,$t0,$t5
	
	move $s0,$t0
	li $s1,0x22
	sb $s1,($s0) #START coloring
	add $s0,$s0,1
	#addi $s1,$s1,0x22
	sb $s1,($s0)
	add $s0,$s0,1
	#addi $s1,$s1,0x22
	sb $s1,($s0) #FINISH coloring
nextpix:
	lw $s0,width
	bge $t1,$s0,nextrow #when program reaches last pixel in a row
	add $t0,$t0,3
	add $t1,$t1,1
	j loop
nextrow:
	lw $s0,height
	bge $t2,$s0,save #when program reaches last row
	lw $t5,padding
	add $t0,$t0,$t5
	add $t2,$t2,1
	li $t1,0
	j loop

save:	
	li $v0,13
	la $a0,out
	li $a1,1 #open file for writing
	li $a2,0
	syscall
	move $t0,$v0 #moving file descriptor to $t0
	
	
	move $a0,$t0
	la $a1,header
	li $a2,54
	li $v0,15 #write header to file
	syscall
	
	move $a0,$t0
	la $a1,obrazek
	lw $a2,pixelAreaSize
	li $v0,15 #write obrazek to file
	syscall
	
	li $v0,16
	move $a0,$t0
	syscall #close file for writing
	
	li $v0, 4 # display file closed prompt
	la $a0, closePrompt
	syscall
	
	li $v0,10
	syscall

fileError:
	li $v0, 4 # display file opened prompt
	la $a0, fileErrorPrompt
	syscall

	li $v0,10
	syscall
