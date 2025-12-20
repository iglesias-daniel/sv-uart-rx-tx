# By Daniel Iglesias and ChatGPT 5.2 (2025)

# ==== Config ====
SIM ?= iverilog
RUNNER ?= vvp

RTL_DIR := rtl
TB_DIR := tb

BUILD_DIR := build
LOG_DIR := logs
WAVE_DIR := waves

# RTL files
RTL_SRCS := $(wildcard $(RTL_DIR)/*.v)

# Testbenches
TB_SRCS  := $(wildcard $(TB_DIR)/tb_*.sv)
TB_NAMES := $(basename $(notdir $(TB_SRCS)))

# Tun targets
RUN_TARGETS := $(addprefix run-,$(TB_NAMES))
WAVE_TARGETS := $(addprefix wave-,$(TB_NAMES))

SIM_FLAGS ?= -g2012 -Wall
INC_FLAGS :=

.PHONY: all list clean $(RUN_TARGETS) $(WAVE_TARGETS)

all: $(RUN_TARGETS)

list:
	@echo "Testbenches:"
	@$(foreach t,$(TB_NAMES),echo "  - $(t)";)

# General rule: compile a TB
$(BUILD_DIR)/%.vvp: $(TB_DIR)/%.sv $(RTL_SRCS)
	@mkdir -p $(BUILD_DIR) $(LOG_DIR) $(WAVE_DIR)
	$(SIM) $(SIM_FLAGS) $(INC_FLAGS) -o $@ $(RTL_SRCS) $<

# General rule: execute a TB
run-%: $(BUILD_DIR)/%.vvp
	@echo "== Running $* =="
	@rm -f $(WAVE_DIR)/$*.vcd
	@$(RUNNER) $< > $(LOG_DIR)/$*.log
	@if [ -f waves.vcd ]; then mv waves.vcd $(WAVE_DIR)/$*.vcd; fi
	@echo "Log:  $(LOG_DIR)/$*.log"
	@echo "Wave: $(WAVE_DIR)/$*.vcd"

#Open GTKWave
wave-%: run-%
	gtkwave $(WAVE_DIR)/$*.vcd

clean:
	rm -rf $(BUILD_DIR) $(LOG_DIR) $(WAVE_DIR) *.vcd waves.vcd