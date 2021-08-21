O_CLDBOOT: equ     0300h               ; jump to cold boot routine
O_WRMBOOT: equ     0303h               ; jump to warm boot routine
O_OPEN:    equ     0306h               ; open a file
O_READ:    equ     0309h               ; read from file
O_WRITE:   equ     030ch               ; write to file
O_SEEK:    equ     030fh               ; seek to file position
O_CLOSE:   equ     0312h               ; close file
O_OPENDIR: equ     0315h               ; open dir as a file
O_DELETE:  equ     0318h               ; delete a file
O_RENAME:  equ     031bh               ; rename a file
O_EXEC:    equ     031eh               ; execute an external program
O_MKDIR:   equ     0321h               ; make directory
O_CHDIR:   equ     0324h               ; change directory
O_RMDIR:   equ     0327h               ; remove directory
O_RDLUMP:  equ     032Ah               ; read LAT entry
O_WRLUMP:  equ     032Dh               ; write LAT entry
O_TYPE:    equ     0330h               ; passthrough for console output
O_MSG:     equ     0333h               ; passthrough for console output
O_READKEY: equ     0336h               ; passthrough for console input
O_INPUT:   equ     0339h               ; passthrough for console input
O_PRTSTAT: equ     033ch               ; printer status
O_PRINT:   equ     033fh               ; output to printer
O_EXECBIN: equ     0342h               ; execute from default directory
O_SETDEF:  equ     0345h               ; set/get default directory
O_KINIT:   equ     0348h               ; reserved - do not use!!!
O_INMSG:   equ     034bh               ; passthrough for console output
O_GETDEV:  equ     034eh               ; passthrough to f_getdef
O_GETTOD:  equ     0351h               ; passthrough to f_gettod
O_SETTOD:  equ     0354h               ; passthrough to f_settod
O_INPUTL:  equ     0357h               ; passthrough to f_inputl
O_BOOT:    equ     035ah               ; passthrough to f_boot
O_SETBD:   equ     0360h               ; passthrough to f_setbd
O_INITCALL: equ    0363h               ; passthrough to f_initcall
O_BRKTEST: equ     0366h               ; passthrough to f_brktest
O_DEVCTRL: equ     0369h               ; Hook for device control drivers
O_ALLOC:   equ     036ch               ; passthrough to alloc
O_DEALLOC: equ     036fh               ; passthrough to dealloc
O_TERMCTRL: equ    0372h               ; Hook for terminal control drivers
O_MEMCTRL: equ     0375h               ; Hook for memory control drivers
I_SERVE:   equ     03f6h               ; address of interrupt chain head
V_IVEC:    equ     03fdh               ; interrupt head
V_DVEC:    equ     036ah               ; device head
K_VER:     equ     0400h               ; kernel version number
K_BUILD:   equ     0403h               ; kernel build number
K_BMONTH:  equ     0405h               ; kernel build month
K_BDAY:    equ     0406h               ; kernel build day
K_BYEAR:   equ     0407h               ; kernel build month
K_HIMEM:   equ     0442h               ; high memory pointer
K_LOWMEM:  equ     0465h               ; lowest memory heap can use
K_RETVAL:  equ     0467h               ; D on program exit
K_HEAP:    equ     0468h               ; heap pointer
K_CLKFREQ: equ     0470h               ; system clock frequency
K_MONTH:   equ     0475h               ; date/time
K_DAY:     equ     0476h
K_YEAR:    equ     0477h
K_HOUR:    equ     0478h
K_MINUTE:  equ     0479h
K_SECOND:  equ     047ah
K_SECDEN:  equ     047bh
K_SECNUM:  equ     047dh


