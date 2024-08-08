; -------------------------------------------------------------------
; Display matching files in a directory and all its sub-directories.
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

#include ../include/ops.inc
#include ../include/kernel.inc

; **************************
; ***  Elf/OS Constants  ***
; **************************
#define   ELFOS_VERSION     $0400
#define   ERR_BAD_VERSION   $14
#define   ERR_BAD_PATH      $08
#define   ERR_BAD_ARG       $09
#define   ERR_USER_PROGRAM  $FE       ; default program error code (-2)   
     
; **************************
; ***  Program Constants ***
; **************************
#define   E_SIZE            22
#define   MAX_INDEX         254
          
; Mode bits:
;   0 - 0=exact match    
;       1=directories only  -d            
;   1 - 1=inc hidden items -h
;   2 - 1=sort by name      -s 

          org     2000h

          ; **************************
          ; ***  Stdlib functions  ***
          ; **************************
          extrn    buildpath
          extrn    str_strincat
          extrn    str_strcat
          extrn    str_strcmp
          extrn    str_strcasecmp
          extrn    str_strncmp
          extrn    str_strncasecmp
          extrn    str_strcpy
          extrn    str_trim
          extrn    str_strlen
          extrn    str_dtoupper
          extrn    int16_itoa


          ; **************************
          ; ***  Program Buffers   ***
          ; **************************
          extrn    dta
          extrn    fnd_ents
          
          
.link .requires find_buf
.link .requires str_dtoupper

begin:    br      start
          ever
          db      'Copyright 2024 Gaston Williams',0

start:    load    rf, ELFOS_VERSION   ; get Elf/OS version
          ldn     rf
          smi     5                   ; must be version 5 or higher
          lbnf    notv5               ; jump if not

          load    rf,next             ; point to fnd_ents pointer
          load    r7,fnd_ents         ; fnd_ents storage
          ldi     0                   ; terminate list
          str     r7
          ghi     r7                  ; store pointer
          str     rf
          inc     rf
          glo     r7
          str     rf
          call    do_crlf             ; display a cr/lf

          ghi     ra
          phi     rf
          glo     ra
          plo     rf
          ldi     0                   ; clear all modes
          plo     r9
sw_lp:    call    str_trim            ; move past leading whitespace

          ldn     rf                  ; check for switches
          smi     '-'                 ; which begin with -
          lbnz    no_sw               ; jump if no switches

          inc     rf                  ; move to switch char
          lda     rf                  ; retrieve switch
          plo     re                  ; save it
          smi     'i'                 ; check for ignore case 
          lbnz    not_i               ; ignore others

          glo     r9                  ; get modes
          ori     01h                 ; set directory only mode
          plo     r9                  ; and put it back
          lbr     sw_lp               ; loop back for more switches

not_i:    glo     re                  ; recover byte
          smi     'p'                 ; check for partial match
          lbnz    not_p               ; if not, check next valid switch

          glo     r9                  ; get modes
          ori     02h                 ; signal ignore case
          plo     r9
          lbr     sw_lp               ; loop back for more switches
          
not_p:    glo     re                  ; recover byte
          smi     'h'                 ; check for hidden items
          lbnz    usage               ; if not, then invalid switch

          glo     r9                  ; get modes
          ori     04h                 ; signal show hidden files
          plo     r9
          lbr     sw_lp               ; loop back for more switches     
               
usage:    call    o_inmsg
            db    'Usage: find [-i|-p|-h] name [directory, default = current]',10,13
            db    'Search a directory and its sub-directories for matching file names.',10,13
            db    'Options:',10,13
            db    '  -i, ignore case when matching',10,13
            db    '  -p, match name as prefix to file names',10,13
            db    '  -h, include hidden files and directories',10,13,0
          abend                       ; exit with user program error code

no_sw:    load    rb,mode             ; point to modes variable
          glo     r9                  ; get modes
          str     rb                  ; and save them

          call    str_trim            ; move past leading whitespace
          load    rd, target          
cpy_fn:   lda     rf                  ; get next character
          str     rd                  ; copy filename into destination
          inc     rd
          lbz     skp_done            ; if we hit 0, we are done with arguments
          smi     ' '                 ; check for whitespace
          lbnz    cpy_fn              ; keep copying until we hit whitespace
          dec     rd                  ; back up target string
          ldi     0
          str     rd                  ; make sure target ends in null
skip_sp:  lda     rf                  ; move past any spaces between option and name
          smi     ' '
          lbz     skip_sp            
skp_done: dec     rf                  ; back up to non-space character
          
          copy    rf,ra               ; set up to call build path
          load    rf,rpath-1          ; store root path in rpath
          call    buildpath
          
          lbnf    goodpath

          call    o_inmsg
            db      'Invalid path',10,13,0
          abend   ERR_BAD_PATH        ; exit with user program error code

goodpath: load    rd, wpath           ; copy root path into working path
          load    rf, rpath           ; path string one after rpath
          call    str_strcpy          ; copy string to working buffer

          load    rf, target          ; get size of target string
          call    str_strlen          
          load    rf, size            
          glo     rc                  ; get size of string
          str     rf                  ; save size in memory
          
          load    rf, mode            ; get the mode flags 
          ldn     rf 
          plo     rb                  ; save mode in rb.0 for scanning
          
          ldi     1                   ; set up level for parent value
          plo     r7                  ; top level is one

          call    o_inmsg             ; print message
            db 'Scanning.',0

scan:     call    o_inmsg             ; print status
            db '.',0

          load    rf, size            ; get the string size 
          ldn     rf 
          phi     rb                  ; save size in rb.1 for scanning
            
          load    rf, mode            ; get the mode flags 
          ldn     rf 
          plo     rb                  ; save mode in rb.0 for scanning
          call    scandir             ; scan directory
          glo     rc                  ; check error byte in rc.0
          lbnz    bad_exit            ; exit to os with error
        
          ldi     0
          shlc                        ; save DF flag in r7.1
          phi     r7                  ; for fixprnts routine
                                             
          call    fixprnts            ; update parents after scan
          lbnf    cont_scn            ; if no more parents to update, continue scan
          
fix_gp:   call    scanlvl             ; check children of grand-parent
          lbdf    cont_scn            ; if unscanned children, continue scan
                    
          call    fixprnts            ; update grand-parents
          lbdf    fix_gp              ; keep updating up the change      

cont_scn: call    findnext            ; find next directory to scan
          lbdf    scan                

display:  call    do_crlf
          call    do_crlf

          call    cntents
          call    setsum
          
prt_lp:   call    printdir
          lbnf    exit                ; if DF = 0, all done (R7.0 has last parent)
                    
prt_chld: call    scanchld            ; scan the children, to see if all printed
          lbnf    prt_lp              ; unprinted children, keep going
          
          call    markprnt            ; mark parent directory as printed
          lbdf    prt_chld            ; scan and update grandparents
          
          lbr     prt_lp              ; keep printing until all done
          
bad_exit: abend   ERR_BAD_PATH        ; exit with bad path value
    
exit:     load    rf, summry          ; show summary message
          call    o_msg
          call    do_crlf             ; new line after summary
          clc
          ldi     0
          return                      ; return to os


; *************************************************************
; ***                   Table Entry Format                  ***
; *************************************************************
;    0   |   1  |   2 - 21
;-------------------------------------------------------------------------------
; Parent | Flag |   Name 
;-------------------------------------------------------------------------------

; *************************************************************
; ***                   Table Entry Fields                  ***
; *************************************************************
;-------------------------------------------------------------------------------
;  Field | Size | Description
;-------------------------------------------------------------------------------
; Parent |   1  | Index of parent record, 1 = top level, 0 = end of table
;-------------------------------------------------------------------------------
; Note: Parent = parent entry array index + 2
;-------------------------------------------------------------------------------
; Flag   |   1  | Flag for entry type
;-------------------------------------------------------------------------------
; Note: Flag = 0, means matching file entry
;       Flag = 1, means unsearched directory
;       Flag = 2, means searched directory with all children searched
;       Flag = 3, means searched directory with unsearched children
;       Flag = 80, printed matching file
;       Flag = 82, directory with possible unprinted children
;       Flag = C2, directory with all children printed
;-------------------------------------------------------------------------------
; Name   |  20  | file name (up to 20 characters)
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; Scan a directory and add entries to the table
; Parameters:
;     rf   - directory path to scan
;     r7.0 - parent value  
;     rb.1 - target str length
;     rb.0 - search mode flags
; Uses: 
;     rf   - buffer pointer, next pointer
;     rd   - filedes
;     rc   - read count, table pointer
;     r7.1 - has children flag
; Returns: 
;     rc.0 - error code (0 = okay; -1 = bad directory, exit program)
;     DF = 0 scanned, no subdirecties
;     DF = 1 sub-directories
;-------------------------------------------------------------------------------

scandir:  ldi     0                   ; set up children flag                   
          phi     r7                  ; initial has no children                  

          load    rf, wpath           ; directory in working path buffer
          load    rd,fildes           ; set up (rf already points to director)
          call    o_opendir           ; open the directory
          lbdf    bad_dir             ; DF =1 means error 

          load    rf,next             ; save next pointer as head
          load    rc,head 
          lda     rf                  ; get hi byte of next pointer
          str     rc                  ; save in head
          inc     rc                  ; move to lo byte of head
          ldn     rf                  ; get lo byte of next pointer
          str     rc                  ; head now points to top of new entries

dirloop:  ldi     0                   ; need to read 32 bytes
          phi     rc
          ldi     32
          plo     rc
          load    rf,buffer           ; setup transfer buffer
          call    o_read              ; read files from dir

          glo     rc                  ; see if eof was hit
          lbz     dirdone             ; if not, we're done
          
          load    rf,buffer           ; setup transfer buffer
          lda     rf                  ; check for good entry
          lbnz    dirgood

          lda     rf                  ; check for good entry
          lbnz    dirgood

          lda     rf                  ; check for good entry
          lbnz    dirgood

          lda     rf                  ; check for good entry
          lbnz    dirgood

          lbr     dirloop             ; not a valid entry, loop back
; *************************************************************
; ***     Good entry found, copy data to fnd_ents table     ***
; *************************************************************
dirgood:  load    rf,buffer+6         ; point to flags byte
          ldn     rf                  ; retrieve it
          ani     8                   ; check hidden bit
          lbz     show_f              ; jump if file is not hidden
          glo     rb                  ; retrieve modes
          ani     4                   ; see if show hidden is on
          lbnz    show_f              ; show if -h was specified
          
          lbr     dirloop             ; otherwise do not show it

show_f:   load    rf,buffer+6         ; point to flags byte
          ldn     rf                  ; get flags
          ani     1                   ; see if file is a directory
          lbnz    do_entry            ; always show directories
          
          push    rd                  ; save rd for use in matching
          load    rd, target          ; point rd to target
          load    rf,buffer+12        ; point to name
          ldi     0 
          phi     rc                  ; set up rc for prefix searches
          ghi     rb                  ; get length of target string
          plo     rc                  ; save in rc as count
          glo     rb                  ; retrieve modes
          ani     $03                 ; check search flags
          lbz     m_exact             ; look for exact match
          smi     1                   ; check for ignore case
          lbz     m_nocase            ; ignore case
          smi     1                   ; check for prefix
          lbz     m_prefix
          smi     1                   ; check for ignore case and prefix
          lbz     m_both              
          
m_exact:  call    str_strcmp           
          lbr     m_test
          
m_nocase: call    str_strcasecmp
          lbr     m_test

m_prefix: call    str_strncmp
          lbr     m_test        
          
m_both:   call    str_strncasecmp
          
m_test:   pop     rd                  ; restore rd to fildes    
          lbdf    do_entry            ; show files and directories

          lbr     dirloop             ; otherwise do not show it

do_entry: load    rf,next             ; need to retrieve next pointer
          lda     rf                  ; put into rc
          phi     rc
          ldn     rf
          plo     rc                  ; rc now points to blank space in fnd_ents
          glo     r7                  ; get parent value
          str     rc                  ; store parent in record
          inc     rc
          load    rf,buffer+6         ; point to flags byte
          ldn     rf                  ; get flags
          ani     1                   ; see if file is a directory
          str     rc                  ; save directory flag in record
          inc     rc          
          load    rf,buffer+12        ; point to filename
          ldi     19                  ; 20 bytes per filename
          plo     re
namelp:   lda     rf                  ; get next byte from name
          lbz     namedn              ; jump if name is done

          str     rc                  ; store into fnd_ents storage
          inc     rc
          dec     re                  ; decrement count
          glo     re                  ; check count
          lbnz    namelp              ; loop until all bytes copied

namedn:   load    rf,buffer+6         ; point to flags byte
          ldn     rf                  ; get flags
          ani     1                   ; see if file is a directory
          lbz     fnamedn             ; jump if not

          ldi     '/'                 ; add directory marker
          str     rc
          inc     rc
          dec     re
          ldi     1                   ; has children  
          phi     r7                  ; set has children flag
fnamedn:  ldi     0                   ; write a string terminator
          str     rc
          inc     rc 
nameskp:  glo     re                  ; see if name is full 20 bytes
          lbz     entrydn             ; jump if so

          inc     rc
          dec     re                  ; decrement count
          lbr     nameskp             ; loop until have 20 bytes
        
          ; ***********************
          ; *** Done with entry ***
          ; ***********************
entrydn:  ldi     0                   ; write terminator into list
          str     rc
          load    rf,next             ; save new pointer
          ghi     rc
          str     rf
          inc     rf
          glo     rc
          str     rf
          lbr     dirloop             ; keep reading entries

bad_dir:  call    o_inmsg
            db 10,13,'Directory not found.',10,13,0
          ldi     $FF               
          plo     rc                  ; put error flag into rc.0
          clc                         ; no children (end scan) 
          return
            
; **************************************************************************
; *** Done reading directory, now it needs to be processed and displayed ***
; **************************************************************************
dirdone:  call    o_close               ; close the directory
          ghi     r7                    ; get children flag
          shr                           ; shift children flag into DF
          ldi     0                     ; make sure rc.0 shows no error
          plo     rc
          return

;-------------------------------------------------------------------------------
; Find the entry corresponding to an index value
; Parameters:
;     rc.0 - index value  
; Uses: 
;     rf    - entry pointer
;     rc.0  - index counter
; Returns: 
;     rf - pointer to entry in table
;     DF = 0 entry found
;     DF = 1 not found
;-------------------------------------------------------------------------------
findent:  load  rf, fnd_ents          ; load buffer pointer to start of table

fe_lp:    glo   rc                    ; check counter             
          lbz   fe_found              ; if index = 0, we are at the entry
          
          add16 rf, E_SIZE            ; move pointer to next entry 
          dec   rc                    ; count down index
          ldn   rf                    ; check for end of table
          lbnz  fe_lp                 ; if not at end, keep going
          stc                         ; otherwise signal not found
          lbr   fe_done    
fe_found: clc
fe_done:  return

;-------------------------------------------------------------------------------
; Update the parent entry after a directory scan
; Parameters:
;     r7.0 - parent value  
;     r7.1 - save register for DF flag
;     r7.1 = 1, directory had children
;     r7.1 = 0, directory scanned had no children
; Uses: 
;     rf   - buffer pointer, next pointer
;     rc.0 - index for parent entry
; Returns: 
;     DF = 0 no more updates needed
;     DF = 1 to scan and update grand-parents
;     r7.0 - grand-parent value (if DF = 1)  
;-------------------------------------------------------------------------------
fixprnts: glo   r7
          smi   2                     ; parent is 2 or higher (1 = top, 0 = end)
          lbnf  fp_done               ; if less than 2, nothing to update
          
          plo   rc                    ; save index in rc.0
          call  findent               ; get the parent entry
          
          lbdf  fp_done               ; if not found, just quit
          
          inc   rf                    ; move pointer to directory flag
          ghi   r7                    ; check the child flag
          lbz   fp_none
          
          ldi   03
          str   rf
          lbr   fp_done               ; if has children we are done

fp_none:  ldi   02                    ; if no child directories
          str   rf
          dec   rf                    ; move back to get grand-parent
          ldn   rf                    ; get grand-parent
          plo   r7                    ; save as new parent value
          stc                         ; set DF flag to update grandparents
          return                      
fp_done:  clc                         ; clear DF flag (no more updates)
          return

;-------------------------------------------------------------------------------
; Scan all children of a parent entry, to see if all have been scanned
; Parameters:
;     r7.0 - parent value  
; Uses: 
;     rf    - entry pointer
;     r7.0  - parent value
; Returns: 
;     DF = 0 all children scanned
;     DF = 1 unscanned children
;-------------------------------------------------------------------------------
scanlvl:  load  rf, fnd_ents          ; load buffer pointer to start of table
          glo   r7                    ; check parent value (1 = top, 0 = end)
          smi   2                     
          lbnf  sl_more               ; if below 2, don't update further
          
sl_lp:    lda   rf                    ; get entry parent
          lbz   sl_cont               ; end of table means, all children scanned
          
          str   r2                    ; save parent in M(X)
          glo   r7                    ; get target parent             
          sm                          ; check for match
          lbnz  sl_skp                ; if not sibling keep scanning  
          ldn   rf                    ; check directory flag
          
          shr                         ; check for 1 or 3
          lbdf  sl_more               ; if 1 or 3, we found unscanned item           
          
sl_skp:   add16 rf, E_SIZE-1          ; move pointer to next entry 
          lbr   sl_lp                 ; keep going, until end
          
sl_more:  stc                         ; set DF = 1 for unscanned children 
          return
sl_cont:  clc                         ; all children scanned, continue update
          return


;-------------------------------------------------------------------------------
; Find next directory to scan
; Parameters:
;     (none)
; Uses: 
;     rf    - entry pointer
;     rd    - destination pointer
;     r7.0  - parent value for scanning
;     r7.1  - directory flag
; Returns:
;     r7.0 - parent value for scanning 
;     DF = 0 entry found
;     DF = 1 not found
;-------------------------------------------------------------------------------
findnext: call    cpy_path            ; copy rpath into wpath

          ldi     1                   ; set initial parent to top level 
          plo     r7
          ldi     0
          plo     rc                  ; set up index
          load    rf, fnd_ents        ; start at top of table
          
fn_lp:    push    rf                  ; save rf before modifying it
          lda     rf                  ; get parent for entry
          lbz     fn_none             ; if we reach the end, nothing more to scan             
          
          str     r2                  ; save parent in M(X)
          glo     r7                  ; get target parent
          sm                          ; check for match
          lbnz    fn_skp              ; skip entries with different parent
          
          lda     rf                  ; check directory flag
          phi     r7                  ; save copy
          shr                         ; check for 1 or 3 (odd value)
          lbnf    fn_skp              ; skip any 0 (file) or 2 (scanned) values
          load    rd, wpath           ; set dest for strcat (rf points to dir name)
          call    str_strcat          ; add directory to working path 
           
          ghi     r7                  ; get the directory flag
          smi     1                   ; unscanned directory (1)
          lbz     fn_fnd              ; if unscanned, we found next directory to scan

          glo     rc                  ; if unscanned children (3), update parent value
          adi     2                   ; parent value is two more than index
          plo     r7                  ; new parent value to find unscanned child
          
fn_skp:   inc     rc                  ; bump index counter
          glo     rc                  ; check for maximum value
          smi     MAX_INDEX                
          lbdf    fn_trunc            ; if at maximum, truncate scanning   

          pop     rf                  ; restore previous value of buffer pointer
          add16   rf, E_SIZE          ; move to next entry
          
          lbr     fn_lp               ; keep going until end
          
fn_trunc: pop     rf                  ; restore rf
          ldi     0                   ; make last record the end of table
          str     rf                  ; truncate table at maximum
          call    o_inmsg             ; print message on next line
            db  10,13,'Scan truncated.',10,13,0
          clc                         ; DF = 0 for no more directories to scan          
          return
          
fn_none:  pop     rf                  ; clean up stack
          clc                         ; DF = 0 for no more directories to scan          
          return

fn_fnd:   pop     rf                  ; clean up stack
          glo     rc                  ; get index
          adi     2                   ; add 2 to convert to parent value
          plo     r7                  ; set parent value for next scan
          stc                         ; DF = 1, more directories to scan
          return


;-------------------------------------------------------------------------------
; Count file entries in table
; Parameters:
;     (none)
; Uses: 
;     rf   - entry pointer
; Returns:
;     rc.0 - count of files 
;-------------------------------------------------------------------------------
cntents:  ldi     0
          plo     rc                  ; clear out count values
          phi     rc
          load    rf, fnd_ents        ; point to beginning of table
          
ce_cnt:   lda     rf                  ; get parent for entry
          lbz     ce_done             ; if we reach the end, no more to count
          
          ldn     rf                  ; get type flag
          lbnz    ce_next             ; 0 means file, anything else is directory
          
          inc     rc                  ; bump the file count
           
ce_next:  add16   rf, E_SIZE-1        ; advance to next entry
          lbr     ce_cnt              ; keep going to the end of the table
          
ce_done:  return                      

;-------------------------------------------------------------------------------
; Set the summary message with the number of files and directories.
; Parameters:
;     rc.0 - count of files
; Uses: 
;     rd   - destination pointer
;     rb   - copy of counts
; Returns:
;     (none) - summry memory variable set with appropriate string
;-------------------------------------------------------------------------------
setsum:   copy    rc,rb               ; save copy of rc
          load    rd, summry          ; point destination to summary message          

          ldi     0
          phi     rc                  ; rc has file count
          call    int16_itoa          ; convert to integer ascii string
          
          call    str_strincat        ; concatenate string to end
            db ' file',0
          glo     rb                  ; check file count for singular value
          smi     1
          lbz     ss_cont             ; if only one file, don't add an s
          
          dec     rd                  ; point to last character in string
          call    str_strincat        ; concatenate string
            db 's',0

ss_cont:  dec     rd                  ; point to last character in string
          call    str_strincat        ; concatenate middle string
            db ' found',0
           
          return          


;-------------------------------------------------------------------------------
; Scan the table and print all entries in a directory branch
; Parameters:
;     (none)
; Uses: 
;     rf   - buffer pointer to entry
;     rd   - destination pointer
;     rc   - read count, table pointer
;     r7.0 - parent value  
;     r7.1 - unprinted children flag
; Returns: 
;     r7.0 - parent value of last printed child
;     DF = 0 everything printed
;     DF = 1 sub-directories to print
;-------------------------------------------------------------------------------
printdir: call    cpy_path            ; copy rpath into wpath
          ldi     0
          plo     rc                  ; set index to zero
          phi     r7                  ; set unprinted child flag to zero
          ldi     1                   ; always start at top level
          plo     r7
          load    rf,fnd_ents         ; set buffer pointer to start of table

pd_lp:    push    rf                  ; save rf value 
          lda     rf                  ; get parent
          lbz     pd_done             ; check for end of table

          str     r2                  ; save in M(X)
          glo     r7                  ; get target parent
          sm                          
          lbnz    pd_next             ; not the child we are looking for
          
          ldn     rf                  ; check entry flag
          shl                         ; get printed byte
          lbdf    pd_prntd            ; bit 7 indicates printed already
                    
pd_chk:   ldn     rf                  ; check file
          lbz     pd_prtf             ; zero means unprinted file
          
          ; update wpath here by adding dir name 
          inc     rf                  ; move to name string
          load    rd, wpath           ; set up destination pointer
          call    str_strcat          ; concatenate directory name to path
          
          glo     rc                  ; update parent to print children
          adi     2                   ; parent is index + 2
          plo     r7                  ; update parent value for directory
          ldi     1                   ; store flag to exit with DF = 1
          phi     r7
          lbr     pd_updt             ; update entry pointer after printing
          
          
pd_prtf:  push    rf                  ; save rf
          load    rf,wpath            ; print working path before file
          call    o_msg
          call    do_crlf             ; print end of line
          pop     rf                  ; restore rf to print file name
          inc     rf                  ; move to name string
          call    o_msg               ; print name
          call    do_crlf             ; print end of line
          call    do_crlf             ; blank  line between matches
          
pd_updt:  pop     rf                  ; restore entry pointer
          inc     rf                  ; move to flag byte
          ldn     rf                  ; get flag byte
          ori     $80                 ; set printed bit
          str     rf                  ; save in entry
          dec     rf                  ; point back to beginning  
          lbr     pd_move             ; move to next entry in table

pd_prntd: lbz     pd_next             ; if flag is zero, skip printed file

          shl                         ; if directory, check if children printed
          lbdf    pd_next             ; bit 6 means all children printed

          glo     rc                  ; if not, update parent to print children
          adi     2                   ; parent is index + 2
          plo     r7                  ; update parent value for directory
          ldi     1                   ; store flag to exit with DF = 1
          phi     r7                            
          inc     rd                  ; increase indent level
          
pd_next:  pop     rf
pd_move:  add16   rf, E_SIZE
          inc     rc                  ; bump index
          lbr     pd_lp               ; continue until the end
          
pd_done:  pop     rf                  ; clean up stack
          clc                         ; clear flag
          ghi     r7                  ; check children flag
          lbz     pd_exit
          stc                         ; set DF to scan children
pd_exit:  return



;-------------------------------------------------------------------------------
; Scan all children of a parent entry, to see if all have been printed
; Parameters:
;     r7.0 - parent value  
; Uses: 
;     rf    - entry pointer
;     r7.0  - parent value
; Returns: 
;     DF = 1 all children printed
;     DF = 0 unprinted children
;-------------------------------------------------------------------------------
scanchld: load  rf, fnd_ents          ; load buffer pointer to start of table
          glo   r7                    ; check parent value (1 = top, 0 = end)
          smi   2                     
          lbnf  sc_cont               ; if below 2, don't update further
          
sc_lp:    lda   rf                    ; get entry parent
          lbz   sc_end                ; end of table means, all children printed
          
          str   r2                    ; save parent in M(X)
          glo   r7                    ; get target parent             
          sm                          ; check for match
          lbnz  sc_skp                ; if not sibling keep scanning  
                    
          ldn   rf                    ; check directory flag
                    
          shl                         ; check to see if entry printed 
          lbnf  sc_cont               ; if bit 7 clear, we found un-printed item  
          
          lbz   sc_skp                ; if file, find next child entry
          
          shl                         ; if directory, check if all children were printed
          lbnf  sc_cont               ; if not, still more entries to print                   
          
sc_skp:   add16 rf, E_SIZE-1          ; move pointer to next entry 
          lbr   sc_lp                 ; keep going, until end
          
sc_end:   stc                         ; set DF = 1 all printed children, mark parent done 
          return
          
sc_cont:  clc                         ; unprinted children, don't mark parent
          return



;-------------------------------------------------------------------------------
; Mark the parent entry after a directory is printed
; Parameters:
;     r7.0 - parent value  
;     r7.1 - save register for DF flag
;     r7.1 = 1, directory had children
;     r7.1 = 0, directory scanned had no children
; Uses: 
;     rf   - buffer pointer, next pointer
;     rc.0 - index for parent entry
; Returns: 
;     DF = 0 no more updates needed
;     DF = 1 to scan and update grand-parents
;     r7.0 - grand-parent value (if DF = 1)  
;-------------------------------------------------------------------------------
markprnt: glo   r7
          smi   2                     ; parent is 2 or higher (1 = top, 0 = end)
          lbnf  mp_none               ; if less than 2, nothing to update
          
          plo   rc                    ; save index in rc.0
          call  findent               ; get the parent entry
          
          lbdf  mp_none               ; if not found, just quit
          
          inc   rf                    ; move pointer to directory flag
          ldn   rf  
          ori   $40                   ; set directory scanned bit (bit 6)
          str   rf
          dec   rf                    ; move back to get grand-parent
          ldn   rf                    ; get grand-parent
          plo   r7                    ; save as new parent value
          stc                         ; set DF flag to update grandparents
          return                      
          
mp_none:  clc                         ; clear DF flag (no more updates)
          return


          ; **********************************
          ; ***   Copy rpath into wpath    ***
          ; **********************************
cpy_path: load    rd, wpath           ; copy root path into working path
          load    rf, rpath           ; path string one after rpath
          call    str_strcpy          ; copy string to working buffer

          load    rd, wpath           ; check for slash at end of root path
cp_end:   lda     rd                  ; get character
          lbnz    cp_end              ; find null at end

          dec     rd                  ; back up to null
          dec     rd                  ; to last character
          ldn     rd                  ; get last character
          smi     '/'                 ; check for slash at end of root
          lbz     cp_done             ; if slash we're ready to scan

          load    rd, wpath           ; set destination for adding slash
          call    str_strincat        ; concatenate slash at end of root path
          db      '/',0
 cp_done: clc
          return

          ; **********************************
          ; ***  Incorrect Elf/OS version  ***
          ; **********************************
notv5:    call    o_inmsg             ; display error
          db      'Requires Elf/OS version 5 or higher',10,13,0
          abend   ERR_BAD_VERSION     ; set return code to invalid version

          ; **********************************
          ; *** Print CRLF                 ***
          ; **********************************
do_crlf:  call   o_inmsg          
            db      10,13,0
          return     

fildes:   db      0,0,0,0
          dw      dta
          db      0,0
          db      0
          db      0,0,0,0
          dw      0,0
          db      0,0,0,0
          db      0,0

next:     dw      0                   ; where to store fnd_ents pointer
head:     dw      0                   ; head of directory list
mode:     db      0
size:     db      0
target:   ds      20                  ; target filename


          db      0,0                 ; padding required for build path
rpath:    ds      128           
wpath:    ds      128
buffer:   ds      32
summry:   ds      20                  ; file count message

          end     begin
