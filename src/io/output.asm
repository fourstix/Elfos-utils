; -------------------------------------------------------------------
; Output data byte to port 4
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

#include ops.inc 
#include bios.inc
#include kernel.inc

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
date:   db      80H+9           ; Month, 80H offset means extended info
        db      22              ; Day
        dw      2021            ; Year

        ; Current build number
build:  dw      5

        ; Must end with 0 (null)
        db      'Copyright 2021 Gaston Williams',0

start:  lda     ra                  ; move past any spaces
        smi     ' '
        lbz     start
        dec     ra                  ; move back to non-space character
        ldn     ra                  ; check for nonzero byte
        lbnz    good                ; jump if non-zero
        
        CALL    o_inmsg             ; otherwise display usage     
        db      'Usage: output hh, where hh is a hexadecimal number',13,10,0
        RETURN                      ; return to os
          
good:   COPY    ra, rf              ; copy argument address to rf
        CALL    f_hexin             ; convert input to hex value

        glo     rd                  ; get the hexadecimal byte value
        str     r2                  ; put it on the stack
        out 4                       ; output to port 4, increments stack
        dec     r2                  ; back stack up to old location

        RETURN                      ; return to Elf/OS
        ;------ define end of execution block
endrom: equ     $
