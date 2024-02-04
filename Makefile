
all:
	nasm -f bin boot.asm -o boot.bin
	dd if=payload.txt >> boot.bin
	dd if=/dev/zero bs=512 count=1 >> boot.bin

run:
	@# Ctrl-A X to kill
	qemu-system-x86_64 -nographic -hda boot.bin

.PHONY: clean

clean:
	rm -f boot.bin
