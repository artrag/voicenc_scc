    ; Wave_incoming.wav
    db data1 / 02000h+1,:period1
    dw 06000h+(data1 & 01FFFh),period1
    ; completed.wav
    db data2 / 02000h+1,:period2
    dw 06000h+(data2 & 01FFFh),period2
    ; lowhealth.wav
    db data3 / 02000h+1,:period3
    dw 06000h+(data3 & 01FFFh),period3
    ; radiation_Warning hazardous radiation level detected.wav
    db data4 / 02000h+1,:period4
    dw 06000h+(data4 & 01FFFh),period4
nfiles: equ  4 

