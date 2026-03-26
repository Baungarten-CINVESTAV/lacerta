# =============================================================================
#  Lacerta-HMI Designer – PyInstaller build target (Windows / GNU Make)
# =============================================================================
#
#  Usage:
#    make                  – show this help
#    make build            – create a single-file Windows executable (dist/)
#    make build-dir        – create a one-directory bundle (faster startup)
#    make clean            – remove PyInstaller artefacts (build/ and dist/)
#    make install-deps     – install Python dependencies + PyInstaller
#
#  The resulting executable is placed in:
#    dist/LacertaHMIDesigner.exe          (for 'make build')
#    dist/LacertaHMIDesigner/             (for 'make build-dir')
#
#  The xpacks toolchain is NOT bundled – set its path at runtime via
#  Settings → Set Tool Paths inside the application.
#
#  Notes:
#    * Requires Python 3.11+ and PyInstaller on PATH.
#    * Run from the repository root (where this file lives).
#    * scenes/ and output/ are NOT bundled; the executable writes them
#      next to itself at runtime (same as in development mode).
# =============================================================================

APP_NAME    := LacertaHMIDesigner
ENTRY_POINT := gui/main.py
ICON        :=                    # optional: set to e.g. gui/icon.ico

PYINSTALLER := pyinstaller

# Data paths bundled with the exe  (src;dest  on Windows, src:dest on Mac/Linux)
# We detect the OS separator automatically via a shell test.
_SEP := ;

PYINSTALLER_FLAGS := \
	--noconfirm \
	--name "$(APP_NAME)" \
	--add-data "tools/masks$(_SEP)tools/masks" \
	--add-data "tools/scripts/python$(_SEP)tools/scripts/python" \
	--hidden-import "PIL" \
	--hidden-import "serial" \
	--hidden-import "serial.tools.list_ports" \
	--hidden-import "numpy"

ifdef ICON
PYINSTALLER_FLAGS += --icon "$(ICON)"
endif

# ─────────────────────────────────────────────
.DEFAULT_GOAL := help

.PHONY: help build build-dir clean install-deps

help:
	@echo ""
	@echo "===== Lacerta-HMI Designer – build targets ====="
	@echo ""
	@echo "  make build        Single-file Windows .exe  (dist/$(APP_NAME).exe)"
	@echo "  make build-dir    One-directory bundle       (dist/$(APP_NAME)/)"
	@echo "  make clean        Remove build/ and dist/"
	@echo "  make install-deps Install Python packages + PyInstaller"
	@echo ""
	@echo "  The RISC-V toolchain is NOT bundled."
	@echo "  Set its path at runtime: Settings > Set Tool Paths"
	@echo ""

# ── Single-file executable ──────────────────────────────────────────────────
build:
	$(PYINSTALLER) --onefile --windowed $(PYINSTALLER_FLAGS) $(ENTRY_POINT)
	@echo ""
	@echo ">>> Built: dist/$(APP_NAME).exe"
	@echo "    Copy scenes/ and output/ next to the exe before running,"
	@echo "    or let the application create them on first use."
	@echo ""

# ── One-directory bundle (faster cold start) ────────────────────────────────
build-dir:
	$(PYINSTALLER) --onedir --windowed $(PYINSTALLER_FLAGS) $(ENTRY_POINT)
	@echo ""
	@echo ">>> Built: dist/$(APP_NAME)/"
	@echo ""

# ── Install Python dependencies ─────────────────────────────────────────────
install-deps:
	pip install PySide6 Pillow pyserial numpy pyinstaller

# ── Clean artefacts ─────────────────────────────────────────────────────────
clean:
	@if exist build   rmdir /s /q build
	@if exist dist    rmdir /s /q dist
	@if exist "$(APP_NAME).spec"   del /q "$(APP_NAME).spec"
	@echo "Cleaned build/ dist/ and $(APP_NAME).spec"
