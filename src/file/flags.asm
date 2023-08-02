; -------------------------------------------------------------------
; Show directory, executable and hidden flags for a file.
; Copyright 2021 by Gaston Williams
; -------------------------------------------------------------------
; Based on software written by Michael H Riley
; Thanks to the author for making this code available.
; Original author copyright notice:
; *******************************************************************
; *** This software is copyright 2005 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************
.list

#include    ops.inc
#include    bios.inc
#include    kernel.inc

d_ideread:  equ    0447h

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

            ; Must end with 0 (null)
            db      'Copyright 2023 Gaston Williams',0

start:      lda     ra                  ; move past any spaces
            smi     ' '
            lbz     start
            dec     ra                  ; move back to non-space character
            ghi     ra                  ; copy argument address to rf
            ldn     ra                  ; get byte
            lbnz    start1              ; jump if argument given
            CALL    o_inmsg             ; otherwise display usage message
            db      'Usage: flags filename',10,13,0
            lbr     o_wrmboot           ; Return to Elf/OS
           
start1:     COPY    ra, rf              ; copy argument address to rf
loop1:      lda     ra                  ; look for first less <= space
            smi     33
            lbdf    loop1
            dec     ra                  ; backup to previous char
            dec     ra                  ; back up to trailing character
            lda     ra                  ; check for trailing slash
            smi     '/'                 ; remove trailing slash for dir file name
            lbnz    end_ln              ; any other character is okay
            dec     ra                  ; move back one character             
end_ln:     ldi     0                   ; need proper termination
            str     ra
            LOAD    rd, fildes          ; get file descriptor
           
            LOAD    r7, 10h             ; open a directory or a file          
            CALL    o_open              ; attempt to open file
            lbnf    opened              ; jump if file opened

            LOAD    rf, errmsg          ; point to error message
            CALL    o_msg               ; display no message
            lbr     o_wrmboot           ; Return to Elf/OS
            
opened:     LOAD    rf,flags            ; get flags byte from file descriptor
            ldn     rf
            stxd                        ; save for next bit check
            ani     020h                ; check directory bit
            lbz     ddot                ; show dot if no flag
            CALL    o_inmsg             ; show d for a directory
            db      'd ',0
            lbr     checkx           

ddot:       CALL    ShowDot             ; show dot for no flag

checkx:     irx                         ; get flags byte from stack
            ldx
            ani     040h                ; check executable bit
            lbz     xdot                ; show dot if no flag bit 
            CALL    o_inmsg             ; show x for a executable
            db      'x ', 0
            lbr     checkh              ; check hidden bit in directory entry

xdot:       CALL    ShowDot             ; show dot for no flag

checkh:     LOAD    rf, sector          ; point to dir sector in FILDES
            inc     rf
            lda     rf                  ; retrieve sector
            plo     r8
            lda     rf
            phi     r7
            lda     rf
            plo     r7
            ldi     0e0h                ; lba mode
            phi     r8
            LOAD    rf, secbuf          ; where to load sector
            CALL    d_ideread           ; call bios to read the sector
                   
            LOAD    rf, offset          ; need dirent offset from fildes
            lda     rf
            phi     r7
            lda     rf
            adi     6                   ; point to flags byte
            plo     r7
            ghi     r7
            adci    0                   ; propagate carry from previous add
            phi     r7                  ; r7 now points to flags
            glo     r7                  ; now point to correct spot in sector buffer
            adi     secbuf.0
            plo     r7
            ghi     r7
            adci    secbuf.1
            phi     r7
            ldn     r7                  ; get flag byte
            stxd                        ; save on stack for next bit check
            ani     08h                 ; check hidden bit
            lbz     hdot                ; show dot if no flag bit
            CALL    o_inmsg             ; show h for hidden file
            db      'h ',0
            lbr     checkw
              
hdot:       CALL    ShowDot             ; show dot for no flag
  
checkw:     irx                         ; get flags byte from stack
            ldx
            ani     04h                 ; check write-protect bit
            lbz     wdot
            CALL    o_inmsg             ; show w for write protected file
            db      'w',0
            lbr     done

wdot:       CALL    ShowDot             ; show a dot for no flag             
            
done:       CALL    o_inmsg             ; output CR/LF
            db      13,10,0
            RETURN                      ; Return to Elf/OS
; -------------------------------------------------------------------
ShowDot:    CALL    o_inmsg             ; show a dot for no flag             
            db      '. ',0
            RETURN
; -------------------------------------------------------------------
errmsg:     db      'Cannot open file.',10,13,0
dot:        db      '.', 0
hidden:     db      'h', 0
exec:       db      'x', 0
dir:        db      'd', 0

fildes:     db      0,0,0,0
            dw      dta
            db      0,0
flags:      db      0
sector:     db      0,0,0,0
offset:     dw      0,0
            db      0,0,0,0
           
buffer:    db      0,0,0,0                 ; 2 char hex value           
endrom:    equ     $
; -------------------------------------------------------------------
dta:       ds      512
secbuf:    dw      512
