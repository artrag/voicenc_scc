		
		
PrintSlots:		
		ld		de,40*8
		ld		hl,scc_slot_text
		call	message
        ld      de,40*8+10
		ld		hl,(SCC)
		ld		h,0
        call    PrintNum

		ld		de,40*9
		ld		hl,rom_slot_text
		call	message
        ld      de,40*9+10
		ld		hl,(slotvar)
		ld		h,0
        call    PrintNum

		ld		de,40*10
		ld		hl,ram_slot_text
		call	message
        ld      de,40*10+10
		ld		hl,(slotram)
		ld		h,0
        call    PrintNum
		
		ld		de,3*40+5
		ld		hl,instruction_text
		call	message

		ret
		

;-------------------------------------
;-------------------------------------
message:
        ld      a,e
        out     (99h),a
        ld      a,d
        and     3Fh
        or      40h
        out     (99h),a

1:		ld		a,(hl)
		and		a
		ret		z
		out     (98h),a
		inc		hl
		jr		1b
		
noSCC_text:
		db "No SCC detected.",0
instruction_text:
		db "use USR0(n) with n 0,1,...",0
scc_slot_text:
		db	"Scc slot: ",0
rom_slot_text:
		db	"Rom slot: ",0
ram_slot_text:
		db	"Ram slot: ",0
		