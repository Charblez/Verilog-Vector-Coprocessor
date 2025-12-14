#----------------------------------------------------------------------------------------------------
# Filename: Makefile
# Author: Charles Bassani
# Description: Makefile for iverilog modules
# Usage: 
#	- make test <module> <optional hex file>
#		> Requires src/<module>.sv and tests/<module>_tb.sv and the below code block in the testbench
#
#			initial begin
#		   		$dumpfile("build/<module>_tb_wave.vcd");
#		   		$dumpvars(0, <module>_tb);
#			end
#
#		> Will compile all other modules and testbenches so an compile error will fail this command
#		> Optional hex file will be loaded into a module using this below code block
#			
#			initial begin
#			    string filename;
#			    if(!$value$plusargs("IMEM_FILE=%s", filename)) filename = "<optional hex file>";
#			    $readmemh(filename, dut.<module to load into>);
#			end
#			
#	- make simulate <module> <optional hex file>
#		> Same as test but runs gtkwave automatically
#
#----------------------------------------------------------------------------------------------------
SIM = iverilog
SRCPATH = src
TESTPATH = tests
PROGRAMPATH = programs
BUILDPATH = build
SRC := $(SRC_MODS) $(SRC_TB)

ARG2 ?= $(word 2, $(MAKECMDGOALS))
ARG3 ?= $(word 3, $(MAKECMDGOALS))

#----------------------------------------------------------------------------------------------------
# Default Module to run
#----------------------------------------------------------------------------------------------------
DEFAULT_MODULE = CPUCore
DEFAULT_PROGRAM = imem_init.hex

#----------------------------------------------------------------------------------------------------
# Terminate ARG2 and ARG3
#----------------------------------------------------------------------------------------------------
$(eval $(ARG2): ; @:)
$(eval $(ARG3): ; @:)

#----------------------------------------------------------------------------------------------------
# Default module and program
#----------------------------------------------------------------------------------------------------
ARG2 ?= DEFAULT_MODULE
ARG3 ?= DEFAULT_PROGRAM

#----------------------------------------------------------------------------------------------------
# Non file termination
#----------------------------------------------------------------------------------------------------
.PHONY: all build test simulate clean

#----------------------------------------------------------------------------------------------------
#  File Checks
#----------------------------------------------------------------------------------------------------
ifneq ($(MAKECMDGOALS),clean)
SRC_FILES = $(wildcard $(SRCPATH)/*.sv)
TB_FILE = $(wildcard $(TESTPATH)/$(ARG2)_tb.sv)

ifeq ($(TB_FILE),)
$(error No testbench file found for module: $(ARG2))
endif
endif

#----------------------------------------------------------------------------------------------------
#  Build default target
#----------------------------------------------------------------------------------------------------
all: build

#----------------------------------------------------------------------------------------------------
#  Build target
#----------------------------------------------------------------------------------------------------
build:
	@mkdir -p $(BUILDPATH)
	@echo "----------------------------------------------------"
	@echo " Building testbench for <$(ARG2)> with program <$(DEFAULT_PROGRAM)>"
	@echo " Build complete → $(BUILDPATH)/$(ARG2)_test.out"
	@echo "----------------------------------------------------"
	@iverilog -g2012 -o $(BUILDPATH)/$(ARG2)_test.out $(SRC_FILES) $(TB_FILE)

#----------------------------------------------------------------------------------------------------
#  Build and test target
#----------------------------------------------------------------------------------------------------
test: build
	@echo "----------------------------------------------------"
	@echo " Testing $(ARG2)"
	@echo "----------------------------------------------------"
	@vvp $(BUILDPATH)/$(ARG2)_test.out +IMEM_FILE=$(PROGRAMPATH)/$(ARG3) +WAVEFILE=$(BUILDPATH)/$(ARG2)_tb_wave.vcd;

#----------------------------------------------------------------------------------------------------
#  Build and run GTKWave for target
#----------------------------------------------------------------------------------------------------
simulate: test
	@echo "----------------------------------------------------"
	@echo " Launching GTKWave for $(ARG2)"
	@echo "----------------------------------------------------"
	@gtkwave $(BUILDPATH)/$(ARG2)_tb_wave.vcd

#----------------------------------------------------------------------------------------------------
#  Clean build directory
#----------------------------------------------------------------------------------------------------
clean:
	@rm -rf build/*