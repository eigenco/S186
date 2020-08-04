	times 8 nop

	mov	bx, cs
	mov	es, bx
	mov	ds, bx
	mov	ss, bx
	mov	sp, 3000

	mov	dx, 0xA000
	push	dx
	pop	es
	mov	[si], word 100
	
L:
	cwd				; DX = 0 ( AH=0 or AH=1 before)
	mov	ax, di			; make x,y from counter DI
	mov	bx, 320
	div	bx			; AX = y, DX = x
	sub	dx, [si]		; x = x - 100	; 160 in the original
	sub	ax, [si]		; y = y - 100
	js	F
	not	ax			; basically avoids 0 in AX and mirrors at 0
F:
	cpu 186
	sal	dx, 4
	cpu 8086

	xchg	bx, ax			; y -> BX, 320 -> AX
	xchg	dx, ax			; (x << 4) -> AX, 320 -> DX
	cwd				; DX = 0 (AX < 0x7fff before)
	idiv	bx			; AX = (x << 4) / y

	cpu 186
	shr	ax, 3			; AX = ((x << 4) / y) >> 3
	cpu 8086

	xchg	cx, ax			; "push AX" to CX
	cwd				; DX = 0 (AX < 0x7fff before)
	mov	ax, 256			; AX = 256
	idiv	bx			; AX = 256 / y
	add	ax, cx			; AX = ((x << 4) / y) >> 3 + ( 256 / y)
	sub	ax, bp			; AX = ((x << 4) / y) >> 3 + ( 256 / y) - frame
	aam	24			; "& 15" originally, but "aam 24" maps smoother
	add	al, 32			; map to coder colors
	stosb				; write pixel, increment pixel counter
	inc	di			; the dither trick (+double "inc DI") writes 3 * (1/3) frames
	inc	di			; until DI is 0 again (use "test DI,DI" for no dither)
	jnz	L			; next pixel
	inc	bp			; next frame

	jmp	L

	mov	bx, 0xA000
	mov	es, bx
	xor	di, di
	mov	cx, 64000
loopa:
	stosb
	inc	al
	loop	loopa

	mov	dx, 0xfffe
	mov	al, 10101010b
	out	dx, al
haltti:
	jmp	haltti

times   0xfff0-($-$$) nop

	jmp	0xf000:0               ; reset vector

times   0x10000-($-$$) db 0