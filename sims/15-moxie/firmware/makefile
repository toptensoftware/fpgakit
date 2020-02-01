## MOXIE TOOL CHAIN
MOXIEPATH=/opt/moxielogic
CC=$(MOXIEPATH)/bin/moxie-elf-gcc
OBJDUMP=$(MOXIEPATH)/bin/moxie-elf-objdump
OBJCOPY=$(MOXIEPATH)/bin/moxie-elf-objcopy

PROJNAME=firmware

## TOOL OPTIONS
CCOPTS=-meb -std=c99 -save-temps=obj

## Output directory
OUT = ./build

## Work out file list
C_SRC = $(wildcard *.c)
S_SRC = $(wildcard *.s)
C_OBJ = $(addprefix $(OUT)/,$(C_SRC:.c=.o))
S_OBJ = $(addprefix $(OUT)/,$(S_SRC:.s=.o))
OBJ_FILES := $(C_OBJ)
OBJ_FILES += $(S_OBJ)

## Link Step
$(OUT)/$(PROJNAME).bin: $(OUT) $(OBJ_FILES)
	@echo Linking $@
	@$(CC) $(OBJ_FILES) -nostartfiles -Wl,-Map,$(OUT)/$(PROJNAME).map -o $(OUT)/$(PROJNAME).elf -Tmoxie-elf-embedded.ld
	@$(OBJCOPY) -O binary $(OUT)/$(PROJNAME).elf $(OUT)/$(PROJNAME).bin

$(OUT)/%.o: %.c
	@echo Compiling $<
	@$(CC) $(CCOPTS) -Wa,-a=$(OUT)/$<.lst -c $< -o $@

$(OUT)/%.o: %.s
	@echo Compiling $<
	@$(CC) $(CCOPTS) -Wa,-a=$(OUT)/$<.lst -c -o $@ $< 

$(OUT):
	@mkdir -p $(OUT)

clean:
	@rm -rf $(OUT)
