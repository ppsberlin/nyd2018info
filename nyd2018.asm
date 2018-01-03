/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/

	icl "nyd2018.h"

	org $f0

fcnt	.ds 2
fadr	.ds 2
fhlp	.ds 2
cloc	.ds 1
regA	.ds 1
regX	.ds 1
regY	.ds 1
merke	dta a(infotxt)
tmer	dta 0
tmer2	dta 0

WIDTH	= 40
HEIGHT	= 30

; ---	BASIC switch OFF
	org $2000\ mva #$ff portb\ rts\ ini $2000
* ---
; Loader

	org $600

antload
:10	dta $70
	dta $47
	dta a(loadtxt)
	dta 2,$70,70
:9	dta $70
	dta $47
	dta a(bb)
	dta $41,a(antload)

loader

	mwa #antload 560
	rts

loadtxt
	dta d'    nyd 2018 INFO    '
	dta d'      some texts and infos for you      '
bb	dta d'          ...loading'
	
	ini loader
* ---

; ---	MAIN PROGRAM
	org $2000
ant	dta $44,a(scr)
	dta $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$84,$84
	dta $04,$04,$04,$04,$04,$84,$04,$04,$04,$04,$04,$04,$04
	dta $41,a(ant)

scr	ins "nyd2018.scr"

	.ALIGN $0400
fnt	ins "nyd2018.fnt"

	ift USESPRITES
	.ALIGN $0800
pmg	.ds $0300
	ift FADECHR = 0
	SPRITES
	els
	.ds $500
	eif
	eif

main
	adw merke #$410 merke

; ---	init PMG

	ift USESPRITES
	mva >pmg pmbase		;missiles and players data address
	mva #$03 pmcntl		;enable players and missiles
	eif

	ift CHANGES		;if label CHANGES defined
	jsr save_color		;then save all colors and set value 0 for all colors
	eif

	lda:cmp:req $14		;wait 1 frame

	sei			;stop IRQ interrupts
	mva #$00 nmien		;stop NMI interrupts
	sta dmactl
	mva #$fe portb		;switch off ROM to get 16k more ram

	mwa #NMI $fffa		;new NMI handler

	mva #$c0 nmien		;switch on NMI+DLI again

	ift CHANGES		;if label CHANGES defined

	jsr fade_in		;fade in colors

_lp
	jmp _lp

	els

null	jmp DLI.dli1		;CPU is busy here, so no more routines allowed

	eif


stop
	jsr fade_out		;fade out colors

	mva #$00 pmcntl		;PMG disabled
	tax
	sta:rne hposp0,x+

	mva #$ff portb		;ROM switch on
	mva #$40 nmien		;only NMI interrupts, DLI disabled
	cli			;IRQ enabled

	mwa #ant_bs2 560
	lda #0
	sta 710
	lda #12
	sta 709
;---------------------------------------------------------------------
lp_
	lda $278		; Stick0
	cmp #13
	beq runter
	cmp #14
	beq rauf
	lda $279		; Stick1
	cmp #13
	beq runter
	cmp #14
	beq rauf
	
	lda trig0		; FIRE #0
	beq zuende

	lda trig1		; FIRE #1
	beq zuende

	lda consol		; START
	and #1
	beq zuende
	lda consol
	and #%00000010		; SELECT?
	beq runter
	lda consol
	and #%00000100		; OPTION?
	beq rauf
	
	lda skctl
	and #$04		; any key?
	beq zuende
	
	lda skctl
	and #$08		; SHIFT key?
	beq zuende
	
	jmp lp_

zuende
	jmp $e477


runter
	cpw merke #endtxt
	beq nichts_ru
	adw merke #40 merke
	adw sctxt #40 sctxt
nichts_ru
	lda:cmp:req $14		;wait 1 frame
	jmp lp_

rrauf	mva #$ff 764

rauf
	cpw sctxt #infotxt
	beq nichts_ra
	sbw sctxt #40 sctxt
	sbw merke #40 merke
nichts_ra
	lda:cmp:req $14		;wait 1 frame
	jmp lp_
	

; ---	DLI PROGRAM

.local	DLI

	?old_dli = *

	ift !CHANGES

dli1	
	lda vcount
	cmp #$02
	bne dli1

	:3 sta wsync

	DLINEW dli6
	eif


dli_start

dli6
	sta regA
	stx regX
	sty regY

	sta wsync		;line=128
	sta wsync		;line=129
	sta wsync		;line=130
	sta wsync		;line=131
	sta wsync		;line=132
c5	lda #$F8
c6	ldx #$F4
c7	ldy #$FA
	sta wsync		;line=133
	sta color0
	stx color1
	sty color2
	DLINEW DLI.dli2 1 1 1
	
dli2
	sta regA
	lda >fnt+$400*$01
	sta wsync		;line=136
	sta chbase

	DLINEW dli3 1 0 0

dli3
	sta regA
	lda >fnt+$400*$00
	sta wsync		;line=184
	sta chbase

	lda regA
	rti

.endl

; ---

CHANGES = 1
FADECHR	= 0

; ---

.proc	NMI

	bit nmist
	bpl VBL

	jmp DLI.dli_start
dliv	equ *-2

VBL
	sta regA
	stx regX
	sty regY

	sta nmist		;reset NMI flag

	mwa #ant dlptr		;ANTIC address program

	mva #scr40 dmactl	;set new screen width

	inc cloc		;little timer

; Initial values

	lda >fnt+$400*$00
	sta chbase
c0	lda #$00
	sta colbak
c1	lda #$04
	sta color0
c2	lda #$0E
	sta color1
c3	lda #$08
	sta color2
c4	lda #$00
	sta color3
	lda #$02
	sta chrctl
	lda #$04
	sta gtictl
x0	lda #$00
	sta hposp0
	sta hposp1
	sta hposp2
	sta hposp3
	sta hposm0
	sta hposm1
	sta hposm2
	sta hposm3
	sta sizep0
	sta sizep1
	sta sizep2
	sta sizep3
	sta sizem
	sta colpm0
	sta colpm1
	sta colpm2
	sta colpm3

	mwa #DLI.dli_start dliv	;set the first address of DLI interrupt

;this area is for yours routines

//--------------------
//   Timer
//--------------------
	lda tmer
	cmp #50
	bne go_further
	mva #0 tmer
	inc tmer2
	lda tmer2
	cmp #5
	bne go_further
	jmp stop

go_further
	inc tmer
//--------------------

quit
	lda regA
	ldx regX
	ldy regY
	rti

.endp

; ---
	ift CHANGES
		ift FADECHR = 0
		icl 'nyd2018.fad'
		eif
	eif
;---------------------------------------------------------------------------------
	.align $0100
ant_bs2
	dta $70
	dta $46
aa	dta a(infotop)
	dta $42
sctxt	dta a(infotxt)
:25	dta 2
	dta $46
	dta a(infoend)
	dta $41,a(ant_bs2)
;---------------------------------------------------------------------------------
infotop
	dta d'      NYD 2018      '
infoend
	dta d'   happy new year   '*
	.align $1000
infotxt
	dta d'Here are some infos by the authors of   '
	dta d'some entries. Use joystick or SELECT and'
	dta d'OPTION to scroll. Trigger, START or key '
	dta d'to reset ATARI. Logo and code of this by'
	dta d'-------------------------------------',d'PPs'*
	dta d'Shamus+ - New Mazes for Shamus V1.0slx'*,d'  '
	dta d'2017 Shamus+ is a patch of Shamus       '
	dta d'allowing to play the extra mazes from   '
	dta d'the C64 version. It includes a          '
	dta d'"Tournament" mode playing all mazes in  '
	dta d'succession and a pause function. A rare '
	dta d'bug affecting advanced players only is  '
	dta d'rectified.                              '
	dta d'Instructions:'*,d' Use [OPTION] to select the'
	dta d'starting Maze. "Tournament" will play   '
	dta d'through all mazes in sequence (except   '
	dta d'the Original C64 which is almost        '
	dta d'identical to the original Atari maze).  '
	dta d'When you die in tournament mode the     '
	dta d'next game will start at the beginning   '
	dta d'of the maze you died in. The maze       '
	dta d'selection will still read Tournament. In'
	dta d'order to start a tournament from        '
	dta d'scratch, use [OPTION] to rotate through '
	dta d'all the mazes until you are in          '
	dta d'"Tournament" again. Use [SPACE] to pause'
	dta d'and the fire button to end the pause. A '
	dta d'documentation about the genesis of this '
	dta d'patch is available at                   '
	dta d'http://atariage.com/forums/topic/271026-'*
	dta d'shamus-new-mazes-for-shamus'*,d'             '
	dta d'Shamus was originally written by William'
	dta d'Mataga and published by Synapse Software'
	dta d'in 1982. Copyright is assumed to be with'
	dta d'Cathryn Mataga at the time of this      '
	dta d'patch. The C64 levels are believed to   '
	dta d'have been developed by Jack L. Thornton '
	dta d'who is named on the C64 version title   '
	dta d'page. I have been unable to contact     '
	dta d'either of them and hope that they       '
	dta d'approve of this patch.                  ' 
	dta d'Copyright of the patch and conversion   '
	dta d'software is with the author permission  '
	dta d'to use, copy, modify, and distribute    '
	dta d'this software for any putpose without   '
	dta d'fee is hereby granted, provided that the'
	dta d'above copyright notice and this         '
	dta d'permission notice appear in all copies. '
	dta d'Should any of this interfere with any   '
	dta d'copyright of the original author(s),    '
	dta d'their copyright shall have precedence.  '
	dta d'THE SOFTWARE IS PROVIDED "AS IS" AND THE'
	dta d'AUTHOR DISCLAIMS ALL WARRANTIES WITH    '
	dta d'REGARD TO THIS SOFTWARE INCLUDING ALL   '
	dta d'IMPLIED WARRANTIES OF MERCHANTABILITY   '
	dta d'AND FITNESS. IN NO EVENT SHALL THE      '
	dta d'AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT'
	dta d'INDIRECT, OR CONSEQUENTIAL DAMAGES OR   '
	dta d'ANY DAMAGES WHATSOEVER RESULTING FROM   '
	dta d'LOSS OF USE, DATA OR PROFITS, WHETHER IN'
	dta d'AN ACTION OF CONTRACT, NEGLIGENCE OR    '
	dta d'OTHER TORTIOUS ACTION, ARISING OUT OF   '
	dta d'OR IN CONNECTION WITH THE USE OR        '
	dta d'PERFORMANCE OF THIS SOFTWARE.           '
	dta d'-------------------------------------slx'
	dta d'His Dark Majesty: Quest II'*,d'              '
	dta d'Twas thought His Dark Majesty was       '
	dta d'finally defeated in the Castle of Awe   '
	dta d'but it seems there was some deception,  '
	dta d'perhaps some mystical force was at work,'
	dta d'for he has once again started to conquer'
	dta d'lands and wreak havoc upon men. Rumour  '
	dta d'has it his subjects have built a new    '
	dta d'stronghold somewhere in the high cliffs.'
	dta d'Hearing this, the King has began to get '
	dta d'word out and amass an army of strongmen '
	dta d'from the local towns - he set off some  '
	dta d'weeks ago but there has been no word.   '
	dta d'You, his loyal subject answer the call  '
	dta d'and with a hunting party from your      '
	dta d'village set off to join him...          '
	dta d'------------------------therealbountybob'
	dta d'Dimos Dungeon and Dimos Quest'*,d'           '
	dta d'Both NTSC versions where tested in      '
	dta d'closed beta and about Dimos Dungeon was '
	dta d'said: - full playable and solvable      '
	dta d'      - no abnormalities                '
	dta d'Dimos Quest:                            '
	dta d'- no bugs found but not completly played'
	dta d'GetUp! v1.2'*,d'                             '
	dta d'New in this release: - now PAL and NTSC '
	dta d'- minor bug fixes (colors, high score)  '
	dta d'- better balance in scoring between     '
	dta d'  getting faster and slowing down       '
	dta d'- a little easier at the start, but     '
	dta d'  later harder                          '
	dta d'------------------------------8bitjunkie'
	dta d'QPA'*,d' shows a picture in new mode to test '
	dta d'mixed gfx8/gfx15 mode. Picture can be   '
	dta d'changed (at $8000). Send your thoughts  '
	dta d'in NYD18 thread please.                 '
	dta d'-----------------------------------Sikor'
endtxt

	run main
; ---

	opt l-

.MACRO	SPRITES
missiles
	.ds $100
player0
	.ds $100
player1
	.ds $100
player2
	.ds $100
player3
	.ds $100
.ENDM

USESPRITES = 0

.MACRO	DLINEW
	mva <:1 NMI.dliv
	ift [>?old_dli]<>[>:1]
	mva >:1 NMI.dliv+1
	eif

	ift :2
	lda regA
	eif

	ift :3
	ldx regX
	eif

	ift :4
	ldy regY
	eif

	rti

	.def ?old_dli = *
.ENDM

