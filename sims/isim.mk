SOURCEFILES ?= *.vhd
BUILDDIR ?= ./build
GHDLFLAGS ?=
XILT ?= xilt
GHDL ?= ghdl
INPUTFILES1 := $(shell $(XILT) scandeps $(SOURCEFILES) --deppath://shared )
INPUTFILES ?= $(INPUTFILES1)
TOPMODULE1 := $(shell $(GHDL) -f $(INPUTFILES) | awk '/entity (.*) \*\*/ {print $$2}')
TOPMODULE ?= $(TOPMODULE1)
EXE = $(BUILDDIR)/$(TOPMODULE)-isim

# Compile and Link
$(EXE): $(INPUTFILES)
	xilt buildsim --topmodule:$(TOPMODULE) $(INPUTFILES)

# View (ie launch gtkwave)
view: $(EXE)
	@cd $(BUILDDIR); ./$(TOPMODULE)-isim -gui

# Clean
clean:
	rm -rf build


