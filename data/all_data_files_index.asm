    ; Game_Over.wav
    db data1 / 02000h+1,:period1
    dw 06000h+(data1 & 01FFFh),period1
    ; Land_now.wav
    db data2 / 02000h+1,:period2
    dw 06000h+(data2 & 01FFFh),period2
    ; Level_Start.wav
    db data3 / 02000h+1,:period3
    dw 06000h+(data3 & 01FFFh),period3
    ; Level_up.wav
    db data4 / 02000h+1,:period4
    dw 06000h+(data4 & 01FFFh),period4
    ; Power_up.wav
    db data5 / 02000h+1,:period5
    dw 06000h+(data5 & 01FFFh),period5
    ; Warning.wav
    db data6 / 02000h+1,:period6
    dw 06000h+(data6 & 01FFFh),period6
    ; Wave_incoming.wav
    db data7 / 02000h+1,:period7
    dw 06000h+(data7 & 01FFFh),period7
    ; completed.wav
    db data8 / 02000h+1,:period8
    dw 06000h+(data8 & 01FFFh),period8
    ; crithealth.wav
    db data9 / 02000h+1,:period9
    dw 06000h+(data9 & 01FFFh),period9
    ; failed.wav
    db data10 / 02000h+1,:period10
    dw 06000h+(data10 & 01FFFh),period10
    ; lowammo.wav
    db data11 / 02000h+1,:period11
    dw 06000h+(data11 & 01FFFh),period11
    ; lowhealth.wav
    db data12 / 02000h+1,:period12
    dw 06000h+(data12 & 01FFFh),period12
    ; radiation.wav
    db data13 / 02000h+1,:period13
    dw 06000h+(data13 & 01FFFh),period13
nfiles: equ  13 

