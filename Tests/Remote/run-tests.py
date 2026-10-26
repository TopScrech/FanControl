#!/usr/bin/env python3
"""Run remote timer model and compatibility checks with Swift Testing"""

from pathlib import Path
import shutil
import subprocess
import tempfile

project = Path(__file__).resolve().parents[2]

with tempfile.TemporaryDirectory(prefix="FanControl-remote-timer-tests-") as directory:
    package = Path(directory)
    sources = package / "Sources" / "RemoteTimersSupport"
    tests = package / "Tests" / "RemoteTimersTests"
    sources.mkdir(parents=True)
    tests.mkdir(parents=True)

    for filename in ("RemoteFanAction.swift", "RemoteFanState.swift", "FanSpeedTimerDraft.swift"):
        shutil.copy2(project / "RemoteShared" / "Models" / filename, sources)
    shutil.copy2(Path(__file__).with_name("RemoteTimerTests.swift"), tests)

    (package / "Package.swift").write_text('''// swift-tools-version: 6.0
import PackageDescription

let package = Package(name: "RemoteTimersSupport", targets: [
    .target(name: "RemoteTimersSupport"),
    .testTarget(name: "RemoteTimersTests", dependencies: ["RemoteTimersSupport"])
])
''')
    subprocess.run(["xcrun", "swift", "test", "--package-path", str(package)], check=True)
