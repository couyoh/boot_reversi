BUILDDIR := build
SRCDIR := src
BOCHS := bochs
OUTPUT := $(BUILDDIR)/main.bin

all: $(OUTPUT)

$(BUILDDIR)/%.bin: $(SRCDIR)/%.asm | $(BUILDDIR)
	nasm $< -o $@

debug: $(OUTPUT)
	$(BOCHS) -dbg -qf ./.bochsrc

clean:
	rm -f $(OUTPUT)

test: $(BUILDDIR)/main.bin
	python tests/main.py $<

$(BUILDDIR):
	mkdir -p $(BUILDDIR)
