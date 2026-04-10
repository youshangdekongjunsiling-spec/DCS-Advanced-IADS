#!/usr/bin/env python3
"""
Runtime path helpers for the advanced EW simulator.
"""

from __future__ import annotations

import sys
from pathlib import Path


MODULE_DIR = Path(__file__).resolve().parent
RESOURCE_ROOT = Path(getattr(sys, "_MEIPASS", MODULE_DIR))
APP_ROOT = Path(sys.executable).resolve().parent if getattr(sys, "frozen", False) else MODULE_DIR

