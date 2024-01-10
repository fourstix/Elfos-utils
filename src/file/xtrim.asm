; -------------------------------------------------------------------
; Truncate an executable file to it's runtime size. Used to remove
; padding bytes added by XMODEM transfer.  Trimmed file has the 
; .tr extension added.
;
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


d_dirent:   equ    037Bh


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
date:       db      80H+1           ; Month, 80H offset means extended info
            db       1              ; Day
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
          
            CALL    o_inmsg           ; otherwise display usage information
            db      'Usage: xtrim filename, where filename is an executable file.',10,13,0
            CALL    o_inmsg
            db      'Trim an executable file to header size and save with .tr extension.',10,13,0
            return                    ; and return to os
            
good:       LOAD    rf, source        ; point to source filename
good1:      lda     ra                ; get byte from argument
            plo     re                ; save for a moment
            smi     '!'               ; check for space or less
            lbnf    good2             ; jump if termination of filename found
            glo     re                ; recover byte
            str     rf                ; write to source buffer
            inc     rf
            lbr     good1             ; loop back for more characters
good2:      ldi     0                 ; need to write terminator
            str     rf                ; source filename is now complete
            
            LOAD    rf, source        ; move back to point to source                                  
            LOAD    rd, dest          ; point to destination filename
            
            lda     rf                ; get the first character of filename
copy:       str     rd                ; save character in destination filename
            inc     rd
            lda     rf                ; get next character
            lbnz    copy              ; copy up to zero at the end
            ldi     '.'               ; add extension '.tr' to destination name
            str     rd
            inc     rd
            ldi     't'
            str     rd
            inc     rd
            ldi     'r'
            str     rd
            inc     rd
            ldi     0                 ; end name string with a null
            str     rd

            ; Set the allocation low memory value to $3000 to prevent
            ; programs from allocating down into program buffers.           
            
            LOAD    rf, k_lowmem      ; Point RF to lowmem location in kernel
 
            ldi     30h               ; load lowmem with floor of $6000
            str     rf                ; Elf/OS will not allocate a block
            inc     rf                ; of memory below this floor value
            ldi     00h 
            str     rf

            ;---- check for executable file
            LOAD    rf, source        ; point to source filename
            call    d_dirent            ; get the directory entry  
            lbnf    dirent              ; jump if directory entry open

            LOAD    rf, errmsg          ; show error message
            CALL    o_msg
            ABEND                       ; exit with error
            
dirent:     glo     ra                  ; ra points to dirent
            adi      6                  ; flags byte is byte 6 in Dirent
            plo     ra
            ghi     ra                  ; add carry flag to high byte
            adci     0                    
            phi     ra                  ; rd now points to flag byte
            
            ldn     ra                  ; get flags from dirent
            ani     02h                 ; check directory bit

            lbnz    open_src
            LOAD    rf, errmsg3       ; show error message
            CALL    o_msg
            ABEND                     ; exit with error

open_src:   LOAD    rf, source        ; point to source filename
            LOAD    rd, fildes        ; get file descriptor
            ldi     0                 ; flags for open
            plo     r7
    
            CALL    o_open            ; attempt to open file          
            lbnf    opened1            ; jump if file was opened
  
            LOAD    rf, errmsg        ; get error message
            CALL    o_msg             ; display it
            ABEND                     ; and return to os with error


opened1:    LOAD    rf, dest          ; point to destination filename
                      
            LOAD    rd, dfildes       ; get file descriptor
            ldi     11                ; flags for open, executable, create if nonexist
            plo     r7
            CALL    o_open            ; attempt to open file
            lbnf    opened2

            LOAD    rf, errmsg2       ; point to error message
            CALL    o_msg             ; and display it
            ABEND
            
opened2:    LOAD    rc, 6             ; want to read 6 bytes
            LOAD    rf, header        ; buffer to for header
            LOAD    rd, fildes        ; get file descriptor
            CALL    o_read            ; read the header
            lbdf    showerr           ; DF = 1 means read error

            LOAD    rf, header        ; buffer to retrieve data
            LOAD    rd, dfildes       ; get file descriptor
            CALL    o_write           ; write to destination file
            lbdf    showerr           ; DF = 1 means write error
            
            LOAD    rf, header        ; point rf at header
            inc     rf
            inc     rf                ; point rf at size 
            lda     rf                ; get size 
            phi     rc
            ldn     rf                ; put size in rc
            plo     rc

            LOAD    r7, 00H           ; no alignment, temporary allocation  
  
            CALL    o_alloc           ; allocate a block of memory
            lbdf    bad_blk           ; DF = 1 means allocation failed  
            
            COPY    rf, r8            ; save copy of buffer pointer
            LOAD    rd, fildes        ; get source file descriptor
            CALL    o_read            ; read the header    
            lbdf    showerr
          
            COPY    r8, rf            ; set rf to point back to buffer
            LOAD    rd, dfildes       ; get destination file descriptor
            CALL    o_write           ; write to destination file
            lbnf    done              ; finished if no errors

showerr:    CALL    o_inmsg           ; otherwise display error
            db      'File write error',10,13,0
            lbr     done  
            
bad_blk:    CALL    o_inmsg           ; otherwise display error
            db      'Allocation failed.',13,10,0
            lbr     done 
                            
done:       LOAD    rd, fildes        ; get source file descriptor
            CALL    o_close           ; close the source file

            LOAD    rd, dfildes       ; get detination file descriptor
            CALL    o_close           ; and close destination file
            RETURN                    ; return to os

           

errmsg:     db      'File not found',10,13,0
errmsg2:    db      'Could not open destination',10,13,0
errmsg3:    db      'Not an executable file',10,13,0
fildes:     db      0,0,0,0
            dw      dta
            db      0,0
flags:      db      0
            db      0,0,0,0
            dw      0,0
            db      0,0,0,0
dfildes:    db      0,0,0,0
            dw      ddta
            db      0,0
            db      0
            db      0,0,0,0
            dw      0,0
            db      0,0,0,0

header:     db      0,0,0,0,0,0

endrom:     equ     $

source:     ds      256
dest:       ds      256
dta:        ds      512
ddta:       ds      512
buffer:     db      0
