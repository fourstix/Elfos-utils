; -------------------------------------------------------------------
; Print Working Directory
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

include    bios.inc
include    kernel.inc


; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************

         org     02000h-6         ; Header starts at 01ffah
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           
         org     2000h            ; Program code starts at 2000
           br      start          ; Jump past build information

           ; Build date
date:      db      80h+2,         ; Month, 80h offset means extended info
           db      8              ; Day
           dw      2021           ; year = 2021

           ; Current build number
build:     dw      3              ; build

          ; Must end with 0 (null)
           db      'Copyright 2021 Gaston Williams',0


start:     ldi     high dta            ; point to suitable buffer
           phi     rf
           ldi     low dta
           plo     rf
           ldi     0
           str     rf                  ; place terminator
           sep     scall               ; get current directory
           dw      o_chdir
           ldi     high dta            ; point to retrieved path
           phi     rf
           ldi     low dta
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           ldi     high crlf           ; display a cr/lf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           sep     sret                ; return to caller

crlf:      db      13,10,0

endrom:    equ     $

dta:       ds      512
