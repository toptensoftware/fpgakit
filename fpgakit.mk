# ------------------------- Enviroment -------------------------

# Phony targets
.PHONY: clean build-bit upload-bit build-ghdl run-ghdl view-ghdl

FPGAKIT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
FPGAKIT := $(FPGAKIT:/=)
XILT ?= xilt
GHDL ?= ghdl
GTKWAVE ?= gtkwave

# ------------------------- Project Settings -------------------------

PROJECTNAME ?= $(notdir $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))
BUILDDIR ?= ./build
OUTDIR ?= $(BUILDDIR)
DEPPATH += $(FPGAKIT)/shared ./coregen
OTHERSOURCEFILES ?= 

# ------------------------- Clean  -------------------------

# Optional files/folders to remove
CLEAN ?= 

# Clean target
clean:
	@rm -rf $(BUILDDIR)
	@rm -rf $(OUTDIR)
	@for p in $(CLEAN); do rm -rf $$p; done



# ------------------------- Xilinx Build -------------------------

# Settings
BITTOP ?= top
BITFILE ?= $(OUTDIR)/$(PROJECTNAME).bit
BINFILE ?= $(OUTDIR)/$(PROJECTNAME).bin
UCFFILE ?= $(wildcard *.ucf)
BOARDSPEC ?= @$(FPGAKIT)/boardspecs/$(TARGETBOARD)-xilt.txt
TARGETBOARD ?= 

# Scan for dependencies
BITSOURCEFILES = $(shell $(XILT) scandeps $(BITTOP).vhd $(addprefix --deppath:,$(DEPPATH)))

$(BITFILE): $(BITSOURCEFILES) $(UCFFILE) $(OTHERSOURCEFILES) $(FPGAKIT)/shared/SuppressBenignWarnings.vhd
	@$(XILT) build \
	--projectName:$(PROJECTNAME) \
	--intDir:$(BUILDDIR) \
	--outDir:$(OUTDIR) \
	--topModule:$(BITTOP) \
	--messageFormat:msCompile \
	--noinfo \
	$(BOARDSPEC) \
	$^

# Build Xilinx .bit file
build-bit: $(BITFILE)


# ------------------------- Xilinx Upload -------------------------

UPLOADER ?= $(FPGAKIT)/boardspecs/$(TARGETBOARD)-upload
UPLOADOPTS ?=

upload-bit: build-bit
	$(UPLOADER) $(BITFILE)


# ------------------------- Build ISIM -------------------------

ISIMSIMEXE = $(OUTDIR)/$(ISIMTOP)-isim
ISIMTOP ?= TestBench

# Scan for dependencies
ISIMSOURCEFILES = $(shell $(XILT) scandeps $(ISIMTOP).vhd $(addprefix --deppath:,$(DEPPATH)))

build-isim: $(ISIMSIMEXE)

# Build ISim simulator
$(ISIMSIMEXE): $(ISIMSOURCEFILES) $(OTHERSOURCEFILES)
	@$(XILT) buildsim --messageFormat:msCompile --topmodule:$(ISIMTOP) $^

# ------------------------- Run ISIM -------------------------

# View (ie launch ISim)
view-isim: build-isim
	@cd $(BUILDDIR); touch waves.wcfg; ./$(ISIMTOP)-isim -gui -view waves.wcfg



# ------------------------- GHDL Build -------------------------

GHDLFLAGS ?= 
GHDLTOP ?= TestBench
GHDLSIMEXE = $(OUTDIR)/$(GHDLTOP)-ghdl
GHDLSIMOPTS ?=

# Scan for dependencies
GHDLSOURCEFILES = $(shell $(XILT) scandeps $(GHDLTOP).vhd $(addprefix --deppath:,$(DEPPATH)))

build-ghdl: $(GHDLSIMEXE)

# Compile and Link
$(GHDLSIMEXE): $(GHDLSOURCEFILES)  $(OTHERSOURCEFILES)
	@mkdir -p $(BUILDDIR)
	@$(XILT) ghdl-filter $(GHDL) -a --workdir=$(BUILDDIR) $(GHDLFLAGS) $^
	@$(XILT) ghdl-filter $(GHDL) -m --workdir=$(BUILDDIR) -o $(GHDLSIMEXE) $(GHDLTOP)
	@echo
	@echo "Finished."


# ------------------------- Run GHDL -------------------------

GHDLVCDFILE ?= $(BUILDDIR)/ghdl-out.vcd

run-ghdl: $(GHDLVCDFILE)

$(GHDLVCDFILE): $(GHDLSIMEXE)
	@echo ------------ Start Simulation \($(GHDLSIMOPTS)\) ------------
	@$(GHDLSIMEXE) --vcd=$(GHDLVCDFILE) $(GHDLSIMOPTS)
	@echo ------------ End Simulation ------------



# ------------------------- View GHDL Wave -------------------------

view-ghdl: run-ghdl
	$(GTKWAVE) $(GHDLVCDFILE) --save=gtkwave_config.gtkw $(GTKWAVEOPTS)

