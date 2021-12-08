;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

	
frame_terminator	equ	-1

        output "sccLOFI_1c.rom"

		defpage	 0,0x4000, 0x2000	; page 0 main code
		defpage	 1,0x6000, 0x2000	; page 1 data
		defpage	 2..3				; page 2-3 period data
		defpage	 4,0x6000, 0x78000	; page 4-15 data


; memory layout
; 0x4000	- bank1 ascii mapper
; 0x6000	- bank2 ascii mapper
; 0x8000	- bank3 scc mapper
; 0xB000	- bank4 scc mapper (unused)



		page 0
        org 4000h
        dw  4241h,START,0,0,0,0,0

; ascii-8 registers
;	Bank 1: 6000h - 67FFh (6000h used)
;	Bank 2: 6800h - 6FFFh (6800h used)
;	Bank 3: 7000h - 77FFh (7000h used)
;	Bank 4: 7800h - 7FFFh (7800h used)


; ascii-8 mapper
Bank1:  equ      6000h
Bank2:  equ      6800h
Bank3:  equ      7000h
Bank4:  equ      7800h

; scc mapper for scc chip
sccBank1:  equ      05000h
sccBank2:  equ      07000h
sccBank3:  equ      09000h
sccBank4:  equ      0B000h


;-------------------------------------
; try to make rom guessers happy
;-------------------------------------
init_mapper:
		ld     a,init_mapper/02000h-2
		ld      (Bank1),a
		ld      (sccBank1),a
		inc		a
		ld      (Bank2),a
		ld      (sccBank2),a
		inc		a
		ld      (Bank3),a
		ld      (sccBank3),a
		inc		a
		ld      (Bank4),a
		ld      (sccBank4),a
		ret

;-------------------------------------
; Entry point
;-------------------------------------
START:
		ld		a,40
		ld		(0xF3AE),a	; screen width
		xor     a
		call    005Fh
		xor     a
		ld		(0xF3DB),a	; no key click


		call	search_slot
		call	search_slotram
		call    SCCsearch

		call	init_mapper

		call	PrintSlots

		ld		a,(SCC)
		inc		a
		jr		nz,scc_install

no_scc:
		ld		de,5*40+5
		ld		hl,noSCC_text
		di
		call	message
		ei
		jr waitforhalfsec

scc_install:
		call	en_scc				; scc in page 2
		di
		ld      a,3Fh
		ld      (sccBank3),a
		call    SccInit
		call    SCCReplayerMute
		call 	InstallIntHanlderScc
		call	en_slot
		ei
waitforhalfsec:
		ld	b,30
1:		halt
		djnz	1b
		ret




;-------------------------------------
; method that prints hl on screen
; to address de
;-------------------------------------
		include PrintNum.asm
		include PrintSlots.asm

;-------------------------------------

InstallIntHanlderScc:
		di
		ld      hl,ISRScc
		ld      ($FD9C),hl

		ld      a,0xF7
		ld      ($FD9A),a
		ld		a,(slotvar)
		ld		($FD9B),a
		ld      a,0xC9
		ld      ($FD9E),a

		ld		hl,USR0
		ld		(0xF39A),hl

		ld      a,0xF7
		ld      (USR0+0),a
		ld		a,(slotvar)
		ld		(USR0+1),a
		ld      hl,HandleUsr
		ld      (USR0+2),hl
		ld      a,0xC9
		ld      (USR0+4),a
		ei
		ret

;-------------------------------------


HandleUsr:
		ld		a,(0xF663)
		cp		2
		ret		nz				; CF = 0

		ld		hl,(0xF7F8)		; Initialize replayer
		ld  	de,nfiles
		sbc		hl,de
		ret		nc				; error: sfx not present
		add 	hl,de			; in : hl  # of Sfx

		ld		e,l
		ld		d,h
		add		hl,hl
		add		hl,de			
		add		hl,hl			; Sfx# * 6 + frames
		ld		de,frames
		add		hl,de
		ld		bc,6

		ld      a,(S988F)
		and		1
		jp		nz,test_ch2
								; play sfx on channel 1
		ld		de,PAG_FRAME1
		ldir

		ld      a,(S988F)
		or		1
		ld      (S988F),a
		ret
test_ch2:
		ld      a,(S988F)
		and		2
		jp		nz,test_ch3
								; play sfx on channel 2
		ld		de,PAG_FRAME2
		ldir

		ld      a,(S988F)
		or		2
		ld      (S988F),a
		ret
test_ch3:
		ld      a,(S988F)
		and		4
		jp		nz,test_ch4
								; play sfx on channel 3
		ld		de,PAG_FRAME3
		ldir

		ld      a,(S988F)
		or		4
		ld      (S988F),a
		ret
test_ch4:
		ld      a,(S988F)
		and		8
		jr		nz,ch_error		; no channels to play
								; play sfx on channel 4
		ld		de,PAG_FRAME4
		ldir

		ld      a,(S988F)
		or		8
		ld      (S988F),a
		ret
ch_error:
		ld		hl,-1
		ld		(0xF7F8),hl		; report replayer error 
		ret

;-------------------------------------


ISRScc:
		call	en_scc				; scc in page 2
		ld      a,3Fh
		ld      (sccBank3),a		; scc registers in page 2
		ld      a,(S988F)
		ld      (988Fh),a

		ld      a,(S988F)
		and		1
		call    nz,ReplayerUpdateScc1
		ld      a,(S988F)
		and		2
		call    nz,ReplayerUpdateScc2
		ld      a,(S988F)
		and		4
		call    nz,ReplayerUpdateScc3
		ld      a,(S988F)
		and		8
		call    nz,ReplayerUpdateScc4

		call	en_slot
		ret

;-------------------------------------
ReplayerUpdateScc1:
		ld		a,(PAG_PERIOD1)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_PERIOD1)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl
		LD		(PNT_PERIOD1),HL
		ld		hl,-1				; frame terminator
		or		a
		sbc		hl,de
		JP		Z,SCCReplayerMute1
		ld		a,15
		ld		(988Ah),a			; volume ch1
		push	de
		ld		a,(PAG_FRAME1)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_FRAME1)
		ld		de,9800h			; wave ch1
		pop 	bc
		inc		bc
		ldi
		ld		(9880h),bc			; period ch1 and phase reset
[31]	ldi
		bit     7,h					; test page crossing
        call    nz,ReplayerNextPage1
		ld      (PNT_FRAME1),hl
		ret
; Moves sample pointer to next page
ReplayerNextPage1:
        ld      hl,PAG_FRAME1
        inc     (hl)
        ld      hl,06000h
        ret
; Mute replayer
SCCReplayerMute1:
		ld      a,(S988F)
		and		0xFE
		ld      (S988F),a
		ld      (988Fh),a		; mute ch1
		ret

;-------------------------------------
ReplayerUpdateScc2:
		ld		a,(PAG_PERIOD2)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_PERIOD2)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl
		LD		(PNT_PERIOD2),HL
		ld		hl,-1				; frame terminator
		or		a
		sbc		hl,de
		JP		Z,SCCReplayerMute2
		ld		a,15
		ld		(988Bh),a			; volume ch2
		push	de
		ld		a,(PAG_FRAME2)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_FRAME2)
		ld		de,9820h			; wave ch2
		pop		bc
		inc		bc
		ldi
		ld		(9882h),bc			; period ch2 and phase reset
[31]	ldi
        bit     7,h					; test page crossing
        call    nz,ReplayerNextPage2
		ld      (PNT_FRAME2),hl
		ret
; Moves sample pointer to next page
ReplayerNextPage2:
        ld      hl,PAG_FRAME2
        inc     (hl)
        ld      hl,06000h
        ret
; Mute replayer
SCCReplayerMute2:
		ld      a,(S988F)
		and		0xFD
		ld      (S988F),a
		ld      (988Fh),a		; mute ch2
		ret

;-------------------------------------
ReplayerUpdateScc3:
		ld		a,(PAG_PERIOD3)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_PERIOD3)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl
		LD		(PNT_PERIOD3),HL
		ld		hl,-1				; frame terminator
		or		a
		sbc		hl,de
		JP		Z,SCCReplayerMute3
		ld		a,15
		ld		(988Ch),a			; volume ch3
		push	de
		ld		a,(PAG_FRAME3)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_FRAME3)
		ld		de,9840h			; wave ch13
		pop		bc
		inc		bc
		ldi
		ld		(9884h),bc			; period ch3 and phase reset
[31]	ldi
        bit     7,h					; test page crossing
        call    nz,ReplayerNextPage3
		ld      (PNT_FRAME3),hl
		ret
; Moves sample pointer to next page
ReplayerNextPage3:
        ld      hl,PAG_FRAME3
        inc     (hl)
        ld      hl,06000h
        ret
; Mute replayer
SCCReplayerMute3:
		ld      a,(S988F)
		and		0xFB
		ld      (S988F),a
		ld      (988Fh),a		; mute ch3
		ret
		
;-------------------------------------
ReplayerUpdateScc4:
		ld		a,(PAG_PERIOD4)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_PERIOD4)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl
		LD		(PNT_PERIOD4),HL
		ld		hl,-1				; frame terminator
		or		a
		sbc		hl,de
		JP		Z,SCCReplayerMute4
		ld		a,15
		ld		(988Dh),a			; volume ch4
		push	de
		ld		a,(PAG_FRAME4)
		ld		(Bank2),a
		ld      (sccBank2),a
		ld		hl,(PNT_FRAME4)
		ld		de,9860h			; wave ch14
		pop		bc
		inc		bc
		ldi 
		ld		(9886h),bc			; period ch4 and phase reset
[31]	ldi
        bit     7,h					; test page crossing
        call    nz,ReplayerNextPage4
		ld      (PNT_FRAME4),hl
		ret
; Moves sample pointer to next page
ReplayerNextPage4:
        ld      hl,PAG_FRAME4
        inc     (hl)
        ld      hl,06000h
        ret
; Mute replayer
SCCReplayerMute4:
		ld      a,(S988F)
		and		0xF7
		ld      (S988F),a
		ld      (988Fh),a		; mute ch4
		ret



;-------------------------------------
; Mute replayer
;-------------------------------------
SCCReplayerMute:
		xor		a
		ld      (S988F),a
		ld      (988Fh),a		; mute all
		ret

;-------------------------------------
; Initialize the scc
;-------------------------------------
SccInit:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	LATER NOTE: DO NOT RESET THE SAMPLE PHASE IN ORDER TO REDUCE DISCONTINUITY BETWEEN WAVES
;
;		ld		a,00100000b         ; Reset phase when freq is written
;		ld		(98E0h),a			; on SCC
;		ld		(98C0h),a			; on SCC+ in SCC mode

		; ld      a,00001111b     	; scc channel 1,2,3,4 active
		; ld      (988Fh),a

		; xor	a
		; ld		(988Ah),a				; volume ch1
		; ld		(988Bh),a				; volume ch2
		; ld		(988Ch),a				; volume ch3
		; ld		(988Dh),a				; volume ch3

        ret

;-------------------------------------
;		audio data
;
		page 0
frames:
		include all_data_files_index.asm

		page 1..3
		include all_data_files_periods.asm

		page 4
		include all_data_files_waves.asm

		page 0


;-------------------------------------
		include checkkbd.asm

;-------------------------------------
; SCC and Slot management
;-------------------------------------
		include rominit64.asm
		include sccdetec.asm

;-------------------------------------

FINISH:


;---------------------------------------------------------
; Variables
;---------------------------------------------------------
					map 0xFD09		; unused ram

slotvar:            #1
slotram:            #1
SCC:            	#1
curslot:            #1
cursubslots:		#1

USR0:				#5

S988F:           	#1				; ram mirror of 988Fh

PAG_FRAME1			#1
PAG_PERIOD1			#1
PNT_FRAME1			#2
PNT_PERIOD1			#2

PAG_FRAME2			#1
PAG_PERIOD2			#1
PNT_FRAME2			#2
PNT_PERIOD2			#2

PAG_FRAME3			#1
PAG_PERIOD3			#1
PNT_FRAME3			#2
PNT_PERIOD3			#2

PAG_FRAME4			#1
PAG_PERIOD4			#1
PNT_FRAME4			#2
PNT_PERIOD4			#2

					endmap

