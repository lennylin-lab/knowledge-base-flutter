#!/usr/bin/env python3
"""Forwarding shim: the real hook lives at <repo>/.zcode/hooks/.

The shell tool's working directory can be a nested task directory, which makes
the host-resolved relative script path point here. Delegate unchanged so the
hook behaves exactly as registered.
"""
import os
import subprocess
import sys
from pathlib import Path

real = Path(__file__).resolve()
while True:
    candidate = real.parent
    real = candidate
    if (real / ".trellis").is_dir():
        break
real = real / ".zcode" / "hooks" / "inject-shell-session-context.py"
sys.exit(subprocess.call([sys.executable, str(real)], stdin=sys.stdin))
