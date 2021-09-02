
SRC_DIR := src
BIN_DIR := bin

EXEC := ${BIN_DIR}/pfxsum
VFILES := $(wildcard $(SRC_DIR)/*.v)

.PHONY: all clean

all: ${EXEC}

${EXEC}: ${VFILES} ${BIN_DIR}
	iverilog -o $@ $^

${BIN_DIR}:
	mkdir -p $@

clean:
	rm -rf ${BIN_DIR}
