apple_eaten_interrupt:
	sw	$a1, 0xffff0068($0)		#acknowledge interrupt
	lw	$t0, APPLE_EATEN_X($0)
	lw	$t1, APPLE_EATEN_Y($0)
	la	$t2, privateapplex
	la	$t3, privateappley
	lw	$t4, 0($t2)
	lw	$t5, 0($t3)
	bne	$t0, $t4, apple_eaten_done
	bne	$t1, $t5, apple_eaten_done
	lw	$t4, PRIVATE_APPLE_X($0)
	lw	$t5, PRIVATE_APPLE_Y($0)
	
	bne	$t4, $t0, apple_next
	beq	$t5, $t1, go_for_public_apple
	
apple_next:	
	sw	$t4, 0($t2)
	sw	$t5, 0($t3)
apple_eaten_done:
	j	interrupt_dispatch	 
go_for_public_apple:
	lw	$t4, APPLE_X($0)
	lw	$t5, APPLE_Y($0)
	sw	$t4, 0($t2)
	sw	$t5, 0($t3)
	j	apple_eaten_done
