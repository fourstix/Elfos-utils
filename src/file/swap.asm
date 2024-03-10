; -------------------------------------------------------------------
; Display a prompt to change the disk and then boot the new disk
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

#include ops.inc
#include bios.inc
#include kernel.inc

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
      org     02000h-6          ; Header starts at 01ffah
          dw      02000h          ; Program load address
          dw      endrom-2000h    ; Program size
          dw      02000h          ; Program execution address

      org     02000h              ; Program code starts here
          br      start           ; Jump past build information

          ; Build information
          ever

          ; Must end with 0 (null)
          db      'Copyright 2024 Gaston Williams',0

start:    LOAD    rf, prompt      ; set rf to default message
                          
chk_arg:  lda     ra              ; process arguments      
          smi     ' '
          bz      chk_arg         ; move past any spaces in argument
          dec     ra              ; move back to non-space character
          LDA     ra              ; check for nonzero byte
          bz      wait4           ; jump to default input on /ef4
          
          smi     '-'             ; check for argument switch
          lbnz    bad_arg         ; anything else is a bad argument
          
          ldn     ra              ; check for option 0 
          smi     '0'             ; to wait for input on serial data
          bz      waits
          
          smi     1               ; check for option 1 ('1' - '0' = 1)
          bz      wait1           ; to wait for input on /ef1
          
          smi     1               ; check for option 2 ('2' - '1' = 1)
          bz      wait2           ; to wait for input of /ef2
          
          smi     1               ; check for option 3 ('3' - '2' = 1)
          bz      wait3           ; to wait for input of /ef4          
          
          smi     1               ; check for option 4 ('4' - '3' = 1)
          bz      wait4           ; to wait for input of /ef4            
          
          lbr     bad_arg         ; anything else is a bad argument

waits:    CALL    O_MSG           ; display prompt
          CALL    O_INPUT         ; wait here for serial input
          br      goodbye         ; boot new card
                   
wait1:    CALL    O_MSG           ; display prompt
          bn1     $               ; wait here for input press on /ef1
          b1      $               ; wait for button up
          br      goodbye         ; boot new card
          
wait2:    CALL    O_MSG           ; display prompt
          bn2     $               ; wait here for input press on /ef2
          b2      $               ; wait for button up
          br      goodbye         ; boot new card
          
wait3:    CALL    O_MSG           ; display prompt
          bn3     $               ; wait here for input press on /ef3
          b3      $               ; wait for button up
          br      goodbye         ; boot new card
          
wait4:    CALL    O_MSG           ; display prompt
          bn4     $               ; wait here for input press on /ef4                                  
          b4      $               ; wait for button up
          
          ; exit point for new card
goodbye:  lbr     O_CLDBOOT       ; boot Elf/OS on new card

        
bad_arg:  LOAD    rf, usage       ; show usage text and exit
          CALL    O_MSG           
          LOAD    rf, info1
          CALL    O_MSG        
          LOAD    rf, info2
          CALL    O_MSG 
          LOAD    rf, info3
          CALL    O_MSG 
          LOAD    rf, info4
          CALL    O_MSG                     
          RETURN                  ; return to Elf/OS
        
prompt:   db 'Change disk and press Input to boot new disk...',13,10,0       
usage:    db 'Usage: swap [-0|-1|-2|-3|-4, default = -4]',13,10,0
info1:    db 'Display a message to swap disks and wait for input to boot new disk.',13,10,0 
info2:    db 'Use option -1,-2,-3 or -4 to wait for /EFn line input.',13,10,0 
info3:    db 'Use option -0 to wait for serial input.',13,10,0 
info4:    db 'Waiting for input on the /EF4 line is the default.',13,10,0    
        ;------ define end of execution block
endrom: equ     $
