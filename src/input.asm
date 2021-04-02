; -------------------------------------------------------------------
; Input a data byte from port 4
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
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
      org     02000h-6          ; Header starts at 01ffah
        dw      02000h          ; Program load address
        dw      endrom-2000h    ; Program size
        dw      02000h          ; Program execution address

      org     02000h            ; Program code starts here
        br      start           ; Jump past build information

        ; Build date
date:   db      80H+1           ; Month, 80H offset means extended info
        db      1               ; Day
        dw      2021            ; Year

        ; Current build number
build:  dw      2

        ; Must end with 0 (null)
        db      'Copyright 2021 Gaston Williams',0

start:  inp     4                   ; input data from Port 4
        plo     rd                  ; put data byte into rd for conversion

        ldi     high buffer          ; Set up rf to point to a buffer
        phi     rf
        ldi     low buffer
        plo     rf

        sep     scall               ; convert to 2 char ASCII
        dw      f_hexout2

        ldi     high buffer          ; Set up rf to point to a buffer
        phi     rf
        ldi     low buffer
        plo     rf

        sep     scall               ; output text value
        dw      o_msg


        lbr     o_wrmboot           ; return to Elf/OS

buffer: db  0,0,0,0               ; 2 char hex value
        ;------ define end of execution block
endrom: equ     $
