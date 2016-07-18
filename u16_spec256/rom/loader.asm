 		DEVICE	ZXSPECTRUM48
; -----------------------------------------------------------------[29.06.2016]
; ReVerSE-U16 Spec256 Loader
; -----------------------------------------------------------------------------
; Engineer: MVV

; Port #xx00 - bit0=0:loader on, 1:loader off; bit1=0:LDR #0000-#03FF write disable, 1:LDR #0000-#0100 write enable
; Port #xx01 - #0000-#FFFF loader exit address
; Port #xx02 - SPI data
; Port #xx03 - SPI status: bit7=1:bysy
; Port #xx04 - bit7..0=1:disable memory write for CPU7..0; 0:enable

pr_param	equ #7f00

	org #0000
startprog:
	di


;#0000-#3FFF rom82 16K
;#4000-#FFFF *.sna 48K	
;#4000-#FFFF *.gfx 384K

; -----------------------------------------------------------------------------
; Palitte
; -----------------------------------------------------------------------------
; 	ld hl,#4000
; n1	ld a,%11111110
; 	out (#04),a
; 	ld (hl),%01010101

; 	ld a,%11111101
; 	out (#04),a
; 	ld (hl),%00110011

; 	ld a,%11111011
; 	out (#04),a
; 	ld (hl),%00001111

; 	ld a,%11110111
; 	out (#04),a
; 	xor a
; 	bit 0,l
; 	jr z,n2
; 	cpl
; n2	ld (hl),a

; 	ld a,%11101111
; 	out (#04),a
; 	xor a
; 	bit 1,l
; 	jr z,n3
; 	cpl
; n3	ld (hl),a

; 	ld a,%11011111
; 	out (#04),a
; 	xor a
; 	bit 2,l
; 	jr z,n4
; 	cpl
; n4	ld (hl),a

; 	ld a,%10111111
; 	out (#04),a
; 	xor a
; 	bit 3,l
; 	jr z,n5
; 	cpl
; n5	ld (hl),a

; 	ld a,%01111111
; 	out (#04),a
; 	xor a
; 	bit 4,l
; 	jr z,n6
; 	cpl
; n6	ld (hl),a

; 	inc hl
; 	ld a,h
; 	cp #64
; 	jr c,n1

; 	xor a
; 	out (#04),a

	ld sp,#5bfe

; -----------------------------------------------------------------------------
; SPI autoloader
; -----------------------------------------------------------------------------
	call spi_start
	ld d,%00000011	; command = read
	call spi_w

	ld d,#0b	; address = #0B0000
	call spi_w
	ld d,#00
	call spi_w
	ld d,#00
	call spi_w

; load #0000-#3FFF rom82 16K		
	ld hl,#0000	; start address
spi_loader1
	call spi_r
	ld (hl),a

	inc hl
	ld a,h
	cp #40
	jr nz,spi_loader1

	ld hl,str
	call print_str

	ld a,%00000010	; LDR #0000-#03FF write enable
	out (#00),a

	ld sp,#03fe

; load #4000-#FFFF *.sna 48K
	ld hl,#4000

; Смещение Размер   Описание
; ---------------------------
; 0        1        Регистр I.
; 1        2        Регистровая пара HL'.
; 3        2        Регистровая пара DE'.
; 5        2        Регистровая пара BC'.
; 7        2        Регистровая пара AF'.
; 9        2        Регистровая пара HL.
; 11       2        Регистровая пара DE.
; 13       2        Регистровая пара BC.
; 15       2        Регистровая пара IY.
; 17       2        Регистровая пара IX.
; 19       1        Состояние прерываний. Бит 2 содержит состояние
;                   триггера IFF2, бит 1 - IFF1 (0=DI, 1=EI).
; 20       1        Регистр R.
; 21       2        Регистровая пара AF.
; 23       2        Указатель на вершину стэка (SP).
; 25       1        Режим прерываний: 0=IM0, 1=IM1, 2=IM2.
; 26       1        Цвет бордюра, 0-7.
; 27       49152    Содержимое памяти с адреса 16384 (4000h).

	call spi_r
	ld i,a			; i
	call spi_r
	ld (index1+1),a		; hl'
	call spi_r
	ld (index1+2),a
	call spi_r
	ld (index3+1),a		; de'
	call spi_r
	ld (index3+2),a
	call spi_r
	ld (index5+1),a		; bc'
	call spi_r
	ld (index5+2),a
	call spi_r
	ld (index7+1),a		; af'
	call spi_r
	ld (index7+2),a
index7	ld bc,#0000
	push bc
	pop af
	ex af,af'
	call spi_r
	ld (index9+1),a		; hl
	call spi_r
	ld (index9+2),a
	call spi_r
	ld (index11+1),a	; de
	call spi_r
	ld (index11+2),a
	call spi_r
	ld (index13+1),a	; bc
	call spi_r
	ld (index13+2),a
	call spi_r
	ld (index15+2),a	; iy
	call spi_r
	ld (index15+3),a
	call spi_r
	ld (index17+2),a	; ix
	call spi_r
	ld (index17+3),a
	call spi_r
	bit 1,a
	ld a,#f3		; di
	jr z,r0
	ld a,#fb		; ei
r0
	ld (index19),a		; iff
	call spi_r
	ld (index20+1),a	; r
	call spi_r
	ld (index21+1),a	; af
	call spi_r
	ld (index21+2),a
	call spi_r
	ld (index23+1),a	; sp
	call spi_r
	ld (index23+2),a
	call spi_r
	cp #00
	im 0
	jr z,spi_loader3
	cp #01
	im 1
	jr z,spi_loader3
	im 2	
spi_loader3
	call spi_r
	ld (index24+1),a	; border

spi_loader2
	call spi_r
	ld (hl),a
	inc hl
	ld a,h
	or l
	jr nz,spi_loader2


; load #4000-#FFFF *.gfx 384K
	ld hl,#4000
	ld ix,buffer
spi_loader5
	ld a,%00000010		; LDR #0000-#03FF write enable
	out (#00),a

	call spi_r
	ld (ix+7),a		; bit 7
	call spi_r
	ld (ix+6),a
	call spi_r
	ld (ix+5),a
	call spi_r
	ld (ix+4),a
	call spi_r
	ld (ix+3),a
	call spi_r
	ld (ix+2),a
	call spi_r
	ld (ix+1),a
	call spi_r
	ld (ix+0),a		; bit 0

	or (ix+1)
	or (ix+2)
	or (ix+3)
	or (ix+4)
	or (ix+5)
	or (ix+6)
	or (ix+7)
	jp z,spi_loader4	; #00 = Not modified byte

	ld b,#ff
	ld a,(ix+7)		; #FF = Not modified byte
	cp b
	jp z,spi_loader4
	ld a,(ix+6)
	cp b
	jp z,spi_loader4
	ld a,(ix+5)
	cp b
	jp z,spi_loader4
	ld a,(ix+4)
	cp b
	jp z,spi_loader4
	ld a,(ix+3)
	cp b
	jp z,spi_loader4
	ld a,(ix+2)
	cp b
	jp z,spi_loader4
	ld a,(ix+1)
	cp b
	jp z,spi_loader4
	ld a,(ix+0)
	cp b
	jp z,spi_loader4

	ld b,8
	ld de,buffer1
spi_loader6
	rlc (ix+0)
	rla
	rlc (ix+1)
	rla
	rlc (ix+2)
	rla
	rlc (ix+3)
	rla
	rlc (ix+4)
	rla
	rlc (ix+5)
	rla
	rlc (ix+6)
	rla
	rlc (ix+7)
	rla
	ld (de),a
	inc de
	djnz spi_loader6

	xor a			; LDR #0000-#03FF write disable
	out (#00),a

	ld a,%11111110		; cpu0
	out (#04),a
	ld a,(ix+15)
	ld (hl),a

	ld a,%11111101		; cpu1
	out (#04),a
	ld a,(ix+14)
	ld (hl),a

	ld a,%11111011		; cpu2
	out (#04),a
	ld a,(ix+13)
	ld (hl),a

	ld a,%11110111		; cpu3
	out (#04),a
	ld a,(ix+12)
	ld (hl),a

	ld a,%11101111		; cpu4
	out (#04),a
	ld a,(ix+11)
	ld (hl),a

	ld a,%11011111		; cpu5
	out (#04),a
	ld a,(ix+10)
	ld (hl),a

	ld a,%10111111		; cpu6
	out (#04),a
	ld a,(ix+9)
	ld (hl),a

	ld a,%01111111		; cpu7
	out (#04),a
	ld a,(ix+8)
	ld (hl),a

	xor a			; cpu all
	out (#04),a

spi_loader4
	ld a,l
	and %00000111
	out (#fe),a

	inc hl
	ld a,l
	or h
	jp nz,spi_loader5

	ld a,%00000001		; spi end
	out (#03),a

	xor a			; LDR #0000-#03FF write disable
	out (#00),a

;	halt


index1	ld hl,#0000
index3	ld de,#0000
index5	ld bc,#0000
	exx
index23	ld sp,#0000
	pop de
	ld b,d
;	ld a,%00000010		; LDR #0000-#03FF write enable
;	out (#00),a
;	ld (index27+1),de
;	xor a			; LDR #0000-#03FF write disable
;	out (#00),a
	ld c,#01
	out (c),e
index13	ld bc,#0000
index15	ld iy,#0000
index17	ld ix,#0000
	ld a,#01
	out (#00),a		; loader off
index20	ld a,#00
	ld r,a
index24 ld a,#00
	out (#fe),a
index21	ld hl,#0000
	push hl
	pop af
index9	ld hl,#0000
	push de
index11	ld de,#0000
index19	ei
;index27	jp #0000
	ret



; -----------------------------------------------------------------------------	
; print string i: hl - pointer to string zero-terminated
; -----------------------------------------------------------------------------	
print_str
	ld a,(hl)
	cp 23
	jr z,print_pos_xy
	or a
	ret z
	inc hl
	call print_char
	jr print_str
print_pos_xy
	inc hl
	ld a,(hl)
	ld (pr_param),a		; x-coord
	inc hl
	ld a,(hl)
	ld (pr_param+1),a	; y-coord
	inc hl
	jr print_str

; -----------------------------------------------------------------------------	
; print character i: a - ansi char
; -----------------------------------------------------------------------------	
print_char
	push hl
	push de
	push bc
	cp 13
	jr z,pchar2
	sub 32
	ld c,a			; временно сохранить в с
	ld hl,(pr_param)	; hl=yx
	;координаты -> scr adr
	;in: H - Y координата, L - X координата
	;out:hl - screen adress
	ld a,h
	and 7
	rrca
	rrca
	rrca
	or l
	ld e,a
	ld a,h
        and 24
	or 64
	ld d,a
	ld l,c			; l= символ
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,#3d00
	add hl,bc
	ld b,8
pchar3	ld a,(hl)
	ld (de),a
	inc d
	inc hl
	djnz pchar3
	ld a,(pr_param)		; x
	inc a
	cp 32
	jr c,pchar1
pchar2
	ld a,(pr_param+1)	; y
	inc a
	cp 24
	jr c,pchar0
	jr pchar00
pchar0
	ld (pr_param+1),a
pchar00
	xor a
pchar1
	ld (pr_param),a
	pop bc
	pop de
	pop hl
	ret


; -----------------------------------------------------------------------------	
; SPI Driver
; -----------------------------------------------------------------------------
; Ports:
; #02: Data Buffer (write/read)
;	bit 7-0	= Stores SPI read/write data
; #03: Command/Status Register (write)
;	bit 7-1	= Reserved
;	bit 0	= 1:END   	(Deselect device after transfer/or immediately if START = '0')
; #03: Command/Status Register (read):
; 	bit 7	= 1:BUSY	(Currently transmitting data)
;	bit 6-0	= Reserved

spi_end
	ld a,%00000001	; config = end
	out (#03),a
	ret
spi_start
	xor a
	out (#03),a
	ret
spi_w
	in a,(#03)
	rlca
	jr c,spi_w
	ld a,d
	out (#02),a
	ret
spi_r
	ld d,#ff
	call spi_w
spi_r1	
	in a,(#03)
	rlca
	jr c,spi_r1
	in a,(#02)
	ret

str	db 23,0,0,"ReVerSE-U16 DevBoard"
	db 13,13,"FPGA SoftCore - SPEC256"
	db 13,"(build 20160629) By MVV"
	db 13,13,"https://github.com/mvvproject"
	db 13,13,13,"F4: Reset, F5: NMI",13,0


buffer	db #00,#00,#00,#00,#00,#00,#00,#00
buffer1	db #00,#00,#00,#00,#00,#00,#00,#00
; -----------------------------------------------------------------------------

	display "End: ",/a, $

	savebin "loader.bin",startprog, 1024
