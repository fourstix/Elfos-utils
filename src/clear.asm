; -------------------------------------------------------------------
; Simple program to clear the screen
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
      org     02000h-6        ; Header starts at 01ffah
        dw      02000h          ; Program load address
        dw      endrom-2000h    ; Program size
        dw      02000h          ; Program execution address

      org     02000H
        br      start           ; Jump past build information
        ; Build date
date:   db      80H+12          ; Month (12) 80H offset means extended info
        db      31              ; Day (31)
        dw      2020            ; Year (2020)

        ; Current build number
build:  dw      3           ; Third build

        ; Must end with 0 (null)
        db      'Copyright 2020 by Gaston Williams',0

start:  ldi     0ch             ; ascii formfeed char clears screen
        sep     scall           ; Call o_type routine
        dw      o_type          ; to write char to display

        lbr     o_wrmboot       ; return to Elf/OS

        ;------ define end of execution block
endrom: equ     $
