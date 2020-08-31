;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

; frame_terminator	equ	-1

        output "sccLOFI_1c_VQ.rom"

		defpage	 0,0x4000, 0x2000	; page 0 main code
		defpage	 1,0x6000, 0xE000	; page 1 56KB of data i.e. 1..7 for the mapper
		defpage	 8,0x6000, 0x20000	; page 8 128KB of data


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
		ld		b,0					; mute all
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
		ld		de,frames
		add		hl,de			; Sfx# * 3 + frames
		ld		bc,3

		ld      a,(S988F)
		and		1
		jp		nz,test_ch2
								; play sfx on channel 1
		ld		de,PAG_SMPLE1
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
		ld		de,PAG_SMPLE2
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
		ld		de,PAG_SMPLE3
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
		ld		de,PAG_SMPLE4
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
set_waves:
		ld 		l,c
		ld		h,0
[5]		add		hl,hl				; wave number * 32
		ld		bc,0x6000
		add		hl,bc				; wave address
		
		add		a,:waves			; base wave page
		ld		(Bank2),a
		ld      (sccBank2),a
		ret
;-------------------------------------
ReplayerUpdateScc1:
		ld		a,(PAG_SMPLE1)
		ld		(Bank2),a
		ld      (sccBank2),a
		
		ld		hl,(PNT_SAMPLE1)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl

		bit		7,d					; frame terminator
		ld		b,0xFE				; mute ch1
		jp		nz,SCCReplayerMute

		ld		c,(hl)
		inc 	hl
		ld  	a,(hl)				; wave page
		inc 	hl
		bit     7,h					; test page crossing
		call	nz,ReplayerNextPage1
		ld		(PNT_SAMPLE1),HL
		
		call set_waves
		
		ld		a,15
		ld		(988Ah),a			; volume ch1

		ld		b,d					; save period		
		ld		c,e					; save period		
		ld		de,9800h			; wave ch1
		inc		bc
		ldi
		ld		(9880h),bc			; period ch1 and phase reset
[31]	ldi
		ret
		
; Moves sample pointer to next page
ReplayerNextPage1:
        ld      hl,PAG_SMPLE1
        inc     (hl)
        ld      hl,06000h
        ret

;-------------------------------------
ReplayerUpdateScc2:
		ld		a,(PAG_SMPLE2)
		ld		(Bank2),a
		ld      (sccBank2),a
		
		ld		hl,(PNT_SAMPLE2)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl

		bit		7,d					; frame terminator
		ld		b,0xFD				; mute ch2
		jp		nz,SCCReplayerMute

		ld		c,(hl)
		inc 	hl
		ld  	a,(hl)				; wave page
		inc 	hl
		bit     7,h					; test page crossing
		call	nz,ReplayerNextPage2
		ld		(PNT_SAMPLE2),HL
		
		call set_waves
		
		ld		a,15
		ld		(988Bh),a			; volume ch1

		ld		b,d					; save period		
		ld		c,e					; save period		
		ld		de,9820h			; wave ch2
		inc		bc
		ldi
		ld		(9882h),bc			; period ch2 and phase reset
[31]	ldi
		ret
; Moves sample pointer to next page
ReplayerNextPage2:
        ld      hl,PAG_SMPLE2
        inc     (hl)
        ld      hl,06000h
        ret

;-------------------------------------
ReplayerUpdateScc3:
		ld		a,(PAG_SMPLE3)
		ld		(Bank2),a
		ld      (sccBank2),a
		
		ld		hl,(PNT_SAMPLE3)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl

		bit		7,d					; frame terminator
		ld		b,0xFB				; mute ch3
		jp		nz,SCCReplayerMute

		ld		c,(hl)
		inc 	hl
		ld  	a,(hl)				; wave page
		inc 	hl
		bit     7,h					; test page crossing
		call	nz,ReplayerNextPage3
		ld		(PNT_SAMPLE3),HL
		
		call set_waves

		ld		a,15
		ld		(988Ch),a			; volume ch3
		ld		b,d					; save period		
		ld		c,e					; save period		
		ld		de,9840h			; wave ch3
		inc		bc
		ldi
		ld		(9884h),bc			; period ch3 and phase reset
[31]	ldi
		ret
		
; Moves sample pointer to next page
ReplayerNextPage3:
        ld      hl,PAG_SMPLE3
        inc     (hl)
        ld      hl,06000h
        ret
		
;-------------------------------------
ReplayerUpdateScc4:
		ld		a,(PAG_SMPLE4)
		ld		(Bank2),a
		ld      (sccBank2),a
		
		ld		hl,(PNT_SAMPLE4)
		ld		e,(hl)
		inc 	hl
		ld  	d,(hl)
		inc 	hl

		bit		7,d					; frame terminator
		ld		b,0xF7				; mute ch4
		jp		nz,SCCReplayerMute

		ld		c,(hl)
		inc 	hl
		ld  	a,(hl)				; wave page
		inc 	hl
		bit     7,h					; test page crossing
		call	nz,ReplayerNextPage4
		ld		(PNT_SAMPLE4),HL
		
		call set_waves

		ld		a,15
		ld		(988Dh),a			; volume ch4
		ld		b,d					; save period		
		ld		c,e					; save period		
		ld		de,9860h			; wave ch4
		inc		bc
		ldi
		ld		(9886h),bc			; period ch4 and phase reset
[31]	ldi
		ret

; Moves sample pointer to next page
ReplayerNextPage4:
        ld      hl,PAG_SMPLE4
        inc     (hl)
        ld      hl,06000h
        ret

;-------------------------------------
; Mute replayer
;-------------------------------------
SCCReplayerMute:
		ld      a,(S988F)
		and		b
		ld      (S988F),a
		ld      (988Fh),a			
		ret

;-------------------------------------
; Initialize the scc
;-------------------------------------
SccInit:
		ld		a,00100000b         ; Reset phase when freq is written
		ld		(98E0h),a			; on SCC
		ld		(98C0h),a			; on SCC+ in SCC mode

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
		include compressed_files_index.asm

		page 1
		include compressed_data.asm

		page 8
waves:		
		include compressed_data_waves.asm

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

PAG_SMPLE1			#1
PNT_SAMPLE1			#2

PAG_SMPLE2			#1
PNT_SAMPLE2			#2

PAG_SMPLE3			#1
PNT_SAMPLE3			#2

PAG_SMPLE4			#1
PNT_SAMPLE4			#2

;---------
; PAG_FRAME1			#1
; PAG_PERIOD1			#1
; PNT_FRAME1			#2
; PNT_PERIOD1			#2

; PAG_FRAME2			#1
; PAG_PERIOD2			#1
; PNT_FRAME2			#2
; PNT_PERIOD2			#2

; PAG_FRAME3			#1
; PAG_PERIOD3			#1
; PNT_FRAME3			#2
; PNT_PERIOD3			#2

; PAG_FRAME4			#1
; PAG_PERIOD4			#1
; PNT_FRAME4			#2
; PNT_PERIOD4			#2

					endmap

