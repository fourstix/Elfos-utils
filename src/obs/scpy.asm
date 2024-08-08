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
      org     02000h-6          ; Header starts at 01ffah
          dw      02000h          ; Program load address
          dw      endrom-2000h    ; Program size
          dw      02000h          ; Program execution address

      org     02000h            ; Program code starts here
          br      start           ; Jump past build information

        ; Build date
date:     db      80H+1           ; Month, 80H offset means extended info
          db      14              ; Day
          dw      2023            ; Year

        ; Current build number
build:    dw      7
        ; Must end with 0 (null)
          db      'Copyright 2021 Gaston Williams',0


start:    ldi     00h                ; set echo flag in r9.0 false initially
          plo     r9

          lda     ra                  ; move past any spaces
          smi     ' '
          lbz     start

          smi     '-'-' '             ; was it a dash to indicate option?
          lbnz    getname             ; if not a dash, check for filename

          lda     ra                  ; check character after dash
          smi     'y'                 ; only option is y for overwrite
          lbnz    usage               ; if not, show bad option message

          LOAD    rf, noprompt        ; point to no prompt flag
          ldi     0ffh                ; set no prompt flag to true 
          str     rf                             

skip_sp:  lda     ra                  ; move past any spaces between option and name
          smi     ' '
          lbz     skip_sp            
getname:  dec     ra                  ; move back to non-space character
          ldn     ra                  ; get character
          lbnz    good                ; jump if non-zero
          
usage:    CALL    o_inmsg             ; display usage message and return
          db      'Usage: scpy [-y] source dest',10,13,0
          CALL    o_inmsg
          db      'Safely copy source file to dest file.',13,10,0
          CALL    o_inmsg
          db      'Option -y will overwrite dest file without a prompt.',13,10,0
          RETURN                      ; and return to os

good:     LOAD    rf,source           ; point to source filename
good1:    lda     ra                  ; get byte from argument
          plo     re                  ; save for a moment
          smi     33                  ; check for space or less
          lbnf    good2               ; jump if termination of filename found
          glo     re                  ; recover byte
          str     rf                  ; write to source buffer
          inc     rf
          lbr     good1               ; loop back for more characters
good2:    ldi     0                   ; need to write terminator
          str     rf                  ; source filename is now complete
          glo     re                  ; recover byte
          lbnz    good3               ; jump if not terminator
          lbr     usage               ; show usage msg and exit 
          
good3:    lda     ra                  ; move past any space
          smi     ' '
          lbz     good3
          dec     ra                  ; move back to non-space character
          ldn     ra                  ; get character
          lbnz    good4               ; jump if not terminator
          lbr     usage               ; show usage msg and exit
          
good4:    LOAD    rf, dest            ; point to destination filename
good5:    lda     ra                  ; get byte from argument
          plo     re                  ; save for a moment
          smi     33                  ; check for space or less
          lbnf    good6               ; jump if terminator
          glo     re                  ; recover byte
          str     rf                  ; store into buffer
          inc     rf
          lbr     good5               ; loop back to copy rest of name
good6:    ldi     0                   ; need terminator
          str     rf
    
          LOAD    rf, source          ; point to source filename
          LOAD    rd, fildes          ; get file descriptor
          ldi     0                   ; flags for open
          plo     r7

          CALL    o_open              ; attempt to open file
          lbnf    opened              ; jump if file was opened

          CALL    o_inmsg
          db      'File not found',10,13,0
          lbr     err_exit            ; and return to os

opened:   LOAD    rf, flags           ; check for directory
          ldn     rf                  ; get flag byte from fildes 
          ani     20h                 ; check if directory bit set
          lbz     cont                ; continue if not a directory            

          CALL    o_inmsg             ; otherwise show error message          
          db      'Source cannot be a directory.',10,13,0 

          CALL    o_close             ; close source file and exit
          lbr     err_exit            ; and exit
             
cont:     COPY    rd, r7              ; make copy of descriptor

          LOAD    rf, dest            ; point to destination filename
          LOAD    rd, dfildes         ; get destination file descriptor
          PUSH    r7                  ; save first descriptor
          LOAD    r7, 0h              ; flags for open, don't create

          CALL    o_open              ; attempt to open file       
          lbdf    reopen              ; DF = 1 -> no such file, reopen to create

          LOAD    rf, dflags          ; check destination flags  
          ldn     rf                  ; get the destination flag byte
          ani     20h                 ; check if directory bit set
          lbz     dupe                ; if not ask before overwriting 

          CALL    o_inmsg             ; show directory error message
          db      'Destination cannot be a directory.',10,13,0
          lbr     abend               ; close files and exit
          
dupe:     LOAD    rf, noprompt        ; get no prompt flag
          ldn     rf
          lbnz    reopen              ; if true continue without asking
          
          CALL    o_inmsg             ; display prompt
          db      'Overwrite? (y/n)',10,13,0
          
          LOAD    rf, buffer 
          CALL    o_input             ; get response
          
          LOAD    rf, buffer          ; check response             
          ldn     rf                  ; Is first character 'y' or not?
          smi     'Y'                 ; 'Y' is a positive response
          lbz     reopen              ; reopen file if positive response
          smi     20h                 ; 'y' is 32 less than 'Y' 
          lbz     reopen              ; reopen if positive, otherwise quit

abend:    CALL    o_close             ; close destination
          POP     rd                  ; recover source descriptor
          CALL    o_close             ; close source
err_exit: ldi     0ffh                ; set retval for error code
          shl                         ; set df true for error
          RETURN                      ; exit to Elf/OS (DF = 1, D = FE)

reopen:   CALL    o_close             ; close and reopen file to overwrite                        

create:   LOAD    rf, dest            ; point to destination filename
          LOAD    r7, 03h             ; flags for truncate, create if non-exist

          CALL    o_open              ; attempt to open file           
          lbnf    opened2             ; file open for copy

          CALL    o_inmsg             ; display to error message
          db      'Could not open destination',10,13,0
          lbr     abend               ; close files and exit
          
opened2:  POP     r7                  ; recover first descriptor
          COPY    rd, r8              ; make copy of descriptor

mainlp:   LOAD    rc, 255             ; want to read 255 bytes
          LOAD    rf, buffer          ; buffer to retrieve data
          COPY    r7, rd              ; get descriptor
          
          CALL    o_read              ; read the header
          lbnf    readgd
          CALL    o_inmsg             ; display error on reading
          db      'File read error',10,13,0
          lbr     done                ; return to OS
          
readgd:   glo     rc                  ; check for zero bytes read
          lbz     done                ; jump if so
          LOAD    rf, buffer          ; buffer to rettrieve data
          COPY    r8, rd              ; get descriptor

          CALL    o_write             ; write to destination file
          lbnf    mainlp              ; loop back if no errors

          CALL    o_inmsg             ; otherwise display error
          db      'File write error',10,13,0
          
done:     CALL    o_close             ; close the file
          COPY    r8, rd              ; get destination descriptor
          CALL    o_close             ; and close it
          RETURN                      ; exit to Elf/OS
          
noprompt: db      0,0                 ; no prompt flag

fildes:   db      0,0,0,0
          dw      dta
          db      0,0
flags:    db      0
          db      0,0,0,0
          dw      0,0
          db      0,0,0,0

dfildes:  db      0,0,0,0
          dw      ddta
          db      0,0
dflags:   db      0
          db      0,0,0,0
          dw      0,0
          db      0,0,0,0

endrom:   equ     $

source:   ds      256
dest:     ds      256
dta:      ds      512
ddta:     ds      512
buffer:   db      0
