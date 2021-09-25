; -------------------------------------------------------------------
; Show the execution header information for a file
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
date:       db      80H+9           ; Month, 80H offset means extended info
            db      23              ; Day
            dw      2021            ; Year

      ; Current build number
build:      dw      5

      ; Must end with 0 (null)
            db      'Copyright 2021 Gaston Williams',0

start:      lda     ra                ; move past any spaces
            smi     ' '
            lbz     start
            
            dec     ra                ; move back to non-space character
            ldn     ra                ; get character
            lbnz    good              ; jump if non-zero
          
            CALL    o_inmsg           ; otherwise display usage information
            db      'Usage: header filename, where filename is an executable file.',10,13,0
            lbr     goodbye           ; and return to os
            
good:       COPY    ra, rf        ; point to source filename
            LOAD    rd, fildes        ; get file descriptor
            ldi     0                 ; flags for open
            plo     r7
    
            CALL    o_open            ; attempt to open file          
            lbnf    opened            ; jump if file was opened
  
            LOAD    rf, errmsg        ; get error message
            CALL    o_msg             ; display it
            lbr     goodbye           ; and return to os

opened:     LOAD    rf, flags         ; check for executable
            ldn     rf                ; get the flag byte from file descriptor
            ani     040h              ; Test executable bit is set
            lbnz    read_hdr          ; if executable file, continue on
            
            CALL    o_inmsg           ; Warn if not executable
            db      'Non-executable file may not have a valid header.',13,10,0
                        
            
read_hdr:   LOAD    rc, 6             ; want to read 6 bytes
            LOAD    rf, header        ; buffer to for header
            LOAD    rd, fildes        ; get file descriptor
            CALL    o_read            ; read the header
            lbdf    showerr           ; DF = 1 means read error
            CALL    o_close           ; close files after reading header bytes
          
            LOAD    rf, header        ; point rf at header
            lda     rf                ; get hi byte of load address
            phi     rd                ; store in rd
            lda     rf                ; get lo byte of load address
            plo     rd                ; store in rd
            PUSH    rf                ; save rf for next address
            
            LOAD    rf, buffer        ; point to buffer for hex conversion
            CALL    f_hexout4         ; convert to hex string
            
            LOAD    rf, load_msg      ; show load address
            CALL    o_msg 
            LOAD    rf, buffer        ; show hex value 
            CALL    o_msg 
            LOAD    rf, crlf          ; next line 
            CALL    o_msg 
            
            POP     rf                ; get pointer into header
                                   
            lda     rf                ; get hi byte of progrm size
            phi     rd                ; store in rd
            lda     rf                ; get lo byte of load address
            plo     rd                ; store in rd
            PUSH    rf                ; save rf for next address
            
            LOAD    rf, buffer        ; point to buffer for hex conversion
            CALL    f_hexout4         ; convert to hex string
            
            LOAD    rf, size_msg      ; show program size
            CALL    o_msg 
            LOAD    rf, buffer        ; show hex value 
            CALL    o_msg 
            LOAD    rf, crlf          ; next line 
            CALL    o_msg 

            POP     rf                ; get pointer into header
                                   
            lda     rf                ; get hi byte of program execution address
            phi     rd                ; store in rd
            lda     rf                ; get lo byte of program execution address
            plo     rd                ; store in rd
            
            LOAD    rf, buffer        ; point to buffer for hex conversion
            CALL    f_hexout4         ; convert to hex string
            
            LOAD    rf, exec_msg      ; show program execution address
            CALL    o_msg 
            LOAD    rf, buffer        ; show hex value 
            CALL    o_msg 
            LOAD    rf, crlf          ; next line 
            CALL    o_msg 
            
            RETURN                    ; finished if no errors

showerr:    CALL    o_inmsg           ; otherwise display error
            db      'File write error',10,13,0
goodbye:    lbr     o_wrmboot  
            
; -------------------------------------------------------------------          
errmsg:     db      'File not found',10,13,0
load_msg:   db      'Program Load address: ',0
size_msg:   db      'Program Size: ',0
exec_msg:   db      'Program Execution address: ',0
crlf:       db      13,10,0

fildes:     db      0,0,0,0
            dw      dta
            db      0,0
flags:      db      0
            db      0,0,0,0
            dw      0,0
            db      0,0,0,0

header:     db      0,0,0,0,0,0
buffer:     db      0,0,0,0,0                 ; 4 char hex value

;------ define end of execution block
endrom:     equ     $
dta:        ds      512
