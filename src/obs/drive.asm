; -------------------------------------------------------------------
; Print Current Drive
; Copyright 2023 by Gaston Williams
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
date:       db      80h+1          ; Month, 80h offset means extended info
            db      28             ; Day
            dw      2023           ; Year

            ; Current build number
build:      dw      8              ; build
            
            ; Must end with 0 (null)
            db      'Copyright 2023 Gaston Williams',0
           

start:      LOAD    rf, dta         ; point to suitable buffer
            ldi     0
            str     rf              ; place terminator
           
            CALL    o_chdir         ; get current directory      
          
            LOAD    rf, dta         ; point to retrieved path
            lda     rf              ; get first character
            smi     '/'             ; check for drive number string '//n'
            lbnz    error
            lda     rf              ; get first character
            smi     '/'             ; check for drive number string '//n'
            lbnz    error
            LOAD    rd, drv_num     ; point to drive number in message 
            lda     rf              ; next character is the number character
            str     rd              ; put character into message string
            inc     rd              ; point to next possible char
            ldn     rf              ; check for second char
            smi     '/'             ; if this is a slash, we're done
            lbz     show            ; show single digit drive number
            ldn     rf              ; otherwise store second number in message
            str     rd              ; put second digit in drive number
show:       LOAD    rf, out_msg     ; point to completed mesage
            CALL    o_msg           ; and display it
            LOAD    rf, crlf        ; display a cr/lf
            CALL    o_msg           ; display it 
            lbr     done
error:      LOAD    rf,err_msg      ; show error message
            ldi     0FFh            ; set error code
            shl                     ; set DF flag for error
done:       RETURN                  ; return to caller

            ; -- over-lapping strings
out_msg:    db      'Current drive: '
drv_num:    db      0,0,0
crlf:       db      13,10,0
            ; -- error message
err_msg:    db      'Error: unable to read drive number.',10,13,0

endrom:     equ     $

dta:        ds      512
