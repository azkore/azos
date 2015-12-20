arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso
linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

NIM=nim
NIMARGS:=$(NIMARGS) --opt:size --noLinking --gc:none --os:standalone --deadCodeElim:on --noMain  --parallelBuild:1 --gcc.exe:gcc  --passC:"-w" --passC:"-O2" --passC:"-Wall" --passC:"-Wextra" --passC:"-ffreestanding" --passC:"-D_POSIX_THREADS"  --passC:"-mcmodel=kernel"  --threads:on --nimcache:./build/arch/$(arch)/nimcache

nim_source_files := src/kmain.nim src/ioutils.nim
nim_object_files := $(patsubst src/%.nim, build/arch/$(arch)/nimcache/%.o, $(nim_source_files)) build/arch/$(arch)/nimcache/stdlib_system.o build/arch/$(arch)/nimcache/stdlib_unsigned.o

.PHONY: all clean run iso debug

all: $(kernel)

clean:
	rm -r build

run: $(iso)
	qemu-system-x86_64 -drive format=raw,file=$(iso)

debug: $(iso)
	qemu-system-x86_64 -drive format=raw,file=$(iso) -s -S -monitor stdio

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	[ ! -f build/isofiles/boot/grub ] && mkdir -p build/isofiles/boot/grub
	cp $(kernel) build/isofiles/boot/kernel.bin
	cp $(grub_cfg) build/isofiles/boot/grub
	grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	rm -r build/isofiles

$(kernel): $(assembly_object_files) $(nim_object_files) $(linker_script)
	ld -n --gc-sections -T $(linker_script) -o $(kernel) $(assembly_object_files) $(nim_object_files)
	ls -l --color $(kernel)

build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@[ ! -f $(shell dirname $@) ] && mkdir -p $(shell dirname $@)
	nasm -felf64 $< -o $@

build/arch/$(arch)/nimcache/%o: $(nim_source_files)
	$(NIM) c $(NIMARGS) $<
