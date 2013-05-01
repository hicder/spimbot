.data
##########################  LIST 2  ########################## 
L22a0: .byte 0x5, 0x9, 0xe, 0xd
L22c0: .byte 0xa, 0x3, 0x6, 0x9
L22e0: .byte 0xd, 0x6, 0xf, 0xe
L2300: .byte 0x1, 0xc, 0xe, 0xd
L2320: .byte 0xf, 0x3, 0x1, 0xc
L2340: .byte 0x4, 0xa, 0xd, 0x1
L2360: .byte 0xd, 0x1, 0xf, 0xe
L2380: .byte 0x4, 0xf, 0xd, 0x5
L2250: .word L22a0, L22c0, L22e0, L2300, L2320, L2340, L2360, L2380
list2: .word 8, L2250


#################### BLANK/EMPTY MATRIX 2 #################### 
B21b0: .byte 0x0, 0x0, 0x0, 0x0
B21d0: .byte 0x0, 0x0, 0x0, 0x0
B21f0: .byte 0x0, 0x0, 0x0, 0x0
B2210: .byte 0x0, 0x0, 0x0, 0x0
B2180: .word B21b0, B21d0, B21f0, B2210
blank2: .word 4, B2180
.kdata
.globl privateapplex
privateapplex: .word 0
.globl privateappley
privateappley: .word 0
.globl privateappleloaded
privateappleloaded: .word 0
.globl numprivate
numprivate: .word 0

.text				#code segment
# spimbot constants
TIMER = 0xffff001c
ORIENTATION = 0xffff0040
PRINT_INT = 0xffff0080
ANGLE = 0xffff0014
ANGLE_CONTROL = 0xffff0018
HEAD_X = 0xffff0020
HEAD_Y = 0xffff0024
BONK_ACKNOWLEDGE = 0xffff0060
TIMER_ACKNOWLEDGE = 0xffff006c
APPLE_X = 0xffff0070
APPLE_Y = 0xffff0074
REQUEST_PUZZLE = 0xffff0090
SUBMIT_PUZZLE = 0xffff0094
PRIVATE_APPLE_X	= 0xffff00b0
PRIVATE_APPLE_Y	= 0xffff00b4	
APPLE_EATEN_X = 0xffff00b8	
APPLE_EATEN_Y = 0xffff00bc
PIVOT_NODES_X = 0xffff00c0
PIVOT_NODES_Y = 0xffff00c4	
.globl main
main:                                  	# ENABLE INTERRUPTS
	li  	$t4, 0x8000                	# timer interrupt enable bit
	or  	$t4, $t4, 0x1000           	# bonk interrupt bit
	or		$t4, $t4, 0x2000			# private apple created bit
	or		$t4, $t4, 0x4000			# apple eaten interrupt
	or		$t4, $t4, 1                	# global interrupt enable
	mtc0   	$t4, $12                   	# set interrupt mask (Status register)
     
                                       	# REQUEST TIMER INTERRUPT
	lw		$v0, TIMER($0)             	# read current time
	add 	$v0, $v0, 5000				# add 50 to current time
	sw  	$v0, TIMER($0)             	# request timer interrupt in 50 cycles

	la		$t4, privateapplex
	la		$t5, privateappley
	lw		$t0, APPLE_X($0)
	lw		$t1, APPLE_Y($0)
	sw		$t0, 0($t4)
	sw		$t1, 0($t5)

	la		$t4, privateappleloaded
	li		$t0, 0
	sw		$t0, 0($t4)
	la		$t4, numprivate
	sw		$t0, 0($t4)
infinite:
	jal		get_more_private_apple
	j		infinite

##############private apple###################
#.globl get_more_private_apple
get_more_private_apple:
	la 		$t0, list2
	sw 		$t0, REQUEST_PUZZLE($0)
	sub		$sp, $sp, 4
	sw 		$ra, 0($sp)
	la  	$a0, blank2
	la  	$a1, list2
	li  	$a2, 0
	li  	$a3, 0

	jal		solve
	
	la		$t1, blank2
	sw		$t1, SUBMIT_PUZZLE($0)
	lw		$ra, 0($sp)
	add		$sp, $sp, 4
	jr		$ra
###############################################
############# p1 ###########
#.globl matrix_column_matches_list_row
matrix_column_matches_list_row:
    li      $t0, 0          # $t0 = k = 0

mcmlr_loop_cond:
    lw      $t1, 0($a0)     # $t1 = matrix->size
    bge     $t0, $t1, mcmlr_loop_end

mcmlr_loop:
    lw      $t2, 4($a0)     # $t2 = matrix->data
    mul     $t3, $t0, 4     # $t3 = 4 * k
    add     $t2, $t2, $t3   # $t2 = &matrix->data[k]
    lw      $t2, 0($t2)     # $t2 = matrix->data[k]
    add     $t2, $t2, $a1   # $t2 = &matrix->data[k][col]
    lb      $t2, 0($t2)     # $t2 = matrix->data[k][col]

    lw      $t3, 4($a2)     # $t3 = list->data
    mul     $t4, $a3, 4     # $t4 = 4 * row
    add     $t3, $t3, $t4   # $t3 = &list->data[row]
    lw      $t3, 0($t3)     # $t3 = list->data[row]
    add     $t3, $t3, $t0   # $t3 = &list->data[row][k]
    lb      $t3, 0($t3)     # $t3 = list->data[row][k]

    beq     $t2, $t3, mcmlr_if_end

    li      $v0, 0          # return 0
    j       mcmlr_return

mcmlr_if_end:
    add     $t0, $t0, 1     # ++ k
    j       mcmlr_loop_cond

mcmlr_loop_end:
    li      $v0, 1          # return 1

mcmlr_return:
    jr      $ra

#############p2#################
#.globl any_matrix_column_matches_list_row
any_matrix_column_matches_list_row:
    sub     $sp, $sp, 24
    sw      $ra, 0($sp)
    sw      $a0, 4($sp)
    sw      $a1, 8($sp)
    sw      $a2, 12($sp)
    sw      $s0, 16($sp)
    sw      $s1, 20($sp)

    li      $s0, 0          # $s0 = col = 0

amcmlr_loop_cond:
    lw      $a0, 4($sp)     # $a0 = matrix
    lw      $s1, 0($a0)     # $s1 = matrix->size
    bge     $s0, $s1, amcmlr_loop_end

amcmlr_loop:
    move    $a1, $s0        # $a1 = col
    lw      $a2, 8($sp)     # $a2 = list
    lw      $a3, 12($sp)    # $a3 = row

    jal     matrix_column_matches_list_row  # matrix_column_matches_list_row(matrix, col, list, row)

    beq     $v0, 0, amcmlr_if_end

    li      $v0, 1          # return 1
    j       amcmlr_return

amcmlr_if_end:
    add     $s0, $s0, 1     # ++ col
    j       amcmlr_loop_cond

amcmlr_loop_end:
    li      $v0, 0          # return 0

amcmlr_return:
    lw      $ra, 0($sp)
    lw      $s0, 16($sp)
    lw      $s1, 20($sp)
    add     $sp, $sp, 24

    jr      $ra

##################p3#####################
#.globl check_remaining_columns
check_remaining_columns:
    sub     $sp, $sp, 28
    sw      $ra, 0($sp)
    sw      $a0, 4($sp)		# save 1st two arguments
    sw      $a1, 8($sp)

    sw      $s0, 12($sp)	# save some callee-saved registers
    sw      $s1, 16($sp)
    sw      $s2, 20($sp)
    sw      $s3, 24($sp)

    li      $s0, 0          # $s0 = i = 0
    lw      $s1, 0($a1)     # $s1 = list->size
    li      $s2, 1          # $s2 = 1
    move    $s3, $a2	    # $s3 = bitmask

crc_loop:
    bge     $s0, $s1, crc_loop_end

    sll     $t0, $s2, $s0   # $t0 = 1L << i
    and     $t0, $t0, $s3   # $t0 = (1L << i) & bitmask
    bne     $t0, 0, crc_continue			

    lw      $a0, 4($sp)     # $a0 = matrix
    lw      $a1, 8($sp)     # $a1 = list
    move    $a2, $s0        # $a2 = i
    jal     any_matrix_column_matches_list_row
    beq     $v0, 0, crc_return	# if call returns zero, we return zero ($v0 is already 0)

crc_continue:
    add     $s0, $s0, 1      # ++ i
    j       crc_loop

crc_loop_end:
    li  $v0, 1              # return 1

crc_return:
    lw      $ra, 0($sp)
    lw      $s0, 12($sp)	# save some callee-saved registers
    lw      $s1, 16($sp)
    lw      $s2, 20($sp)
    lw      $s3, 24($sp)
    add     $sp, $sp, 28
    jr      $ra

####################p4#####################
#.globl solve
solve:
    sub     $sp, $sp, 28
    sw      $ra, 0($sp)	    # save return address

    lw      $t0, 0($a0)     # matrix->size
    bne     $a2, $t0, solve_recurse

    move    $a2, $a3        # pass args (matrix, list, bitmask)
    jal     check_remaining_columns      # return value in $v0

    lw      $ra, 0($sp)
    add     $sp, $sp, 28
    jr      $ra

solve_recurse:
    sw      $s0, 4($sp)     # save a bunch of $s registers
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)
    sw      $s4, 20($sp)    
    sw      $s5, 24($sp)

    move    $s0, $a0       # copy arguments to $s registers
    move    $s1, $a1
    move    $s2, $a2
    move    $s3, $a3

    li      $s4, 0          # $s4 = i = 0

solve_loop:
    lw      $t0, 0($s1)     # $t0 = list->size
    bge     $s4, $t0, solve_return0

    li      $t0, 1          # 1
    sll     $t0, $t0, $s4   # $t0 = (1 << i)
    and     $t1, $t0, $s3   # $t1 = (1L << i) & bitmask
    bne     $t1, 0, solve_continue

    li      $s5, 0          # $s4 = j = 0

solve_inner_loop:
    lw      $t2, 0($s0)     # $t2 = matrix->size
    bge     $s5, $t2, solve_inner_done

    lw      $t3, 4($s0)     # $t3 = matrix->data
    mul     $t4, $s2, 4     # $t4 = 4 * depth
    add     $t4, $t3, $t4   # $t4 = &matrix->data[depth]
    lw      $t4, 0($t4)     # $t4 = matrix->data[depth]
    add     $t4, $t4, $s5   # $t4 = &matrix->data[depth][j]

    lw      $t5, 4($s1)     # $t5 = list->data
    mul     $t6, $s4, 4     # $t6 = 4 * i
    add     $t6, $t5, $t6   # $t6 = &list->data[i]
    lw      $t6, 0($t6)     # $t6 = list->data[i]
    add     $t6, $t6, $s5   # $t6 = &list->data[i][j]
    lb      $t6, 0($t6)     # $t6 = list->data[i][j]

    sb      $t6, 0($t4)     # matrix->data[depth][j] = list->data[i][j]

    add     $s5, $s5, 1     # ++ j
    j       solve_inner_loop

solve_inner_done:
    move    $a0, $s0
    move    $a1, $s1
    add     $a2, $s2, 1     # $a2 = depth + 1
    or      $a3, $s3, $t0   # $a3 = (1L << i) | bitmask
    jal     solve           # new_solve(matrix, list, depth + 1, (1L << i) | bitmask)

    beq     $v0, 0, solve_continue

    li      $v0, 1          # return 1
    j       solve_done

solve_continue:
    add     $s4, $s4, 1     # ++ i
    j       solve_loop

solve_return0:
    li      $v0, 0          # return 0

solve_done:
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)     # save a bunch of $s registers
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
    lw      $s4, 20($sp)    
    lw      $s5, 24($sp)
    add     $sp, $sp, 28
    jr      $ra

############################################





.kdata
.globl prev_angle

prev_angle: .word 0

# spimbot constants

.kdata                # interrupt handler data (separated just for readability)
chunkIH: .space 80      # space for the universe to exist
kstackbot: .space 1000
pivotnodesx: .space 1024
pivotnodesy: .space 1024
kstack: .word 0			#kernel stack

non_intrpt_str:   .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
move      $k1, $at               # Save $at
.set at
	la   	$k0, chunkIH
	sw   	$a0, 0($k0)              # Get some free registers
	sw   	$a1, 4($k0)              # by storing them to a global variable
	sw   	$a2, 8($k0)
	sw   	$a3, 12($k0)
	sw   	$t0, 16($k0)
	sw   	$v0, 20($k0)
	sw   	$t1, 24($k0)
	sw		$t2, 28($k0)
	sw		$t3, 36($k0)
	sw		$t4, 40($k0)
	sw		$t5, 44($k0)
	sw		$t6, 48($k0)
	sw		$t7, 52($k0)
	sw  	$sp, 56($k0)            # save stack pointer
	sw		$t8, 60($k0)
	sw		$t9, 64($k0)

	mfc0    $k0, $13                 # Get Cause register
	srl     $a0, $k0, 2
	and     $a0, $a0, 0xf            # ExcCode field
	bne     $a0, 0, non_intrpt

interrupt_dispatch:                    # Interrupt:
	mfc0    $k0, $13                 # Get Cause register, again
	beq     $k0, $zero, done         # handled all outstanding interrupts

	and     $a0, $k0, 0x1000         # is there a bonk interrupt?
	bne     $a0, 0, bonk_interrupt

	and     $a0, $k0, 0x4000         # is there a apple_eaten interrupt?
	bne     $a0, 0, apple_eaten_interrupt

	and     $a0, $k0, 0x2000         # is there a apple_eaten interrupt?
	bne     $a0, 0, apple_created_interrupt

	and     $a0, $k0, 0x8000         # is there a timer interrupt?
	bne     $a0, 0, timer_interrupt



# add dispatch for other interrupt types here.

	li      $v0, 4                   # Unhandled interrupt types

	la      $a0, unhandled_str
	syscall
	j       done



apple_created_interrupt:				#private apple has been created
	sw		$a1, 0xffff0064($0)		#acknowledge interrupt
	la 		$t0, privateappleloaded
	lw 		$t0, 0($t0)
	beq		$t0, 0, apple_next
	la		$t0, numprivate
	lw		$t1, 0($t0)
	add		$t1, $t1, 1
	sw		$t1, 0($t0)
	lw		$t0, PRIVATE_APPLE_X($0)	# $t0 is new applex
	lw 		$t1, PRIVATE_APPLE_Y($0)	# $t1 is new appley
	la 		$t2, privateapplex		# $t2 is current applex
	la 		$t3, privateappley		# $t3 is current appley
	lw 		$t4, 0($t2)
	lw 		$t5, 0($t3)
	lw 		$t6, HEAD_X($0)		# $t6 is head_x
	lw 		$t7, HEAD_Y($0)		# $t7 is head_y

	sub 	$t8, $t6, $t0
	abs 	$t8, $t8
	sub 	$t9, $t7, $t1
	abs 	$t9, $t9
	add 	$t8, $t8, $t9		# $t8 is distance b/w head and new apple

	sub 	$t6, $t6, $t4
	abs 	$t6, $t6
	sub 	$t7, $t7, $t5
	abs 	$t7, $t7
	add 	$t6, $t6, $t7		# $t6 is distance b/w head and old apple
	
	bge 	$t8, $t6, set_end
	sw 		$t0, 0($t2)
	sw 		$t1, 0($t3)

set_end:
	la		$t0, privateappleloaded
	li		$t1, 1
	sw		$t1, 0($t0)
	j		interrupt_dispatch


apple_eaten_interrupt:
	sw		$a1, 0xffff0068($0)		#acknowledge interrupt
	lw		$t0, APPLE_EATEN_X($0)
	lw		$t1, APPLE_EATEN_Y($0)
	
	la		$t2, privateapplex
	la		$t3, privateappley
	lw		$t4, 0($t2)
	lw		$t5, 0($t3)
	bne		$t0, $t4, apple_eaten_done

	bne		$t1, $t5, apple_eaten_done

	la		$t8, privateappleloaded
	lw		$t8, 0($t8)
	beq		$t8, 0, go_for_public_apple
	lw		$t4, PRIVATE_APPLE_X($0)
	lw		$t5, PRIVATE_APPLE_Y($0)
	j 		go_for_public_apple
	bne		$t4, $t0, apple_next
	beq		$t5, $t1, go_for_public_apple
	
apple_next:	
	la		$t0, privateappleloaded
	li		$t1, 1
	sw		$t1, 0($t0)
	la		$t2, privateapplex
	la		$t3, privateappley
	lw		$t4, PRIVATE_APPLE_X($0)
	lw		$t5, PRIVATE_APPLE_Y($0)
	sw		$t4, 0($t2)
	sw		$t5, 0($t3)
apple_eaten_done:
	j		interrupt_dispatch	 
go_for_public_apple:

	lw		$t4, APPLE_X($0)
	li		$t6, 1001

	lw		$t5, APPLE_Y($0)
	la		$t2, privateapplex
	la		$t3, privateappley
	sw		$t4, 0($t2)
	sw		$t5, 0($t3)
	j		apple_eaten_done


bonk_interrupt:
	sw		$a1, 0xffff0060($0)
	li		$t0, 90
	sw		$t0, ANGLE($0)
	li		$t0, 0
	sw		$t0, ANGLE_CONTROL($0)
#	li   	$t0, 2500      # and wait ~5000 cycles
#wait2:
#	add  	$t0, $t0, -1
#	bne  	$t0, $0, wait2
	j		interrupt_dispatch

timer_interrupt:
	sw		$a1, 0xffff006c($zero)   # acknowledge interrupt
	lw		$t8, TIMER($0)
	lw   	$a0, HEAD_X($0)               #a0 is my_x
	lw   	$a1, HEAD_Y($0)               #a1 my_y
	la		$a2, privateapplex
	lw		$a2, 0($a2)
	la		$a3, privateappley
	lw		$a3, 0($a3)
	beq  	$a0, $a2, else1
	bge  	$a0, $a2, else2
	move 	$v0, $0
	j    	aftercode
else2:
	li   	$v0, 180
	j    	aftercode
else1:
	bge  	$a1, $a3, else3
	li   	$v0, 90
	j    	aftercode
else3:
	li   	$v0, 270
	j    	aftercode
aftercode:
	la   	$t0, prev_angle
	lw   	$t0, 0($t0)                             #t0 holds the value of prev_angle
	sub  	$t0, $t0, $v0                      #subtract prev_angle from desired_angle
	abs  	$t0, $t0                           #take the absolute value of the difference
	bne  	$t0, 180, afterif                  #if it's not 180, go to afterif
	add  	$t1, $v0, 90
	sw   	$t1, ANGLE($0)                     #set angle = 90 + desired_angle
	li   	$t0, 1                                  #t0 = 1
	sw   	$t0, ANGLE_CONTROL($0)             #set 1 to ANGLE_CONTROL
#loop to wait 5000 cycles
	li   	$t0, 2500      # and wait ~5000 cycles
wait:
	add  	$t0, $t0, -1
	bne  	$t0, $0, wait

afterif:
#SET_ABSOLUTE_ANGLE(desired_anlged)
	sw   	$v0, ANGLE($0)
	li   	$t0, 1                                  #t0 = 1
	sw   	$t0, ANGLE_CONTROL($0)             #set 1 to ANGLE_CONTROL
#prev_angle = desired_angle
	la   	$t0, prev_angle
	sw   	$v0, 0($t0)                             #store the value of desired_angle to the address of prev_angle

#request timer
	lw   	$v0, 0xffff001c($0)                # current time
	add  	$v0, $v0, 150
	sw   	$v0, 0xffff001c($0)                # request timer in 50000
	j    	interrupt_dispatch                 # see if other interrupts are waiting


non_intrpt:                         # was some non-interrupt
	li   	$v0, 4
	la   	$a0, non_intrpt_str
	syscall                            # print out an error message

# fall through to done


done:
	la      $k0, chunkIH
	lw   	$a0, 0($k0)              # Get some free registers
	lw   	$a1, 4($k0)              # by storing them to a global variable
	lw   	$a2, 8($k0)
	lw   	$a3, 12($k0)
	lw   	$t0, 16($k0)
	lw   	$v0, 20($k0)
	lw   	$t1, 24($k0)
	lw		$t2, 28($k0)
	lw		$t3, 36($k0)
	lw		$t4, 40($k0)
	lw		$t5, 44($k0)
	lw		$t6, 48($k0)
	lw		$t7, 52($k0)
	lw  	$sp, 56($k0)            # save stack pointer
	lw		$t8, 60($k0)
	lw		$t9, 64($k0)
.set noat
	move    $at, $k1                 # Restore $at
.set at
	eret


