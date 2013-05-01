set:

lw $t0, PRIVATE_APPLE_X($0)	# $t0 is new applex
lw $t1, PRIVATE_APPLE_Y($0)	# $t1 is new appley
la $t2, privateapplex		# $t2 is current applex
la $t3, privateapply		# $t3 is current appley
lw $t4, 0($t2)
lw $t5, 0($t3)
lw $t6, HEAD_X($0)		# $t6 is head_x
lw $t7, HEAD_Y($0)		# $t7 is head_y

sub $t8, $t6, $t0
abs $t8, $t8
sub $t9, $t7, $t1
abs $t9, $t9
add $t8, $t8, $t9		# $t8 is dis1

sub $t6, $t6, $t2
abs $t6, $t6
sub $t7, $t7, $t3
abs $t7, $t7
add $t6, $t6, $t7		# $t6 is dis2

bge $t8, $t6, set_end
sw $t0, 0($t2)
sw $t1, 0($t3)

set_end:

j interrupt_dispatch
