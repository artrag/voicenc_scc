    ; Game_Over.wav
    db :sample1+sample1/0x2000-3
    dw 0x6000+(sample1 & 0x1FFF)
    ; Land_now.wav
    db :sample2+sample2/0x2000-3
    dw 0x6000+(sample2 & 0x1FFF)
    ; Level_Start.wav
    db :sample3+sample3/0x2000-3
    dw 0x6000+(sample3 & 0x1FFF)
    ; Level_up.wav
    db :sample4+sample4/0x2000-3
    dw 0x6000+(sample4 & 0x1FFF)
    ; Power_up.wav
    db :sample5+sample5/0x2000-3
    dw 0x6000+(sample5 & 0x1FFF)
    ; Warning.wav
    db :sample6+sample6/0x2000-3
    dw 0x6000+(sample6 & 0x1FFF)
    ; Wave_incoming.wav
    db :sample7+sample7/0x2000-3
    dw 0x6000+(sample7 & 0x1FFF)
    ; completed.wav
    db :sample8+sample8/0x2000-3
    dw 0x6000+(sample8 & 0x1FFF)
    ; crithealth.wav
    db :sample9+sample9/0x2000-3
    dw 0x6000+(sample9 & 0x1FFF)
    ; failed.wav
    db :sample10+sample10/0x2000-3
    dw 0x6000+(sample10 & 0x1FFF)
    ; lowammo.wav
    db :sample11+sample11/0x2000-3
    dw 0x6000+(sample11 & 0x1FFF)
    ; lowhealth.wav
    db :sample12+sample12/0x2000-3
    dw 0x6000+(sample12 & 0x1FFF)
    ; radiation.wav
    db :sample13+sample13/0x2000-3
    dw 0x6000+(sample13 & 0x1FFF)
nfiles: equ  13 

