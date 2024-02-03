
all:
	nasm -f bin boot.asm -o boot.bin
	# Ctrl-A X to kill
	qemu-system-x86_64 -nographic -hda boot.bin

.PHONY: clean

.clean:
	rm -f boot.bin
