	.arch armv8-a
	.file	"multiply.c"
	.text
	.align	2
	.p2align 3,,7
	.global	mult_std
	.type	mult_std, %function
mult_std:
	cmp	w3, 0
	ble	.L1
	mov	x4, 0
	.p2align 3
.L3:
	ldr	s0, [x0, x4, lsl 2]
	ldr	s1, [x1, x4, lsl 2]
	fmul	s0, s0, s1
	str	s0, [x2, x4, lsl 2]
	add	x4, x4, 1
	cmp	w3, w4
	bgt	.L3
.L1:
	ret
	.size	mult_std, .-mult_std
	.align	2
	.p2align 3,,7
	.global	mult_vect
	.type	mult_vect, %function
mult_vect:
	cmp	w3, 0
	ble	.L6
	sub	w3, w3, #1
	add	x4, x0, 16
	lsr	w3, w3, 2
	add	x3, x4, x3, uxtw 4
	.p2align 3
.L8:
	ldr	q1, [x0], 16
	ldr	q0, [x1], 16
	cmp	x0, x3
	fmul	v0.4s, v0.4s, v1.4s
	str	q0, [x2], 16
	bne	.L8
.L6:
	ret
	.size	mult_vect, .-mult_vect
	.section	.text.startup,"ax",@progbits
	.align	2
	.p2align 3,,7
	.global	main
	.type	main, %function
main:
	stp	x29, x30, [sp, -128]!
	mov	x1, 33792
	movk	x1, 0x17d7, lsl 16
	mov	x0, 16
	add	x29, sp, 0
	stp	x19, x20, [sp, 16]
	adrp	x19, :got:__stack_chk_guard
	stp	x21, x22, [sp, 32]
	ldr	x2, [x19, #:got_lo12:__stack_chk_guard]
	ldr	x3, [x2]
	str	x3, [x29, 120]
	mov	x3,0
	str	x23, [sp, 48]
	str	d8, [sp, 56]
	bl	aligned_alloc
	mov	x21, x0
	mov	x1, 33792
	mov	x0, 16
	movk	x1, 0x17d7, lsl 16
	bl	aligned_alloc
	mov	x1, 33792
	mov	x22, x0
	movk	x1, 0x17d7, lsl 16
	mov	x0, 16
	bl	aligned_alloc
	mov	x23, x0
	mov	w2, 12897
	mov	w0, 7130
	mov	w7, 1033
	mov	w6, 40193
	mov	x4, 57600
	movk	w2, 0x3e15, lsl 16
	movk	w0, 0x3dfc, lsl 16
	mov	x1, 0
	movk	w7, 0x8102, lsl 16
	fmov	s3, w2
	movk	w6, 0x317f, lsl 16
	mov	w5, 331
	fmov	s2, w0
	movk	x4, 0x5f5, lsl 16
	.p2align 3
.L11:
	smull	x2, w1, w7
	asr	w3, w1, 31
	smull	x0, w1, w6
	lsr	x2, x2, 32
	add	w2, w2, w1
	asr	x0, x0, 38
	sub	w0, w0, w3
	asr	w2, w2, 6
	sub	w2, w2, w3
	msub	w0, w0, w5, w1
	lsl	w3, w2, 7
	sub	w2, w3, w2
	sub	w2, w1, w2
	scvtf	s0, w0
	scvtf	s1, w2
	fmul	s0, s0, s2
	fmul	s1, s1, s3
	str	s0, [x22, x1, lsl 2]
	str	s1, [x21, x1, lsl 2]
	add	x1, x1, 1
	cmp	x1, x4
	bne	.L11
	add	x1, x29, 72
	mov	w0, 1
	bl	clock_gettime
	mov	x20, 0
	mov	x0, 33792
	movk	x0, 0x17d7, lsl 16
	.p2align 3
.L12:
	ldr	s0, [x21, x20]
	ldr	s1, [x22, x20]
	fmul	s0, s0, s1
	str	s0, [x23, x20]
	add	x20, x20, 4
	cmp	x20, x0
	bne	.L12
	add	x1, x29, 88
	mov	w0, 1
	bl	clock_gettime
	add	x20, x21, x20
	mov	x0, x21
	mov	x2, x22
	mov	x1, x23
	.p2align 3
.L13:
	ldr	q0, [x0], 16
	ldr	q1, [x2], 16
	cmp	x0, x20
	fmul	v0.4s, v0.4s, v1.4s
	str	q0, [x1], 16
	bne	.L13
	add	x1, x29, 104
	mov	w0, 1
	bl	clock_gettime
	ldp	x1, x3, [x29, 72]
	ldp	x5, x4, [x29, 88]
	ldp	x2, x0, [x29, 104]
	sub	x3, x4, x3
	sub	x1, x5, x1
	sub	x0, x0, x4
	adrp	x4, .LC0
	scvtf	d2, x3
	sub	x2, x2, x5
	scvtf	d8, x0
	ldr	d3, [x4, #:lo12:.LC0]
	scvtf	d1, x2
	scvtf	d0, x1
	mov	w0, 1
	adrp	x1, .LC1
	fmadd	d0, d2, d3, d0
	add	x1, x1, :lo12:.LC1
	fmadd	d8, d8, d3, d1
	bl	__printf_chk
	fmov	d0, d8
	adrp	x1, .LC2
	add	x1, x1, :lo12:.LC2
	mov	w0, 1
	bl	__printf_chk
	mov	x0, x21
	bl	free
	mov	x0, x22
	bl	free
	mov	x0, x23
	bl	free
	ldr	x19, [x19, #:got_lo12:__stack_chk_guard]
	mov	w0, 0
	ldr	x2, [x29, 120]
	ldr	x1, [x19]
	eor	x1, x2, x1
	cbnz	x1, .L19
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldr	x23, [sp, 48]
	ldr	d8, [sp, 56]
	ldp	x29, x30, [sp], 128
	ret
.L19:
	bl	__stack_chk_fail
	.size	main, .-main
	.section	.rodata.cst8,"aM",@progbits,8
	.align	3
.LC0:
	.word	3894859413
	.word	1041313291
	.section	.text.startup
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC1:
	.string	"Elapsed time std: %f\n"
	.zero	2
.LC2:
	.string	"Elapsed time vec: %f\n"
	.ident	"GCC: (Ubuntu/Linaro 7.5.0-3ubuntu1~18.04) 7.5.0"
	.section	.note.GNU-stack,"",@progbits
