#!/usr/bin/env python3
"""Run CLI Swift Testing checks with an existing CoreSMC checkout"""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("core_smc", type=Path, help="Path to an existing CoreSMC package checkout")
arguments = parser.parse_args()
project = Path(__file__).resolve().parents[2]
core_smc = arguments.core_smc.resolve()
if not (core_smc / "Package.swift").is_file():
    parser.error("CoreSMC checkout must contain Package.swift")

with tempfile.TemporaryDirectory(prefix="FanControl-CLI-tests-") as directory:
    package = Path(directory)
    sources = package / "Sources" / "FanCLITestsSupport"
    signals = package / "Sources" / "FanTimerSignals"
    tests = package / "Tests" / "FanCLITests"
    for folder in (sources, signals / "include", tests):
        folder.mkdir(parents=True)

    for filename in ("FanCLIError.swift", "FanCommand.swift", "FanCommandParser.swift", "FanTimerRequest.swift", "FanCLITimer.swift"):
        shutil.copy2(project / "CLI" / filename, sources)
    # SwiftPM exposes the C header as a module instead of Xcode's bridging header
    timer = sources / "FanCLITimer.swift"
    timer.write_text("import FanTimerSignals\n" + timer.read_text())
    shutil.copy2(project / "Shared" / "SMC" / "SMCService.swift", sources)
    shutil.copy2(project / "Shared" / "Fan" / "Fan + DisplayValues.swift", sources)
    shutil.copy2(project / "CLI" / "FanTimerSignal.c", signals)
    header = signals / "include" / "FanTimerSignal.h"
    shutil.copy2(project / "CLI" / "FanTimerSignal.h", header)
    for file in Path(__file__).parent.glob("*.swift"):
        shutil.copy2(file, tests)

    (package / "Package.swift").write_text(f'''// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FanCLIChecks",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: {json.dumps(str(core_smc))})],
    targets: [
        .target(name: "FanTimerSignals"),
        .target(
            name: "FanCLITestsSupport",
            dependencies: ["FanTimerSignals", .product(name: "CoreSMC", package: "CoreSMC")]
        ),
        .testTarget(
            name: "FanCLITests",
            dependencies: ["FanCLITestsSupport", .product(name: "CoreSMC", package: "CoreSMC")]
        )
    ],
    swiftLanguageModes: [.v5]
)
''')
    subprocess.run(
        ["xcrun", "swift", "test", "--package-path", str(package), "--scratch-path", str(package / "build")],
        check=True,
    )
