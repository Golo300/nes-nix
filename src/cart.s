.segment "HEADER"
	.byte "NES"		;identification string
	.byte $1A
	.byte $02		;amount of PRG ROM in 16K units
	.byte $01		;amount of CHR ROM in 8K units
	.byte $00		;mapper and mirroing
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00
.segment "ZEROPAGE"
XPOS:	.RES 1	;reserves 1 byte of memory for a variable named VAR
XVEL:	.RES 1
buttons: .RES 2
.segment "STARTUP"

RESET:
	SEI 		;disables interupts
	CLD			;turn off decimal mode
	
	LDX #%1000000	;disable sound IRQ
	STX $4017
	LDX #$00
	STX $4010		;disable PCM
	
	;initialize the stack register
	LDX #$FF
	TXS 		;transfer x to the stack
	
	; Clear PPU registers
	LDX #$00
	STX $2000
	STX $2001
	
	;WAIT FOR VBLANK
:
	BIT $2002
	BPL :-
	
	;CLEARING 2K MEMORY
	TXA
CLEARMEMORY:		;$0000 - $07FF
	STA $0000, X
	STA $0100, X
	STA $0300, X
	STA $0400, X
	STA $0500, X
	STA $0600, X
	STA $0700, X
		LDA #$FF
		STA $0200, X
		LDA #$00
	INX
	CPX #$00
	BNE CLEARMEMORY

	;WAIT FOR VBLANK
:
	BIT $2002
	BPL :-
	
	;SETTING SPRITE RANGE
	LDA #$02
	STA $4014
	NOP
	
	LDA #$3F	;$3F00
	STA $2006
	LDA #$00
	STA $2006
	
	LDX #$00
LOADPALETTES:
	LDA PALETTEDATA, X
	STA $2007
	INX
	CPX #$20
	BNE LOADPALETTES

;LOADING SPRITES
	LDX #$00
	LDA #$80
	STA XPOS

LOADSPRITES:
	LDA SPRITEDATA, X
	STA $0200, X
	INX
	CPX #$40	;16bytes (4 bytes per sprite, 8 sprites total)
	BNE LOADSPRITES

;ENABLE INTERUPTS
	CLI	

	LDA #%10010000
	STA $2000			;WHEN VBLANK OCCURS CALL NMI

	LDA #%00011110		;show sprites and background
	STA $2001
	
	INFLOOP:
		JMP INFLOOP

JOYPAD1 = $4016
BUTTON_A      = 1 << 7
BUTTON_B      = 1 << 6
BUTTON_SELECT = 1 << 5
BUTTON_START  = 1 << 4
BUTTON_UP     = 1 << 3
BUTTON_DOWN   = 1 << 2
BUTTON_LEFT   = 1 << 1
BUTTON_RIGHT  = 1 << 0

CHRADDR = $0203

NMI:


	LDA #$02	;LOAD SPRITE RANGE
	STA $4014

	JSR readjoy

	LDX #$00
	DEX
	STX XVEL


 	lda buttons
    and #BUTTON_RIGHT
    beq notRight

		LDX #$00
		STX XVEL
		JMP endInput

	notRight:

	lda buttons
	and #BUTTON_LEFT
    beq notLeft
		
		LDX #$00
		DEX
		DEX
		STX XVEL
		JMP endInput

	notLeft:
	
	endInput:

	JSR MOVE

	RTI

MOVE:

	LDA XVEL     
	SEC          ; Setze das Carry Flag für die Subtraktion
	LDA XVEL     ; Lade den Wert von XVEL

	ADC XPOS     ; Subtrahiere XPOS von XVEL
	STA XPOS     ; Speichere das Ergebnis zurück in XPOS

	LDX #$00
	LDY #$00

UPDATESPRITES:
	
	STA CHRADDR, X
	INX
	INX
	INX
	INX
	
	ADC #$08 ; posion of next sprite is far right
	
	PHA

	TXA           ; Übertrage den Inhalt des Akkumulator-Registers ins X-Register

	AND #$0F      ; Führe eine logische UND-Operation mit 0x0F (15 in Dezimal) durch
    BNE NOT_NEXT_ROW    ; Wenn X nicht gleich 16 ist, springe zu NOT_FOURTH

	PLA
    SEC               ; Setze das Carry-Flag für die Subtraktion
    SBC #$20          ; Subtrahiere 0x20 vom Akkumulatorwert
	PHA

	NOT_NEXT_ROW:
	
	PLA

	CPX #$40	;16bytes (4 bytes per sprite, 8 sprites total)
	
	BNE UPDATESPRITES
	
	RTS             ; Return from subroutine

; At the same time that we strobe bit 0, we initialize the ring counter
; so we're hitting two birds with one stone here
readjoy:
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta JOYPAD1
    sta buttons
    lsr a        ; now A is 0
    ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
    sta JOYPAD1
loop:
    lda JOYPAD1
    lsr a        ; bit 0 -> Carry
    rol buttons  ; Carry -> bit 0; bit 7 -> Carry
    bcc loop
    rts

PALETTEDATA:
	.byte $00, $0F, $00, $10, 	$00, $0A, $15, $01, 	$00, $29, $28, $27, 	$00, $34, $24, $14 	;background palettes
	.byte $01, $17, $12, $37, 	$00, $0F, $11, $30, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	;sprite palettes

SPRITEDATA:
;Y, SPRITE NUM, attributes, X
;76543210
;||||||||
;||||||++- Palette (4 to 7) of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically

	; wizzard
	.byte $60, $88, $00, $80
	.byte $60, $89, $00, $88
	.byte $60, $8a, $00, $90
	.byte $60, $8b, $00, $98

	.byte $68, $98, $00, $80
	.byte $68, $99, $00, $88
	.byte $68, $9a, $00, $90
	.byte $68, $9b, $00, $98

	.byte $70, $a8, $00, $80
	.byte $70, $a9, $00, $88
	.byte $70, $aa, $00, $90
	.byte $70, $ab, $00, $98

	.byte $78, $b8, $00, $80
	.byte $78, $b9, $00, $88
	.byte $78, $ba, $00, $90
	.byte $78, $bb, $00, $98

.segment "VECTORS"
	.word NMI
	.word RESET
	; specialized hardware interurpts
.segment "CHARS"
	.incbin "rom.chr"
