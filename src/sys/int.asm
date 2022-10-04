; -------------------------------------------------------------------
; Simple program to show the status of the IE flag.
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

#include ops.inc
#include bios.inc
#include kernel.inc

; ************************************************************
; ***** This block generates the 6 byte Execution header *****
; ************************************************************
; The Execution header starts 6 bytes before the program start
      org     02000h-6          ; Header starts at 01ffah
        dw      02000h          ; Program load address
        dw      endrom-2000h    ; Program size
        dw      02000h          ; Program execution address

      org     2000h             ; Program code begins here
        br      start           ; Jump past build information

        ; Build date
date:   db      80H + 5         ; Month 80H offset means extended info
        db      25              ; Day
        dw      2022            ; Year

        ; Current build number
build:  dw      5

        ; Must end with 0 (null)

        db      'Copyright 2022 by Gaston Williams',0

start:    lda     ra              ; process arguments      
          smi     ' '
          bz      start         ; move past any spaces in argument
          dec     ra              ; move back to non-space character
          LDA     ra              ; check for nonzero byte
          lbz     status         ; jump to default action to show status
                  
          smi     '-'             ; check for argument switch
          lbnz    bad_arg         ; anything else is a bad argument
                  
          ldn     ra              ; check for option d 
          smi     'd'             ; to disable interrupts
          bz      int_off
                  
          smi     1               ; check for option e ('e' - 'd' = 1)
          bz      int_on          ; to enable interrupts
                  
bad_arg:  mov     rf, usage       ; anything else is a bad argument
          CALL    o_msg           ; show usage message
          mov     rf, info1       
          CALL    o_msg
          mov     rf, info2       
          CALL    o_msg
          mov     rf, info3       
          CALL    o_msg
          lbr     done
          
int_on:   sex     r3              ; x = p for ret instruction
          ret                     ; Turn interrupts on
          db      23H             ; with x=2, p=3
          lbr     status
          
int_off:  sex     r3              ; x = p for dis instruction
          dis                     ; Turn interrupts off
          db      23H             ; with x=2, p=3          
            
status:   CALL    o_inmsg         ; status message
          db      'Interrupts ', 0      
          ldi     0FFh            ; load true value as default
          lsie                    ; only instruction that checks IE flag!             
          ldi     00h             ; D = false, skipped over if IE true
          lbnz    ie_on           ; show enabled message if true
          CALL    o_inmsg         ; IE = 0 message
          db      'disabled. (IE = 0)', 10, 13, 0
          lbr     done                  
ie_on:    CALL   o_inmsg        ; IE = 1 message
          db     'enabled. (IE = 1)', 10, 13, 0
done:     RETURN

usage:    db 'Usage: int [-d|-e]',13,10,0
info1:    db 'Display interrupt status.',13,10,0 
info2:    db 'Use option -d to disable interrupts',13,10,0
info3:    db 'or option -e to enable interrupts.',13,10,0        

        ;------ define end of execution block
endrom: equ     $
