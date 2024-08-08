[Your Path]\Asm02\asm02 -L tree.asm
[Your Path]\Asm02\asm02 -L tree_buf.asm

[Your Path]\Asm02\asm02 -L find.asm
[Your Path]\Asm02\asm02 -L find_buf.asm


[Your Path]\Link02\link02 -e -s tree.prg -l ..\lib\stdlib5.lib -l tree_buf.prg

[Your Path]\link02 -e -s find.prg -l ..\lib\stdlib5.lib -l find_buf.prg
