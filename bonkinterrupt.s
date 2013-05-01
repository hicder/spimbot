bonk_interrupt:
	sw		$a1, 0xffff0060($0)
	lw		$t0, ORIENTATION($0)
	add		$t0, $t0, 90
	sw		$t0, ANGLE($0)
	li		$t0, 1
	sw		$t0, ANGLE_CONTROL($0)
	j		interrupt_dispatch
