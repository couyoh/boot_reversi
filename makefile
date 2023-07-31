BUILDDIR := build
BOCHS := bochs
OUTPUT := $(BUILDDIR)/main.bin

all: $(OUTPUT)

$(BUILDDIR)/%.bin: %.asm | $(BUILDDIR)
	nasm $< -o $@

debug: $(OUTPUT)
	$(BOCHS) -qf ./.bochsrc

clean:
	rm -f $(OUTPUT)

test: $(BUILDDIR)/main.bin
	python tests/main.py $<

$(BUILDDIR):
	mkdir -p $(BUILDDIR)
