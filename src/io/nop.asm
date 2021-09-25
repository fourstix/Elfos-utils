; -------------------------------------------------------------------
; Do nothing but return to the Elf/OS
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
          
start:  RETURN                  ; return to Elf/OS

        ;------ define end of execution block
endrom: equ     $
