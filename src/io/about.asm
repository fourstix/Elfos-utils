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

        org     02000h-6        ; Header starts at 01ffah
            dw      2000h
            dw      endrom-2000h
            dw      2000h
        org     2000h          ; Program code starts at 2000
            br      start

; Build date
date:       db      80h+1,         ; Month, 80h offset means extended info
            db      13             ; Day
            dw      2023           ; year

; Current build number
build:      dw      7              ; build

            db      'Copyright 2023 Gaston Williams',0

start:      LOAD    rf, about_fn        ; information file about this config                      
            LOAD    rd, fildes          ; get file descriptor
            ldi     0                   ; flags for open
            plo     r7
            CALL    o_open              ; attempt to open file 
            lbnf    main                ; jump if file was opened
            LOAD    rf, errmsg          ; get error message
            CALL    o_msg               ; display it
            ldi     0ch
            RETURN                      ; and return to os
            
main:       ldi     0                   ; clear out skip character
            phi     r9       
            ldi     23                  ; 23 lines before pausing
            plo     r9
mainlp:     ldi     0                   ; want to read 16 bytes
            phi     rc
            ldi     16
            plo     rc 
            LOAD    rf, buffer          ; buffer to retrieve data
            CALL    o_read              ; read the header
            glo     rc                  ; check for zero bytes read
            lbz     done                ; jump if so
            LOAD    r8, buffer          ; buffer to retrieve data
linelp:     lda     r8                  ; get next byte
            stxd                        ; save a copy
            CALL    o_type
            irx                         ; recover character
            ghi     r9                  ; get skip character
            lbz     cont                ; continue on if no skip character
            sm                          ; check if this is skip character
            lbz     skipped             ; jump if skipped
cont:       ldx                         ; get character to check for eol
            smi     10                  ; check for lf (0ah)
            lbnz    chk_cr              ; if not lf check for cr  
            ldi     13                  ; skip next char if cr  (eol: lf,cr)    
            phi     r9              
            lbr     newline             ; process new line
chk_cr:     smi     3                   ; check for cr (0dh - 0ah = 3)
            lbnz    linelp2             ; jump if not cr
            ldi     10                  ; skip next char if lf (eol: cr,lf)
            phi     r9        
newline:    dec     r9                  ; decrement line count
            glo     r9                  ; see if full page
            lbnz    linelp2             ; jump if not
            call    o_inmsg             ; display more message
            db      10,'-MORE-',0
            call    o_readkey           ; check keys
            smi     3                   ; check for <CTRL><C>
            lbz     done                ; exit if <ESC> is pressed
            call    o_inmsg             ; display cr/lf
            db      10,13,0
            ldi     23                  ; reset line count
            plo     r9
skipped:    ldi     0
            phi     r9           
linelp2:    dec     rc                  ; decrement read count
            glo     rc                  ; see if done
            lbnz    linelp              ; loop back if not
            lbr     mainlp              ; and loop back til done

done:       sep     scall               ; close the file
            dw      o_close
            ldi     0
            RETURN                      ; return to os




about_fn:   db      '/cfg/about.nfo',0 
errmsg:     db      'File not found',10,13,0
fildes:     db      0,0,0,0
            dw      dta
            db      0,0
            db      0
            db      0,0,0,0
            dw      0,0
            db      0,0,0,0

endrom:     equ     $

.suppress

buffer:     ds      20
cbuffer:    ds      80
dta:        ds      512
