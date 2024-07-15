; -------------------------------------------------------------------
; Truncate a file to remove padding bytes added by XMODEM transfer.  
;
; Copyright 2024 by Gaston Williams
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
    org     02000h-6              ; Header starts at 01ffah
            dw      02000h          ; Program load address
            dw      endrom-2000h    ; Program size
            dw      02000h          ; Program execution address

    org     02000h            ; Program code starts here
            br      start           ; Jump past build information

      ; Build date
date:       db      80H+7           ; Month, 80H offset means extended info
            db      14              ; Day
            dw      2024            ; Year

      ; Current build number
build:      dw      6

      ; Must end with 0 (null)
            db      'Copyright 2024 Gaston Williams',0

start:      lda     ra                ; move past any spaces
            smi     ' '
            lbz     start
            
            dec     ra                ; move back to non-space character
            ldn     ra                ; get character
            lbnz    good              ; jump if non-zero
          
            call    o_inmsg           ; otherwise display usage information
            db      'Usage: xtrunc filename, where filename is an xmodem padded file.',10,13,0
            return                    ; and return to os
            
good:       load    rf, source        ; point to source filename
lp_arg:     lda     ra                ; get byte from argument
            plo     re                ; save for a moment
            smi     '!'               ; check for space or less
            lbnf    chk_file          ; jump if termination of filename found
            glo     re                ; recover byte
            str     rf                ; write to source buffer
            inc     rf
            lbr     lp_arg            ; loop back for more characters
            
chk_file:   ldi     0                 ; need to write terminator
            str     rf                ; source filename is now complete
            
            load    rf, source        ; point to source filename
            load    rd, fildes        ; get file descriptor
            ldi     0                 ; flags for open
            plo     r7
    
            call    o_open            ; attempt to open file          
            lbnf    chk_size          ; if file was opened, check its size
  
            load    rf, errmsg1       ; get file not found error message
            call    o_msg             ; display it
            abend                     ; and return to os with error
            
chk_size:   ldi     $00               ; clear out r7, r8               
            plo     r7                ; set seek offset to zero
            phi     r7
            plo     r8
            phi     r8
            phi     rc                ; clear out hi byte of flags 
            ldi     2                 ; flag for EOF
            plo     rc                ; set RC to seek from EOF
            load    rd, fildes        ; set file descriptor for seek
            call    o_seek            ; seek end of file
            lbdf    showerr           ; DF = 1 means seek error

            load    rf, fildes+3      ; first four bytes in fildes is the size
            ldn     rf                ; get low byte of size
            ani     $7F               ; clear out high bit for multiple 128 blocks
            lbnz    not_padded        ; any odd size is not xmodem padded    

            ldi     $80               ; set r8, r7 for -128 bytes               
            plo     r7                ; set seek offset to zero
            ldi     $FF               ; sign extend -128 
            phi     r7
            plo     r8
            phi     r8
            ldi     0
            phi     rc                ; clear out hi byte of flags 
            ldi     2                 ; flag for EOF
            plo     rc                ; set RC to seek from EOF
            load    rd, fildes        ; set file descriptor for seek
            call    o_seek            ; seek end of file minus 128 bytes
            lbdf    showerr           ; DF = 1 means seek error
                        
            load    rc, 128           ; get last block of 128 bytes
            load    rf, buffer        ; buffer for block
            load    rd, fildes        ; get file descriptor
            call    o_read            ; read the header
            lbdf    showerr           ; DF = 1 means read error
            
            glo     rc                ; check count of bytes read
            smi     128               ; should be 128 (one whole xmodem block)
            lbnz    not_padded        ; if unexpected size, like 0, then not padded
            
            load    rf, buffer+127    ; point to end of block buffer
            load    r7, 0             ; clear counter
            
lp_trim:    ldn     rf                ; get byte from block
            dec     rf                ; move backwards in block
            smi     $1A               ; check for xmodem padding character
            lbnz    done_trim         ; 
            dec     r7                ; count down padding characters at end of block
            lbr     lp_trim           ; until non-padding character encountered              
            
done_trim:  ghi     r7                ; check if r7 was not decremented
            lbz     not_padded        ; if not decremented, then no padding was found
            
            ldi     $FF               ; sign extend r7 into r8
            plo     r8
            phi     r8
            ldi     0                 ; clear out rc
            phi     rc
            ldi     2                 ; set to seek from end of file
            plo     rc
                  
            load    rd, fildes        ; set fildes for seek            
            call    o_seek            ; seek to end of file minus N
            lbdf    showerr           ; DF = 1 means seek error
            
            load    rd, fildes        ; set fildes for truncate
            call    o_trunc           ; truncate file to remove padding characters
            ; lbdf    showerr           ; DF = 1 means error

            call    o_inmsg           ; print success message
            db      'File truncated to remove XModem padding.',10,13,0            
            
exit:       load    rd, fildes
            call    o_close
            return
            
            
not_padded: load    rf, errmsg3       ; show not padded error message
            call    o_msg
            lbr     exit

showerr:    load    rf, errmsg2       ; otherwise display error msg
            call    o_msg
            load    rd, fildes        ; attempt to close anyway after file error
            call    o_close
            abend
                        

errmsg1:    db      'File not found.',10,13,0
errmsg2:    db      'A file error occurred.',10,13,0
errmsg3:    db      'No XModem padding found.',10,13,0
fildes:     db      0,0,0,0
            dw      dta
            db      0,0
flags:      db      0
            db      0,0,0,0
            dw      0,0
            db      0,0,0,0
            db      0,0               ; extended fildes
padding:    db      0,0,0,0           ; pad to align buffer boundaries            
endrom:     equ     $

source:     ds      256
dta:        ds      512
buffer:     ds      128
