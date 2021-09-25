;  -------------------------------------------------------------------
;  DMA Video Test
;  Based on Tom Pittman's original Video DMA Program
;  Published in A Short Course in Computer Programming by Tom Pittman
;  Copyright 1979 Netronics Research & Development Ltd.
;
;  Modified to run under the Elf/OS with Pico/Elf Pixie Video
;  Copyright 2021 by Gaston Williams
;  -------------------------------------------------------------------
; *** Based on Elf/OS software written by Michael H Riley
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
; **************************************************
date:      db      80h+9  ; Month
           db      23     ; Day
           dw      2021   ; Year

build:     dw      5      

           db      'Copyright 2021 Gaston Williams',0

        ; stack pointer r2 is already set by OS
start:     ldi 023H ; value for x=2; p=3
           str r2   ; save for disable Int instruction
           dis      ; Keep x=2; p=3 and disable interrupts

           ghi r3   ; P = 3
           phi r0   ; set up DMA pointer
           ldi 080H ; point to video Data
           glo r0   ; set up DMA pointer

Video:     inp 1    ; turn video on

           ;------------ DMA occurs here ------------

loop:      ldi 080H ; fix r0
           plo r0
           bn4 loop ; continue until input pressed

           ; Leave interrupts disabled
           out 1    ; turn off Video
           lbr     o_wrmboot       ; return to Elf/OS


  org 2080H
; data for video dma
buffer: db 080H, 081H, 082H, 083H, 084H, 085H, 086H, 087H
        db 088H, 089H, 08AH, 08BH, 08CH, 08DH, 08EH, 08FH
          
          ;------ define end of execution block  
endrom:   equ     $               ; End of code
