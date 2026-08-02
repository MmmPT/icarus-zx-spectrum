PASMO ?= pasmo
PYTHON ?= python3
BUILD_DIR := build
RELEASE_TAP := $(BUILD_DIR)/Icarus.tap

.PHONY: all clean verify

all: $(RELEASE_TAP)

$(BUILD_DIR)/icarus.bin: src/icarus.asm src/tabs.inc
	mkdir -p $(BUILD_DIR)
	cd src && $(PASMO) icarus.asm ../$(BUILD_DIR)/icarus.bin ../$(BUILD_DIR)/icarus.sym

$(RELEASE_TAP): $(BUILD_DIR)/icarus.bin assets/basic_loader.bin assets/loadscr.scr tools/build_tap.py
	$(PYTHON) tools/build_tap.py \
		--loader assets/basic_loader.bin \
		--screen assets/loadscr.scr \
		--code $(BUILD_DIR)/icarus.bin \
		--output $(RELEASE_TAP)

verify: $(RELEASE_TAP)
	sha256sum $(RELEASE_TAP)
	@echo "Released v1.0 TAP SHA-256: f3247a40daf56174e9046a7ef8b503fd4a0c2ff7e6d311e9d12168f9109954c3"

clean:
	rm -rf $(BUILD_DIR)
