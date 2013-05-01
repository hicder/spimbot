# spimbot constants
TIMER = 0xffff001c

.globl main
main:                                  # ENABLE INTERRUPTS
     li     $t4, 0x8000                # timer interrupt enable bit
     or     $t4, $t4, 0x1000           # bonk interrupt bit
     or     $t4, $t4, 1                # global interrupt enable
     mtc0   $t4, $12                   # set interrupt mask (Status register)
     
                                       # REQUEST TIMER INTERRUPT
     lw     $v0, TIMER($0)             # read current time
     add    $v0, $v0, 50               # add 50 to current time
     sw     $v0, TIMER($0)             # request timer interrupt in 50 cycles

infinite: 
     j      infinite
     nop


.kdata
.globl prev_angle
prev_angle: .word 0

# spimbot constants
ANGLE = 0xffff0014
ANGLE_CONTROL = 0xffff0018
#TIMER = 0xffff001c
HEAD_X = 0xffff0020
HEAD_Y = 0xffff0024
BONK_ACKNOWLEDGE = 0xffff0060
TIMER_ACKNOWLEDGE = 0xffff006c
APPLE_X = 0xffff0070
APPLE_Y = 0xffff0074
PIVOT_NODES_X = 0xffff00c0
PIVOT_NODES_Y = 0xffff00c4
OTHER_PIVOT_NODES_X = 0xffff00c8
OTHER_PIVOT_NODES_Y = 0xffff00cc 

.kdata                # interrupt handler data (separated just for readability)
chunkIH:.space 1056      # space for eight registers
non_intrpt_str:   .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
piv_nodes_x:	.size 256
piv_nodes_y:	.size 256
other_piv_nodex_x:	.size 256
other_piv_nodes_y:	.size 256

.ktext 0x80000180
interrupt_handler:
.set noat
move      $k1, $at               # Save $at
.set at
la   $k0, chunkIH
sw   $a0, 0($k0)              # Get some free registers
sw   $a1, 4($k0)              # by storing them to a global variable
sw   $a2, 8($k0)
sw   $a3, 12($k0)
sw   $t0, 16($k0)
sw   $v0, 20($k0)
sw   $t1, 24($k0)

mfc0    $k0, $13                 # Get Cause register
srl     $a0, $k0, 2
and     $a0, $a0, 0xf            # ExcCode field
bne     $a0, 0, non_intrpt

interrupt_dispatch:                    # Interrupt:
mfc0    $k0, $13                 # Get Cause register, again
beq     $k0, $zero, done         # handled all outstanding interrupts

and     $a0, $k0, 0x1000         # is there a bonk interrupt?
bne     $a0, 0, bonk_interrupt

and     $a0, $k0, 0x8000         # is there a timer interrupt?
bne     $a0, 0, timer_interrupt

# add dispatch for other interrupt types here.

li      $v0, 4                   # Unhandled interrupt types

la      $a0, unhandled_str
syscall
j       done

bonk_interrupt:
sw      $a1, 0xffff0060($zero)   # acknowledge interrupt

sw	piv_nodes_x, PIVOT_NODES_X($0)
sw	piv_nodes_y, PIVOT_NODES_Y($0)
sw	other_piv_nodes_x, OTHER_PIVOT_NODES_X($0)
sw	other_piv_nodes_x, OTHER_PIVOT_NODES_X($0)

#Code for bonk with self
#if(piv_nodes_x[0] == piv_nodes_x[1])
#{
#	if(piv_nodes_y[0] < piv_nodes_y[1])	//first turn above 2nd
#		turn down
#	else
#		turn up
#}
#else if(piv_nodes_y[0] == piv_nodes_y[1])
#{
#	if(piv_nodes_x[0] < piv_nodes_x[1])
#		turn left
#	else
#		turn right
#}
lw	$t0, 0(piv_nodes_x)
lw	$t1, 4(piv_nodes_x)
bne	$t0, $t1, yequal
lw	$t0, 0(piv_nodes_y)
lw	$t1, 4(piv_nodes_y)
bge	$t0, $t1, elsex

li	$t0, 270
sw	$t0, ANGLE($0)
li	$t0, 1
sw	$t0, ANGLE_CONTROL($0)
j 	done

elsex:

li	$t0, 90
sw	$t0, ANGLE($0)
li	$t0, 1
sw	$t0, ANGLE_CONTROL($0)
j 	done

yequal:
lw	$t0, 0(piv_nodes_y)
lw	$t1, 4(piv_nodes_y)
bne	$t0, $t1, done
lw	$t0, 0(piv_nodes_x)
lw	$t1, 4(piv_nodes_x)
bge	$t0, $t1, elsey

li	$t0, 180
sw	$t0, ANGLE($0)
li	$t0, 1
sw	$t0, ANGLE_CONTROL($0)
j 	done

elsey:

li	$t0, 0
sw	$t0, ANGLE($0)
li	$t0, 1
sw	$t0, ANGLE_CONTROL($0)

done:
j       interrupt_dispatch       # see if other interrupts are waiting

timer_interrupt:
sw      $a1, 0xffff006c($zero)   # acknowledge interrupt
#load my_x, my_y, apple_x, apple_y
lw   $a0, HEAD_X($0)               #a0 is my_x
lw   $a1, HEAD_Y($0)               #a1 my_y
lw   $a2, APPLE_X($0)              #a2 apple_x
lw   $a3, APPLE_Y($0)              #a3 apple_y
#also, t0 is desired angle
#do the code
beq  $a0, $a2, else1
bge  $a0, $a2, else2
move $v0, $0
j    aftercode
else2:
li   $v0, 180
j    aftercode
else1:
bge  $a1, $a3, else3
li   $v0, 90
j    aftercode
else3:
li   $v0, 270
j    aftercode

aftercode:
la   $t0, prev_angle
lw   $t0, 0($t0)                             #t0 holds the value of prev_angle
sub  $t0, $t0, $v0                      #subtract prev_angle from desired_angle
abs  $t0, $t0                           #take the absolute value of the difference
bne  $t0, 180, afterif                  #if it's not 180, go to afterif
add  $t1, $v0, 90
sw   $t1, ANGLE($0)                     #set angle = 90 + desired_angle
li   $t0, 1                                  #t0 = 1
sw   $t0, ANGLE_CONTROL($0)             #set 1 to ANGLE_CONTROL
#loop to wait 5000 cycles
li   $t0, 2500      # and wait ~5000 cycles
wait:
add  $t0, $t0, -1
bne  $t0, $0, wait

afterif:
#SET_ABSOLUTE_ANGLE(desired_anlged)
sw   $v0, ANGLE($0)
li   $t0, 1                                  #t0 = 1
sw   $t0, ANGLE_CONTROL($0)             #set 1 to ANGLE_CONTROL
#prev_angle = desired_angle
la   $t0, prev_angle
sw   $v0, 0($t0)                             #store the value of desired_angle to the address of prev_angle

#request timer
lw   $v0, 0xffff001c($0)                # current time
add  $v0, $v0, 500
sw   $v0, 0xffff001c($0)                # request timer in 50000
j    interrupt_dispatch                 # see if other interrupts are waiting

non_intrpt:                         # was some non-interrupt
li   $v0, 4
la   $a0, non_intrpt_str
syscall                            # print out an error message

# fall through to done

done:
la      $k0, chunkIH
lw      $a0, 0($k0)                # Restore saved registers
lw      $a1, 4($k0)
lw   $a2, 8($k0)
lw   $a3, 12($k0)
lw   $t0, 16($k0)
lw   $v0, 20($k0)
lw   $t1, 24($k0)
.set noat
move    $at, $k1                 # Restore $at
.set at
eret
