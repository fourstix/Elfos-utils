; CMD - a simple command file interpreter
; Copyright 2021 by Gaston Williams
;
; Based on the Init v5 program written by David S. Madole
; Original author's copyright statement from Init v5:
;
; This software is copyright 2021 by David S. Madole.
; You have permission to use, modify, copy, and distribute
; this software so long as this copyright notice is retained.
; This software may not be used in commercial applications
; without express written permission from the author.
;
; The author grants a license to Michael H. Riley to use this
; code for any purpose he sees fit, including commercial use,
; and without any need to include the above notice.


           ; Include bios ad kernel API
           include bios.inc
           include kernel.inc

           ; Define internal kernel AP
d_reapheap equ 044dh
d_progend  equ 0450h
d_lowmem   equ 0465h

           ; Program header to start at $5000

           org     5000h - 6
           dw      start
           dw      end-start
           dw      start

start:     org     5000h
           br      main

           ; Build information

           db      8+80h              ; month
           db      18                 ; day
           dw      2021               ; year
           dw      4                  ; build
text:      db      'Copyright 2021 Gaston Williams',0

           ; If Input button is pressed when run, skip execution
main:      bn4     chk_os
           sep     scall              ; autobaud is needed in case of init
           dw      o_setbd            ; otherwise we might get stuck after reboot
           
           lbr     goodbye            ; exit program

           ; verify elf/os kernel version before executing
chk_os:    ldi     high k_ver         ; get pointer to kernel version
           phi     rf
           ldi     low k_ver
           plo     rf

           lda     rf                 ; if major is non-zero we are good
           lbnz    setup

           lda     rf                 ; if major is zero and minor is 4
           smi     4                  ;  or higher we are good
           lbdf    setup

           lbr     badkrnl            ; show msg and exit


setup:     ldi     00h                ; set echo flag in r9.0 false initially
           plo     r9
           ldi     fd.1               ; get file descriptor
           phi     rd
           ldi     fd.0
           plo     rd

           ldi     0                  ; no flags for open
           plo     r7

           ; get the file name if one was entered
getparam:  lda     ra                  ; move past any spaces
           smi     ' '                 ; d = char - space
           lbz     getparam
                              
           smi     '-'-' '             ; was it a dash to indicate option?
           lbnz    getname             ; if not a dash, check for filename

           lda     ra                  ; check character after dash
           smi     'e'                 ; only option is e for echo
           lbnz    badopt              ; if not, show bad option message

           ldi     0ffh                ; set echo flag in r9.0 to true 
           plo     r9                             
          
skip_sp:   lda     ra                  ; move past any spaces between option and name
           smi     ' '
           lbz     skip_sp       
                                                  
getname:   dec     ra                  ; move back to non-space character
           ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldn     rf                  ; get byte from argument
           lbnz    openfile            ; jump if filename given
           
           ; othrewise use default name instead            
usedeflt:  ldi     default.1
           phi     ra
           ldi     default.0
           plo     ra

           glo     ra                 ; remember start of name
           plo     rf
           ghi     ra
           phi     rf

           ; Open file for input and read data

openfile:  sep     scall              ; open file
           dw      o_open
           lbdf    notfound

           ldi     buffer.1           ; pointer to data buffer
           phi     rf
           ldi     buffer.0
           plo     rf

           ldi     2048.1             ; file length to read
           phi     rc
           ldi     2048.0
           plo     rc

           sep     scall              ; read from file
           dw      o_read

           sep     scall              ; close file when done
           dw      o_close

           ; Set the allocation low memory value to $6000 to prevent
           ; programs from allocating down to the loader buffer.           
           
           ldi     d_lowmem.1       ; Point RD to lowmem location in kernel
           phi     rd
           ldi     d_lowmem.0
           plo     rd

           ldi     60h              ; load lowmem with floor of $6000
           str     rd               ; Elf/OS will not allocate a block
           inc     rd               ; of memory below this floor value
           ldi     00h 
           str    rd

           ; We need to intercept the kernel o_wrmboot d_progend return vector
           ; because that is the recommended way for programs to return to
           ; Elf/OS, and apparently many do so. So we save what's there now,
           ; replace it with our own handler, then restore later.

           ldi     d_progend.1        ; pointer to o_wrmboot return return vector
           phi     rd
           ldi     d_progend.0
           plo     rd

           inc     rd                 ; skip lbr instruction

           ldi     warmretn.1         ; pointer to save o_wrmboot return vector
           phi     rf
           ldi     warmretn.0
           plo     rf

           ldn     rd                 ; save o_wrmboot return vector high byte
           str     rf

           ldi     execgood.1         ; replace o_wrmboot return vector high byte
           str     rd

           inc     rd                 ; switch to low bytes
           inc     rf

           ldn     rd                 ; save o_wrmboot return vector low byte
           str     rf

           ldi     execgood.0         ; replace o_wrmboot return vector low byte
           str     rd

           ; Now process the input file which has been read into memory
           ; one line at a time, executing each line as a command line
           ; including any arguments provided. This looks in the current
           ; directory and then in bin directory if not found.

           ldi     buffer.1           ; reset buffer to beginning of input
           phi     rf
           ldi     buffer.0
           plo     rf

           ghi     rc                 ; has the length of data to process,
           adi     1                  ; adjust it so that we can just test
           phi     rc                 ; the high byte for end of input

           ; From here is where we repeatedly loop back for input lines and
           ; process each as a command line.

getline:   dec     rc                 ; if at end of input, then quit
           ghi     rc
           lbz     endfile

           lda     rf                 ; otherwise, skip any whitespace
           smi     '!'                ; leading the command line
           lbnf    getline

           inc     rc                 ; back up to first non-whitespace
           dec     rf                 ; characters of command

           ghi     rf                 ; make two copies of pointer to
           phi     ra                 ; command line
           phi     rb
           glo     rf
           plo     ra
           plo     rb

scanline:  dec     rc                 ; if at end of input, then quit
           ghi     rc
           lbz     endfile

           lda     ra                 ; otherwise, skip to first control
           smi     ' '                ; characters after command
           lbdf    scanline

           dec     ra                 ; back up to first control character
           ldi     0                  ; and overwrite with zero byte, then
           str     ra                 ; advance again
           inc     ra

           ; check for echo
           glo     r9                 ; check echo flag
           lbz     noecho
                    
           sep     scall              ; rf already points to command string
           dw      o_msg
           ldi     crlf.1             ; go to next line after command 
           phi     rf                 
           ldi     crlf.0
           plo     rf
           sep     scall
           dw      o_msg
           
noecho:    ldi     warmretn.1         ; pointer to save registers
           phi     rd                 ; in area below warmretn
           ldi     warmretn.0
           plo     rd
           dec     rd                 ; point to end of inp_stck
           sex     rd                 ; set stack pointer to local stack
           
           glo     ra                 ; save pointer to next input to process
           stxd                       ; as well as length of input remaining
           ghi     ra                 ; since executing the program may wipe
           stxd                       ; out all register contents as o_exec
           glo     rc                 ; does not preserve register values as
           stxd                       ; most elf/os calls do
           ghi     rc
           stxd      
           glo     r9                 ; save flag byte in stack
           stxd    
           sex     r2                 ; set stack pointer back to system stack
           
           ldi     filepath.1         ; make a copy of the command line
           phi     rd                 ; concatenated to the static string
           ldi     filepath.0         ; /bin/ so that we can try that if
           plo     rd                 ; program not found in current directory

strcpy:    lda     rb                 ; the copy is needed not just to prepend
           str     rd                 ; /bin/ but also because o_exec modifies
           inc     rd                 ; the string it is passed in-place so
           lbnz    strcpy             ; we can't reuse it

           sep     scall              ; try executing the plain command line
           dw      o_exec
           lbnf    execgood

           ldi     binpath.1          ; if unsuccessful, reset pointer to the
           phi     rf                 ; copy with /bin/ prepended
           ldi     binpath.0
           plo     rf
 
           sep     scall              ; and then try that one
           dw      o_exec
           lbdf    execfail

           ; If the executed program ends with lbr o_wrmboot instead of sep sret
           ; then control will also come here. 

execgood:  ldi     crlf.1             ; if exec is succesful, output a blank
           phi     rf                 ; line to separate output
           ldi     crlf.0
           plo     rf

           sep     scall
           dw      o_msg

execfail:  sep     scall
           dw      d_reapheap

           ldi     inp_stck.1         ; pointer to restore registers
           phi     rd                 ; set to bottom of stack
           ldi     inp_stck.0
           plo     rd
           sex     rd                 ; set stack to point to local stack
           
           ldxa                       ; restore flag byte in r9.0
           plo     r9
           ldxa                       ; restore the length of the input
           phi     rc
           ldxa                       
           plo     rc
           ldxa
           phi     rf                 ; and retore the pointer to the input
           ldxa                       ; note it is put into rf which 
           plo     rf                 ; is copied to ra later 
           
           sex     r2                 ; set the stack back to system stack
           lbr     getline            ; go find next line to process

           ; Before we exit, we need to restore the original value of 
           ; o_wrmboot which we replaced earlier to point to our own
           ; return handling code.

endfile:   ldi     d_progend.1        ; pointer to o_wrmboot return vector
           phi     rd
           ldi     d_progend.0
           plo     rd
           inc     rd                 ; skip lbr instruction

           ldi     warmretn.1         ; point to saved local copy of original 
           phi     rf                 ; o_wrmboot return vector
           ldi     warmretn.0
           plo     rf

           lda     rf                 ; restore saved o_wrmboot return vector
           str     rd
           inc     rd
           ldn     rf
           str     rd

           lbr     goodbye            ; exit program
           
           ; line separator
crlf:      db      13,10,0

           ; Error handling follows, mostly these just output a message and
           ; exit, but readfail also closes the input file first since it
           ; would be open at that point.

badkrnl:   ldi     krnlmsg.1   ; if unable to open input file
           phi     rf
           ldi     krnlmsg.0
           plo     rf
           lbr     failmsg            

badopt:    ldi     usagemsg.1   ; if unable to open input file
           phi     rf
           ldi     usagemsg.0
           plo     rf
           lbr     failmsg 
          
notfound:  ldi     openmsg.1   ; if unable to open input file
           phi     rf
           ldi     openmsg.0
           plo     rf
           lbr     failmsg

readfail:  sep     scall        ; if read on input file fails
           dw      o_close

           ldi     readmsg.1
           phi     rf
           ldi     readmsg.0
           plo     rf

failmsg:   sep     scall       ; output the message and return
           dw      o_msg
           
           ; exit point for program
goodbye:   lbr     o_wrmboot   ; return to Elf/OS
           
           ; Error messages
krnlmsg:   db      'Requires Elf/OS v0.4.0 or higher',13,10,0
openmsg:   db      'File not found',13,10,0
readmsg:   db      'Read file failed',13,10,0
usagemsg:  db      'Usage: cmd [-e] [filename, default = start.cmd]',13,10
           db      'Run commands from filename, or start.cmd if not specified',13,10
           db      'Option -e will echo commands before they are executed.',13,10,0    

           ; Default file name
default:   db      'start.cmd',0
          
           ; Include file descriptor in program image so it is initialized.
fd:        db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

           ; This is used to prefix a copy of the path to pass to exec
           ; a second time if the first time fails to find the command in
           ; the current directory.

binpath:   db      '/bin/'    ; needs to be immediately prior to filepath

end:       ; These buffers are not included in the executable image but will
           ; will be in memory immediately following the loaded image.

filepath:  ds      0          ; overlay over dta, not used at same time
dta:       ds      512-5-2    ; likewise, overlay dta and next two variables
inp_stck:  ds      5          ; local stack area for input count and pointer while execing
warmretn:  ds      2          ; place to save the o_wrmboot return vector
buffer:    ds      2048       ; load the input file to memory here
pgmtop:    ds      0          ; highest location in program
