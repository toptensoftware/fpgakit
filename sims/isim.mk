SOURCEFILES ?= *.vhd
BUILDDIR ?= ./build
XILT ?= xilt
INPUTFILES := $(shell $(XILT) scandeps $(SOURCEFILES) --deppath://shared )
TOPMODULE ?= TestBench
EXE = $(BUILDDIR)/$(TOPMODULE)-isim

.PHONY: simulator view clean

simulator: $(EXE)

# View (ie launch ISim)
view: $(EXE)
	@cd $(BUILDDIR); touch waves.wcfg; ./$(TOPMODULE)-isim -gui -view waves.wcfg

# Build ISim simulator
$(EXE): $(INPUTFILES)
	@xilt buildsim --topmodule:$(TOPMODULE) $(INPUTFILES)

clean:
	@rm -rf build
	@for p in $(CLEAN); do rm -rf $$p; done
