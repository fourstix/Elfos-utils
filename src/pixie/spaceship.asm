;  -------------------------------------------------------------------
; Original Elf Pixie Graphic Program by Joseph A Weisbecker
; Published in Popular Electronics, July 1979, pages 41-46
; Copyright Joseph A Weisbecker 1976-1979
;
; Modified to run under the Elf/OS with the Pico/Elf PixieVideo
; Copyright 2021 by Gaston Williams
;  -------------------------------------------------------------------
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
include  kernel.inc

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

date:      db      80h+9   ; January
           db      23      ; Day
           dw      2021    ; Year
build:     dw      5       ; build for kernel 4
           db      0       ; No room for information string!

start:     ghi     r3            ; P=3, X=2 in Elf/OS
           phi     r1            ; Set up interrupt register
           ldi     low interrupt ; set interrupt address
           plo     r1            ; to point to interrupt handler

           ldi     023H          ; Value for x=2; p=3
           str     r2            ; Save for return instruction
           ret                   ; Keep x=2; p=3 and enable interrupts

           br      main          ; go to main routine and wait for interrupt

return:    ldxa                  ; restore D,
           ret                   ; return point X, P back to original locations
interrupt: dec     r2            ; move stack pointer
           sav                   ; save T register
           dec     r2            ; move stack pointer
           str     r2            ; Store D onto stack
           nop                   ; 3 nops = 9 cycles to make interrupt
           nop                   ; routine exactly the 29 instruction cycles
           nop                   ; required for 1861 timing
           ldi     20h           ; point dma register at code page
           phi     r0            ;
           ldi     00h           ; point dma register at code page
           plo     r0
refresh:   glo     r0            ; D = r0.0
           sex     r2            ; X = 2
                     ; <----- 8 DMA cycles occur here (R0+8)
           sex     r2    ; there is time for exactly 6 instruction cycles
           dec     r0    ; utilized here by 3 two-cycle instructions
           plo     r0    ; in between dma requests
                     ; <----- 8 DMA cycles occur here (R0+8)
           sex     r2
           dec     r0
           plo     r0
                     ; <----- 8 DMA cycles occur here (R0+8)
           sex     r2
           dec     r0
           plo     r0
                     ; <----- 8 DMA cycles occur here (R0+8)
           bn1     refresh   ; go to refresh if EF1 false
           br      return    ; return if EF1 true (end of frame)

main:      inp 1             ; Turn on Video
wait:      bn4     wait      ; wait for Input pressed to exit
           ldi     23H       ; value for x=2, p=3
           str     r2        ; store on stack for disable instruction
           dis               ; x=2, p=3 and disable interrupts
           out 1             ; turn off Video, increments stack
           dec 2             ; put stack pointer back to original
           lbr     o_wrmboot ; return to Elf/OS

; ***************************************
; Data for spaceship graphic image
; ***************************************
  org 2040h
spaceship: db 00h, 00h,  00h,  00h,  00h,  00h,  00h,  00h
           db 00h, 00h,  00h,  00h,  00h,  00h,  00h,  00h
           db 7Bh, 0DEh, 0DBh, 0DEh, 00h,  00h,  00h,  00h
           db 4Ah, 50h,  0DAh, 52h,  00h,  00h,  00h,  00h
           db 42h, 5Eh,  0ABh, 0D0h, 00h,  00h,  00h,  00h
           db 4Ah, 42h,  8Ah,  52h,  00h,  00h,  00h,  00h
           db 7Bh, 0DEh, 8Ah,  5Eh,  00h,  00h,  00h,  00h
           db 00h, 00h,  00h,  00h,  00h,  00h,  00h,  00h
           db 00h, 00h,  00h,  00h,  00h,  00h,  07h,  0E0h
           db 00h, 00h,  00h,  00h,  0FFh, 0FFh, 0FFh, 0FFh
           db 00h, 06h,  00h,  01h,  00h,  00h,  00h,  01h
           db 00h, 7Fh,  0E0h, 01h,  00h,  00h,  00h,  02h
           db 7Fh, 0C0h, 3Fh,  0E0h, 0FCh, 0FFh, 0FFh, 0FEh
           db 40h, 0Fh,  00h,  10h,  04h,  80h,  00h,  00h
           db 7Fh, 0C0h, 3Fh,  0E0h, 04h,  80h,  00h,  00h
           db 00h, 3Fh,  0D0h, 40h,  04h,  80h,  00h,  00h
           db 00h, 0Fh,  08h,  20h,  04h,  80h,  7Ah,  1Eh
           db 00h, 00h,  07h,  90h,  04h,  80h,  42h,  10h
           db 00h, 00h,  18h,  7Fh,  0FCh, 0F0h, 72h,  1Ch
           db 00h, 00h,  30h,  00h,  00h,  10h,  42h,  10h
           db 00h, 00h,  73h,  0FCh, 00h,  10h,  7Bh,  0D0h
           db 00h, 00h,  30h,  00h,  3Fh,  0F0h, 00h,  00h
           db 00h, 00h,  18h,  0Fh,  0C0h, 00h,  00h,  00h
           db 00h, 00h,  07h,  0F0h, 00h,  00h,  00h,  00h
           
           ;------ define end of execution block
endrom:    equ     $               ; End of code
