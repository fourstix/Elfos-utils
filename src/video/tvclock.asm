;  -------------------------------------------------------------------
; *** TV Clock based on code written by Tom Pittman
; *** Published in A Short Course in Programming by Tom Pittman
; *** Copyright 1979 Netronics Research & Development Ltd.
;  -------------------------------------------------------------------
; *** Modified to run under the Elf/OS with Pico/Elf Pixie Video
; *** Copyright 2021 by Gaston Williams
; *** Based on software written by Michael H Riley
; *** Thanks to the author for making this code available.
; *** Original author copyright notice:
; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#include ops.inc
#include bios.inc
#include kernel.inc

; ************************************************************
; This block generates the Execution header for a stand-alone
; program. It begins 6 bytes before the program start.
; ************************************************************

    org     02000h-6        ; Header starts at 01ffah
        dw      2000h
        dw      endrom-2000h
        dw      2000h
        
    org     2000h          ; Program code starts at 2000
        br      start
; **************************************************
; *** Build information:                         ***
; ***    build date                              ***
; ***    build number                            ***
; ***    No information text string              ***
; **************************************************
; Build date
date:   db      80h+9          ; Month, 80h offset means extended info
        db      24             ; Day
        dw      2021           ; year = 2021

; Current build number
build:  dw      5              ; build for kernel 4

; Must end with 0 (null)
        db      0              ; No room for information string!


        ;
        ; TV DIGITAL CLOCK
        ;
start:  ghi r3        ;INITIALIZE R0, R1
        phi r0
        phi r1
        ldi low ints  ; .. R1 = INTERRUPT PC
        plo r1
        sex r3        ; Thanks to David Madole for fix 
        ret           ; turn on interrupts
        db 23H        ; x=2, p=3
main:   inp 1         ; TURN ON TV
        br test       ; check for button press

done:   inc r2        ;.. ASSUME X=2!
        lda r2        ;.. RESTORE DF
        shr
        lda r2        ;.. RESTORE R7
        phi r7
        lda r2
        plo r7
        lda r2        ;.. NOW D
        ret           ;.. RESTORE X AND P
ints:   nop           ;.. EVEN OUT CYCLES
        dec r2        ;.. PUSH STACK, TO
        sav           ;.. SAVE X AND P (IN T)
        dec r2
        stxd          ;.. SAVE D
        glo  r7       ;.. SAVE R7
        stxd
        ghi r7
        stxd
        shlc          ;.. SAVE DF
        stxd
        ldi low buff  ;.. SET UP R0
        b1  $         ;.. WAIT FOR DISPLAY
row:    plo r0
                ;...  DMA HERE
        plo r0        ;.. RESET R0
        phi r7
        ldi 0Bh       ;.. (RASTER COUNT - 3)/2
                ;...  DMA HERE
        plo r7
        ghi r7        ;.. KEEP FIXING R0
        plo r0
                ;...  DMA HERE
rept:   dec r7        ;.. COUNTER RASTERS
        ghi r7
        plo r0
                ;...  DMA HERE
        plo r0
        glo r7        ;.. TWO LINES PER LOOP
        bnz rept
                 ;...  DMA HERE
        glo r0        ;.. IF LAST TIME,
        bn1 row
        plo r0        ;.. JUST BLANK IT
                ;...  DMA HERE
                     ;003D 343C  B1 *-1    .. (3 LINES)
        b1  $-1      ;  B1 *-1    .. (3 LINES)
                ;
                ; SECONDS CLOCK
                ;
        ghi r3          ; Thanks to David Madole for fix
        phi r7
        ldi low frct    ;.. POINT TO FRAME COUNT
        plo r7          ;.. R7 IS AVAILABLE
        ldn r7
        adi 01h         ;.. BUMP COUNTER
        str r7
        smi 3Dh         ;.. MOD 61
        bnf done        ;.. NOT OVER
        sex r7
        stxd            ;.. ROLL OVER
        ldx             ;.. TO SECONDS
        adi 03h
        str r7
        bnf unit        ;.. GO DISPLAY
        ldi 0E2h        ;.. ROLL OVER -30
        stxd
        ldx              ;.. TO TENS
        adi 03h
        str r7
        adi 0Ch         ;.. (OVERFLOW AT 60) ADI 12
        bnf tens
        ldi 0E2h        ;.. ONE MINUTE! -30
        str r7
                    ;...    .. COULD DO MINUTES, HOURS...
tens:   ldi low buff    ;.. POINT TO LEFT DIGIT
                    ;0064 306B  BR UNIT+2
        br unit+2
        ldi low secs    ;.. (POINT TO COUNTER)
        plo r7
unit:   ldi low brit    ;.. OR RIGHT DIGIT
        plo r0
        lda r7          ;.. POINT TO DIGITS
                    ;006D FCAC  ADI TABL  .. (TABLE OFFSET)
        adi low tabl    ;.. (TABLE OFFSET)
        plo r7
down:   lda r7          ;.. GET DOTS
        str r2          ;.. (SAVE)
        sex r2
half:   ldx             ;.. CONVERT A DOT
        shl              ;.. FROM A BIT
        str r2
        sdb             ;.. =00 IF DF=1, =FF IF DF=0
        str r0          ;.. STORE INTO BUFFER
        inc r0
        glo r0
        ani 03h         ;.. DO THIS 4 TIMES
        bnz half        ;.. (9*4 INSTRUCTIONS)
        inc r0
        inc r0
        inc r0
        inc r0
        LDX             ;.. CHECK FOR SECOND 4 BITS
        bnz half        ;.. ((36+6)*2)
        glo r0          ;.. REPEAT IF THIS WAS LEFT
                  ;0086 FFF8  SMI BEND
        smi low bend    ;check for end of buffer
        bnf down        ;.. ((84+6)*3)
                  ;008A 3266  BZ UNIT-3 .. ((270+9)*2)
        bz unit-3       ;.. ((270+9)*2)
        br done         ;.. MAX TOTAL <600 INSTRUCTIONS

;  DOT TABLE FOR DIGITS
    db 0DAh, 0AAh, 0DFh   ; 0
    db 0D9h, 0DDh, 08Fh   ; 1
    db 09Eh, 0DBh, 08Fh   ; 2
    db 09Eh, 0DEh, 09Fh   ; 3
    db 0EAh, 0A8h, 0EFh   ; 4
    db 08Bh, 09Eh, 09Fh   ; 5
    db 0CBh, 09Ah, 0DFh   ; 6
    db 08Eh, 0DBh, 0BFh   ; 7
    db 0DAh, 0DAh, 0DFh   ; 8
    db 0DAh, 0CEh, 0DFh   ; 9
tabl:    equ    $

test:   bn4 test      ; wait for button express
        b4 $          ; wait for button release
        ldi 23H       ; value for x=2, p=3
        str r2        ; store on stack for disable instruction
        dis           ; x=2, p=3 and disable interrupts
        out 1         ; turn off Video, increments stack
        dec 2         ; put stack pointer back to original
        lbr o_wrmboot ; return to Elf/OS

  org 20c5h           ;.. TIME COUNTERS AND DISPLAY BUFFER
sten:  db 0E2h        ;.. MUST INITIALIZE
secs:  db 0E2h        ;.. SECS:  #E2
frct:  db 00h
buff:  db 0,0,0,0     ;.. EMPTY BUFFER
       ;----   org 20cch
brit: db 0,0,0,0
      db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      db 0,0,0,0,0,0,0,0
       ;---- org 20F8h
bend: equ    $
endrom:    equ     $               ; End of code
