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

d_dirent:   equ    037Bh

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
            db      1              ; Day
            dw      2024           ; year
           
            ; Current build number
build:      dw      8              ; build

            ; Must end with 0 (null)
            db      'Copyright 2024 Gaston Williams',0

start:      lda     ra                  ; move past any spaces
            smi     ' '
            lbz     start
            dec     ra                  ; move back to non-space character
            ghi     ra                  ; copy argument address to rf
            ldn     ra                  ; get byte
            lbnz    start1              ; jump if argument given
            CALL    o_inmsg             ; otherwise display usage message
            db      'Usage: flags filename',10,13,0
            RETURN                      ; Return to Elf/OS
           
start1:     COPY    ra, rf              ; copy file string address to rf
loop1:      lda     ra                  ; look for first less <= space
            smi     33
            lbdf    loop1
            dec     ra                  ; backup to previous char
            dec     ra                  ; back up to trailing character
            lda     ra                  ; check for trailing slash
            smi     '/'                 ; remove trailing slash for dir file name
            lbnz    end_ln              ; any other character is okay
            dec     ra                  ; move back one character             
end_ln:     ldi     0                   ; need proper termination for string
            str     ra
            
            call    d_dirent            ; get the directory entry  
            lbnf    dirent              ; jump if directory entry open

            LOAD    rf, errmsg          ; point to error message
            CALL    o_msg               ; display no message
            abend                       ; Return to Elf/OS with error
            
dirent:     glo     ra                  ; ra points to dirent
            adi      6                  ; flags byte is byte 6 in Dirent
            plo     rd
            ghi     ra                  ; add carry flag to high byte
            adci     0                    
            phi     rd                  ; rd now points to flag byte
            
            ldn     rd                  ; get flags from dirent
            ani     01h                 ; check directory bit
            lbz     ddot                ; show dot if no flag
            CALL    o_inmsg             ; show d for a directory
            db      'd ',0
            lbr     checkx           

ddot:       CALL    ShowDot             ; show dot for no flag

checkx:     ldn     rd                  ; get flags byte from dirent
            ani     02h                 ; check executable bit
            lbz     xdot                ; show dot if no flag bit 
            CALL    o_inmsg             ; show x for a executable
            db      'x ', 0
            lbr     checkh              ; check hidden bit in directory entry

xdot:       CALL    ShowDot             ; show dot for no flag

checkh:     ldn     rd                  ; get flags byte from dirent
            ani     08h                 ; check hidden bit
            lbz     hdot                ; show dot if no flag bit
            CALL    o_inmsg             ; show h for hidden file
            db      'h ',0
            lbr     checkw
              
hdot:       CALL    ShowDot             ; show dot for no flag
  
checkw:     ldn     rd                  ; get flags byte from dirent
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
endrom:    equ     $
