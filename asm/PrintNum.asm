;---------------------------------------------------------			
; method that prints hl on screen
; to address de
;---------------------------------------------------------			
PrintNum:
        ld      a,e
        out     (99h),a
        ld      a,d
        and     3Fh
        or      40h
        out     (99h),a

        push    hl
        ex      de,hl

        ld      a,d
        rlca
        rlca
        rlca
        rlca
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        ld      a,d
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        ld      a,e
        rlca
        rlca
        rlca
        rlca
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        ld      a,e
        and     15
        ld      b,0
        ld      c,a
        ld      hl,Numbers
        add     hl,bc
        ld      a,(hl)
        out     (98h),a

        pop     hl
        ret

Numbers:
        db  "0123456789ABCDEF"

