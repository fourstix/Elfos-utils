; -------------------------------------------------------------------
; Simple program to clear the screen (Ansi or non-Ansi)
; Copyright 2020 by Gaston Williams
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

      org     02000H
        br      start           ; Jump past build information
        ; Build date
date:   db      80H+8           ; Month 80H offset means extended info
        db      21              ; Day
        dw      2021            ; Year

        ; Current build number
build:  dw      4           

        ; Must end with 0 (null)
        db      'Copyright 2021 by Gaston Williams',0

start:  sep     scall             ; Call inline message routine
        dw      o_inmsg           ; to write clear string to display
        db      01bh,'[2J',0ch,0  ; ANSI string followed by form feed character

        lbr     o_wrmboot         ; return to Elf/OS

        ;------ define end of execution block
endrom: equ     $
