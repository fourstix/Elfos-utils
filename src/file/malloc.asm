; *******************************************************************************************
; malloc - Allocate a block of memory on the heap for testing low memory conditions.
; Copyright (c) 2021 by Gaston Williams
; *******************************************************************************************

#include ops.inc
#include bios.inc
#include kernel.inc
                                                 
; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
              ORG     02000h-6  ; Header starts at 01ffah
          dw  02000h            ; Program load address
          dw  endrom-2000h      ; Program size
          dw  02000h            ; Program execution address

              ORG     02000h    ; code starts here
          br  start             ; Jump past build info to code

; Build information
binfo:    db  80H+9             ; Month, 80H offset means extended info
          db  22                ; Day
          dw  2021              ; Year

          ; Current build number
build:    dw  5

          ; Must end with 0 (null)
          db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:    lda     ra          ; move past any spaces
          smi     ' '
          lbz     start
          dec     ra          ; move back to non-space character
          ldn     ra          ; check for nonzero byte
          lbnz    good        ; jump if non-zero
          lbr     usage       ; no size or opt, show usage message                    
       
good:     smi     '-'         ; was it a dash to indicate option?
          lbnz    getsize     ; if not a dash, get size

          inc     ra          ; move to next character
          lda     ra          ; check for fill option 
          smi     'f'
          lbnz    usage       ; bad option, show usage message
       
sp_1:     lda     ra          ; move past any spaces
          smi     ' '
          lbz     sp_1        
            
          dec     ra          ; back up to non-space character
          ldn     ra          ; check for nonzero byte
          lbz     usage       ; show message if end of string
          
          LOAD    rf, fill    ; set flag to fill memory block
          ldi     0FFh        
          str     rf          

            
          COPY    ra, rf      ; point rf to hex value in argument string        
          CALL    f_hexin     ; convert input to hex value
     
          
          COPY    rf, ra      ; point ra to end of hex value in argument string

          LOAD    rf, padding ; point rf to the padding value
          glo     rd          ; get the hexadecimal byte value
          str     rf          ; put in the padding value
                    
sp_2:     lda     ra          ; move past any spaces
          smi     ' '
          lbz     sp_2
          
          dec     ra          ; back up to non-space character
          ldn     ra          ; check for zero
          lbz     usage       ; missing size, show usage message

getsize:  COPY    ra, rf      ; copy argument address to rf
          CALL    f_atoi      ; convert input to integer value
  
          COPY    rd, rc      ; RD contains the block size in bytes
                              ; Move size into RC for allocate load block size
           
          LOAD    r7, 0004H   ; no alignment, permanent allocation 
  
          CALL    o_alloc     ; allocate a block of memory     
          lbdf    bad_blk     ; DF = 1 means allocation failed

          
          COPY    rf, rd      ; point rd to block, rc contains size
          
          LOAD    rf, fill    ; check fill byte
          lda     rf          ; get fill flag, advance pointer to padding byte
          lbz     goodbye     ; if no fill, then we are done 
          
fillmem:  ldn     rf          ; get the padding byte 
          str     rd          ; put into memory block 
          inc     rd          ; advance to next byte 
          dec     rc          ; bump counter 
          ghi     rc          ; check high byte of counter 
          lbnz    fillmem     ; repeat if not zero
          glo     rc          ; check low byte
          lbnz    fillmem     ; repeat until count is zero
          lbr     goodbye     ; Once block is filled, we are done 
          
bad_blk:  CALL    o_inmsg     ; display test message
          db      'Allocation failed.',13,10,0
          lbr     goodbye

usage:    CALL    o_inmsg     ; display usage information
          db      'Usage: malloc [-f hh] <size>, allocate a memory block of <size> oon the heap.',13,10,0
          CALL    o_inmsg
          db      'Option: -f hh, fill memory block with byte hh',13,10,0
          ; falls through to exit 
          
goodbye:  lbr     o_wrmboot   ; return to Elf/OS       
;----------------------------------------------------------------------------------------
fill:     db 0
padding:  db 0                    

; define end of execution block
endrom:   EQU     $
