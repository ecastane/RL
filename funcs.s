	.globl _Z5counti
_Z5counti:	
	mov	r1, #0
1:
	add	r1, #1
	subs	r0, #1
	bne	1b
	bx	lr
	

	.globl _Z9countDowni
_Z9countDowni:
1:
	subs	r0, #1
	bne	1b
	bx	lr



	.globl _Z3sumii
_Z3sumii:
	mov	r2, #0
	sub	r1, r0
1:
	add	r2, r0
	add	r0, #1
	subs	r1, #1
	bge 	1b
	mov	r0, r2
	bx	lr



	.globl _Z4facti
_Z4facti:
	mov	r1, #1
	cmp	r0, #0
	moveq	r0, #1
	beq	2f
1:
	mul	r1, r0
	subs	r0, #1	
	bne	1b
	mov	r0, r1
2:
	bx 	lr
	



	

