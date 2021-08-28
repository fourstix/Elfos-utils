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

include    bios.inc
include    kernel.inc

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
date:       db      80H+8           ; Month, 80H offset means extended info
            db      28              ; Day
            dw      2021            ; Year

      ; Current build number
build:      dw      5

      ; Must end with 0 (null)
            db      'Copyright 2021 Gaston Williams',0

start:      ldi     high k_ver          ; get pointer to kernel version
            phi     rf
            ldi     low k_ver
            plo     rf

            lda     rf                  ; if major is non-zero we are good
            lbnz    setup

            lda     rf                  ; if major is zero and minor is 4
            smi     4                   ;  or higher we are good
            lbdf    setup
            
            sep     scall               ; Show bad kernel message and exit
            dw      o_inmsg
            db      'Requires Elf/OS v0.4.0 or higher',13,10,0            
            lbr     goodbye             ; show msg and exit

setup:      lda     ra                  ; move past any spaces
            smi     ' '
            lbz     start
            
            dec     ra                  ; move back to non-space character
            ldn     ra                  ; get character
            lbnz    good                ; jump if non-zero
          
            sep     scall               ; otherwise display usage inforamtion
            dw      o_inmsg
            db      'Usage: xtrim filename, where filename is an executable file.',10,13,0
            sep     scall
            dw      o_inmsg
            db      'Trim an executable file to header size and save with .tr extension.',10,13,0
            lbr     goodbye              ; and return to os
            
good:       mov     rf,source           ; point to source filename
good1:      lda     ra                  ; get byte from argument
            plo     re                  ; save for a moment
            smi     '!'                 ; check for space or less
            lbnf    good2               ; jump if termination of filename found
            glo     re                  ; recover byte
            str     rf                  ; write to source buffer
            inc     rf
            lbr     good1               ; loop back for more characters
good2:      ldi     0                   ; need to write terminator
            str     rf                  ; source filename is now complete
            
            mov     rf,source           ; move back to point to source                                  
            mov     rd,dest             ; point to destination filename
            
            lda     rf                  ; get the first character of filename
copy:       str     rd                  ; save character in destination filename
            inc     rd
            lda     rf                  ; get next character
            lbnz    copy                ; copy up to zero at the end
            ldi     '.'                 ; add extension '.tr' to destination name
            str     rd
            inc     rd
            ldi     't'
            str     rd
            inc     rd
            ldi     'r'
            str     rd
            inc     rd
            ldi     0                   ; end name string with a null
            str     rd

            ; Set the allocation low memory value to $3000 to prevent
            ; programs from allocating down into program buffers.           
            
            mov     rf, k_lowmem        ; Point RF to lowmem location in kernel
 
            ldi     30h                 ; load lowmem with floor of $6000
            str     rf                  ; Elf/OS will not allocate a block
            inc     rf                  ; of memory below this floor value
            ldi     00h 
            str     rf

            mov     rf,source           ; point to source filename
            ldi     high fildes         ; get file descriptor
            phi     rd
            ldi     low fildes
            plo     rd
            ldi     0                   ; flags for open
            plo     r7
            sep     scall               ; attempt to open file
            dw      o_open
            lbnf    opened              ; jump if file was opened
            ldi     high errmsg         ; get error message
            phi     rf
            ldi     low errmsg
            plo     rf
            sep     scall               ; display it
            dw      o_msg
            lbr     goodbye           ; and return to os

opened:     mov     rf,flags            ; check for executable
            ldn     rf                  ; get the flag byte from file descriptor
            ani     040h                ; Test executable bit is set
            lbnz    opendest            ; if executable file, continue on
            
            sep     scall               ; close file
            dw      o_close       
            mov     rf,errmsg3          ; show error message
            sep     scall               
            dw      o_msg
            lbr     goodbye             ; exit
                        
opendest:   mov     rf,dest             ; point to destination filename
                      
            ldi     high dfildes        ; get file descriptor
            phi     rd
            ldi     low dfildes
            plo     rd        
            ldi     11                  ; flags for open, executable, create if nonexist
            plo     r7
            sep     scall               ; attempt to open file
            dw      o_open
            lbnf    opened2
            mov     rf,errmsg2          ; point to error message
            sep     scall               ; and display it
            dw      o_msg
            lbr     goodbye
            
opened2:    ldi     0                   ; want to read 6 bytes
            phi     rc
            ldi     6
            plo     rc 
            mov     rf,header           ; buffer to for header
            ldi     high fildes         ; get file descriptor
            phi     rd
            ldi     low fildes
            plo     rd
            sep     scall               ; read the header
            dw      o_read
            lbdf    showerr             ; DF = 1 means read error

            mov     rf, header          ; buffer to retrieve data
            ldi     high dfildes        ; get file descriptor
            phi     rd
            ldi     low dfildes
            plo     rd
            sep     scall               ; write to destination file
            dw      o_write
            lbdf    showerr             ; DF = 1 means write error
            
            mov     rf, header          ; point rf at header
            inc     rf
            inc     rf                  ; point rf at size 
            lda     rf                  ; get size 
            phi     rc
            ldn     rf                  ; put size in rc
            plo     rc

            ldi     00H                 ; no alignment 
            phi     r7
            ldi     00H                 ; temporary allocation
            plo     r7
  
            sep     scall               ; allocate a block of memory
            dw      o_alloc
            lbdf    bad_blk             ; DF = 1 means allocation failed  
            
            ghi     rf                  ; save copy of buffer pointer
            phi     r8
            glo     rf
            plo     r8
                      
            ldi     high fildes         ; get source file descriptor
            phi     rd
            ldi     low fildes
            plo     rd
            sep     scall               ; read the header
            dw      o_read
            lbdf    showerr
          
            ghi     r8                  ; set rf to point back to buffer
            phi     rf
            glo     r8
            plo     rf
            
            ldi     high dfildes        ; get destination file descriptor
            phi     rd
            ldi     low dfildes
            plo     rd
            sep     scall               ; write to destination file
            dw      o_write
            lbnf    done                ; loop back if no errors

bad_blk:    sep     scall               ; otherwise display error
            dw      o_inmsg
            db      'Allocation failed.',13,10,0
            lbr     done 
            
showerr:    sep     scall               ; otherwise display error
            dw      o_inmsg
            db      'File write error',10,13,0
                
done:       ldi     high fildes         ; get source file descriptor
            phi     rd
            ldi     low fildes
            plo     rd
            sep     scall               ; close the source file
            dw      o_close
            ldi     high dfildes        ; get detination file descriptor
            phi     rd
            ldi     low dfildes
            plo     rd
            sep     scall               ; and close destination file
            dw      o_close
goodbye:    lbr     o_wrmboot           ; return to os

           

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
