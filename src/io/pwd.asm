; -------------------------------------------------------------------
; Print Working Directory
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

#include    ops.inc
#include    bios.inc
#include    kernel.inc


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
date:       db      80h+9          ; Month, 80h offset means extended info
            db      22             ; Day
            dw      2021           ; Year

            ; Current build number
build:      dw      5              ; build
            
            ; Must end with 0 (null)
            db      'Copyright 2021 Gaston Williams',0
           

start:      LOAD    rf, dta         ; point to suitable buffer
            ldi     0
            str     rf              ; place terminator
           
            CALL    o_chdir         ; get current directory      
          
            LOAD    rf, dta         ; point to retrieved path
            CALL    o_msg           ; display it
  
            LOAD    rf, crlf        ; display a cr/lf
            CALL    o_msg           ; display it    
            RETURN                  ; return to caller

crlf:      db      13,10,0

endrom:    equ     $

dta:       ds      512
