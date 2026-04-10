#!/usr/bin/env python3
"""
Build a runnable Windows package for the advanced EW simulator.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PyInstaller.__main__ import run as pyinstaller_run


ROOT_DIR = Path(__file__).resolve().parent
DIST_DIR = ROOT_DIR / "dist"
BUILD_DIR = ROOT_DIR / "build"
APP_NAME = "AdvancedEWSimulator"


def clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)


def main() -> None:
    clean_dir(DIST_DIR)
    clean_dir(BUILD_DIR)

    pyinstaller_run(
        [
            str(ROOT_DIR / "jammer_research_ui.py"),
            "--noconfirm",
            "--clean",
            "--windowed",
            "--onedir",
            f"--name={APP_NAME}",
            f"--distpath={DIST_DIR}",
            f"--workpath={BUILD_DIR}",
            f"--specpath={ROOT_DIR}",
            f"--add-data={ROOT_DIR / 'Jammer parameters'};Jammer parameters",
            f"--add-data={ROOT_DIR / 'jammer_research_params.json'};.",
            "--hidden-import=tkinter",
            "--hidden-import=matplotlib.backends.backend_tkagg",
            "--exclude-module=PyQt5",
            "--exclude-module=PyQt6",
            "--exclude-module=PySide2",
            "--exclude-module=PySide6",
        ]
    )

    packaged_root = DIST_DIR / APP_NAME
    shutil.copyfile(ROOT_DIR / "jammer_research_params.json", packaged_root / "jammer_research_params.json")
    print(f"Built runnable package: {packaged_root}")


if __name__ == "__main__":
    main()
