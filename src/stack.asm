; -------------------------------------------------------------------
; Simple program to exit the Elf/OS and return to the STG ROM
; Copyright 2021 by Gaston Williams
; -------------------------------------------------------------------
; Based on software written by Michael H Riley
; Thanks to the author for making this code available.
; Original author copyright notice:
; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include bios.inc
include kernel.inc

; ************************************************************
; ***** This block generates the 6 byte Execution header *****
;
; ************************************************************
; The Execution header starts 6 bytes before the program start
      org     02000h-6          ; Header starts at 01ffah
        dw      02000h          ; Program load address
        dw      endrom-2000h    ; Program size
        dw      02000h          ; Program execution address

      org     2000h             ; Program code begins here
        br      start           ; Jump past build information

        ; Build date
date:   db      80H + 8         ; Month 80H offset means extended info
        db      21              ; Day
        dw      2021            ; Year

        ; Current build number
build:  dw      4
        ; Must end with 0 (null)

        db      'Copyright 2021 by Gaston Williams',0

start:     ghi     r2
           phi     rd
           glo     r2
           plo     rd
           mov     rf,buffer           ; point to output buffer
           sep     scall               ; convert address to ASCII hex
           dw      f_hexout4
           mov     rf,buffer           ; point to output buffer
           sep     scall               ; and display it
           dw      o_msg
           sep     sret                ; return to Elf/OS
           
buffer:    db      0,0,0,0,10,13,0

        ;------ define end of execution block
endrom: equ     $
