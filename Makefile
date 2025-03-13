VERSION := $(shell grep '^version' typst.toml | awk -F ' = ' '{print $$2}' | tr -d '"')
PACKAGE_NAME := $(shell grep '^name' typst.toml | awk -F ' = ' '{print $$2}' | tr -d '"')
TARGET_DIR=./$(PACKAGE_NAME)/$(VERSION)


check:
	typst compile ./src/lib.typ
	rm ./src/lib.pdf

all:
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/src
	cp ./typst.toml $(TARGET_DIR)/typst.toml
	cp ./LICENSE $(TARGET_DIR)/
	cp -r ./src/* $(TARGET_DIR)/src/
	awk '{gsub("https://typst.app/universe/package/fancy-units", "https://github.com/janekfleper/typst-fancy-units");print}' ./README.md > $(TARGET_DIR)/README.md
