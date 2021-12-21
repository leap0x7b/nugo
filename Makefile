ISO := build/nugo.iso
SHELL := zsh

GO := go
CC := clang -target i386-pc-elf
LD := ld.lld
AS := nasm

GOFLAGS := -ldflags="-w -compressdwarf=false" -gcflags=all="-N -l"
GOHARDFLAGS := -buildmode=c-archive
GOENV :=
GOHARDENV := GOPATH=$(CURDIR)/build GOARCH=386 GOOS=linux CGO_ENABLED=1 CC="$(CC)" CGO_CFLAGS="-ggdb -ffreestanding -I$(CURDIR)/src/c" GOTRACEBACK=crash
CFLAGS := -O0 -ggdb -Wall -Wextra
CHARDFLAGS := -nostdlib -ffreestanding -Isrc/c -mcmodel=kernel -mabi=sysv
LDFLAGS :=
LDHARDFLAGS := -melf_i386 -nostdlib -Tsrc/linker.ld
ASFLAGS :=
ASHARDFLAGS := -O0 -g -Fdwarf -felf32 -Isrc/asm

C_SRC := $(wildcard src/c/*.c src/c/*/*.c)
AS_SRC := $(wildcard src/asm/*.s src/asm/*/*.s)
OBJ := $(patsubst src/%, build/%.o, $(C_SRC:%.c=%))
OBJ += $(patsubst src/%, build/%.o, $(AS_SRC:%.s=%))

all: $(shell mkdir -p build build/asm build/c) $(ISO)

limine:
	make -C external/limine

$(ISO): limine build/nugo.elf
	rm -rf build/iso
	mkdir -p build/iso/boot
	cp build/nugo.elf src/limine.cfg external/limine/limine.sys build/iso/boot
	cp external/limine/limine-cd.bin external/limine/limine-eltorito-efi.bin build/iso/
	xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-eltorito-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		build/iso -o $(ISO)
	external/limine/limine-install $(ISO)

build/nugo.elf: build/go.o $(OBJ)
	$(LD) $(LDFLAGS) $(LDHARDFLAGS) $^ -o $@ -Map build/nugo.map

build/c/%.o: src/c/%.c
	$(CC) $(CFLAGS) $(CHARDFLAGS) -c $< -o $@

build/asm/%.o: src/asm/%.s
	$(AS) $(ASFLAGS) $(ASHARDFLAGS) $< -o $@

build/go.o: src/main.go
	ar --output build -x =($(GOHARDENV) $(GO) build $(GOFLAGS) $(GOHARDFLAGS) -o /dev/stdout ./$(shell dirname $<))
	llvm-objcopy --globalize-symbol runtime.g0 --globalize-symbol main.main $@ $@

run: build/nugo.elf
	qemu-system-x86_64 -m 2G -cdrom $(ISO) -serial stdio

clean:
	$(RM)r build
