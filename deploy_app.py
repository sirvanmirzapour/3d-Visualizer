#!/usr/bin/env python3
"""
deploy_app.py - Automated Flutter app deployment to USB-connected Android devices.

Steps:
  1. Wait for a USB-connected Android device to appear (polling `adb devices`).
  2. Run `flutter clean` and `flutter build apk --debug`.
  3. Install the debug APK onto the connected device.
  4. Launch the app with `adb shell am start`.

Only standard library modules are used.
"""

import argparse
import os
import subprocess
import sys
import time


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Deploy a Flutter debug APK to a USB-connected Android device.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--project-dir",
        required=True,
        help="Path to the Flutter project directory.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Seconds to wait for a USB-connected Android device.",
    )
    parser.add_argument(
        "--serial",
        default=None,
        help="Optional device serial number to target a specific device.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print commands that would be executed without actually running them.",
    )
    return parser.parse_args()


def run_command(
    command: list[str],
    cwd: str | None = None,
    check: bool = True,
    dry_run: bool = False,
) -> subprocess.CompletedProcess:
    """Run a command and return the CompletedProcess.

    If dry_run is True, the command is only printed and not executed.
    """
    display_command = " ".join(command)
    if dry_run:
        print(f"[DRY-RUN] $ {display_command}")
        return subprocess.CompletedProcess(
            args=command,
            returncode=0,
            stdout="",
            stderr="",
        )

    print(f"+ {display_command}")
    try:
        return subprocess.run(
            command,
            cwd=cwd,
            check=check,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        print(f"[ERROR] Command failed with exit code {exc.returncode}")
        if exc.stdout:
            print("--- stdout ---")
            print(exc.stdout)
        if exc.stderr:
            print("--- stderr ---")
            print(exc.stderr)
        raise


def is_adb_available() -> bool:
    """Check that the adb executable is reachable in PATH."""
    result = subprocess.run(
        ["adb", "version"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def find_connected_device(serial: str | None = None, timeout: int = 30) -> str | None:
    """Poll `adb devices` until a USB-connected device appears.

    Returns the serial of the first suitable device, or None if none appears.
    """
    print(f"Waiting for a USB-connected Android device (timeout: {timeout}s)...")
    start = time.perf_counter()

    while time.perf_counter() - start < timeout:
        result = subprocess.run(
            ["adb", "devices"],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print(
                f"  [WARN] `adb devices` failed (exit {result.returncode}). "
                f"STDERR: {result.stderr.strip()}"
            )
            time.sleep(1)
            continue

        output_lines = result.stdout.splitlines()
        # First line is the header: "List of devices attached"
        for line in output_lines[1:]:
            line = line.strip()
            if not line:
                continue

            # Format: SERIAL\tSTATE
            parts = line.split("\t")
            if len(parts) != 2:
                continue
            device_serial, state = parts

            # Skip the unauthorized entry
            if state == "unauthorized":
                print(f"  [WARN] Device '{device_serial}' is unauthorized. Please accept it on the device.")
                continue

            if serial:
                if device_serial == serial:
                    print(f"  Found targeted device '{serial}' (state: {state}).")
                    return device_serial
                else:
                    continue

            # Filter for USB-connected devices (state 'device' means adb sees it;
            # 'offline' means the connection is not healthy)
            if state == "device":
                print(f"  Found USB-connected device '{device_serial}' (state: {state}).")
                return device_serial
            else:
                print(f"  Waiting for device... (current: {device_serial} [{state}])")

        time.sleep(1)

    elapsed = time.perf_counter() - start
    print(f"  [FAIL] No USB-connected Android device appeared within {elapsed:.1f}s.")
    return None
