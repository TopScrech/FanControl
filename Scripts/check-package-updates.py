#!/usr/bin/env python3
"""Emit package update warnings, caching successful checks for 15 minutes"""
import concurrent.futures
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

CACHE_SECONDS = 15 * 60


def warning(message):
    return 'warning: Package updates: ' + ' '.join(message.splitlines())


def find_tool():
    return shutil.which('swift-outdated') or next(
        (str(p) for p in (Path('/opt/homebrew/bin/swift-outdated'),
                          Path('/usr/local/bin/swift-outdated')) if p.is_file()), None)


def check_branch(pin, environment):
    name = pin.get('identity', pin.get('package', 'package'))
    state = pin['state']
    branch = state['branch']
    try:
        result = subprocess.run(
            ['git', 'ls-remote', '--exit-code', '--heads',
             pin.get('location', pin.get('repositoryURL')), 'refs/heads/' + branch],
            env=environment, capture_output=True, text=True, timeout=15)
        matches = [line.split()[0] for line in result.stdout.splitlines()
                   if line.split()[-1:] == ['refs/heads/' + branch]]
        if result.returncode or not matches:
            return [warning(f'Could not check {name} branch {branch}; will retry next build')], False
        remote = matches[0]
        current = state.get('revision', '')
        if remote != current:
            return [warning(f'{name} branch {branch} has a different remote HEAD '
                            f'({current[:12]} -> {remote[:12]}); update package dependencies')], True
        return [], True
    except (OSError, subprocess.TimeoutExpired):
        return [warning(f'Could not check {name} branch {branch}; will retry next build')], False


def collect(project, resolved, tool, environment):
    messages = []
    success = True
    command = [tool, '--no-cache', '--include-transitive', '--ignore-prerelease', str(project)]
    # Xcode's checkouts live beside Build, regardless of the DerivedData location
    build_dir = environment.get('BUILD_DIR')
    if build_dir:
        checkouts = Path(build_dir).parent.parent / 'SourcePackages/checkouts'
        if checkouts.is_dir():
            command += ['--checkouts-path', str(checkouts)]
    try:
        result = subprocess.run(command, cwd=project, env=environment,
                                capture_output=True, text=True, timeout=30)
        messages += [line for line in result.stdout.splitlines() if line.startswith('warning:')]
        if result.returncode or result.stderr.strip():
            messages.append(warning('Version check was incomplete; will retry next build'))
            success = False
    except (OSError, subprocess.TimeoutExpired):
        messages.append(warning('Version check did not finish; will retry next build'))
        success = False
    data = json.loads(resolved.read_text())
    pins = data.get('pins', data.get('object', {}).get('pins', []))
    branches = [pin for pin in pins if pin.get('state', {}).get('branch')]
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for warnings, checked in pool.map(lambda pin: check_branch(pin, environment), branches):
            messages.extend(warnings)
            success = success and checked
    return messages, success


def main():
    project = Path(os.environ.get('SRCROOT', Path(__file__).resolve().parents[1])).resolve()
    project_file = os.environ.get('PROJECT_FILE_PATH')
    candidates = ([Path(project_file) / 'project.xcworkspace/xcshareddata/swiftpm/Package.resolved']
                  if project_file else list(project.glob('*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved')))
    resolved = next((path for path in candidates if path.is_file()), None)
    if resolved is None:
        print(warning('Package.resolved was not found; resolve package dependencies first'))
        return
    tool = find_tool()
    if tool is None:
        print(warning('Install swift-outdated with brew install swift-outdated to enable version and branch checks'))
        return
    environment = os.environ.copy()
    environment.update(XCODE_VERSION_ACTUAL=environment.get('XCODE_VERSION_ACTUAL', '1'),
                       GIT_TERMINAL_PROMPT='0', GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10')
    fingerprint = hashlib.sha256(resolved.read_bytes() + Path(__file__).read_bytes()
                                 + f'{tool}:{Path(tool).stat().st_mtime_ns}'.encode()).hexdigest()
    directory = Path.home() / 'Library/Caches/PackageUpdateChecks' / hashlib.sha256(str(project).encode()).hexdigest()
    directory.mkdir(parents=True, exist_ok=True)
    cache_file = directory / 'results.json'
    with (directory / 'check.lock').open('a') as lock:
        # Separate Xcode invocations share the cache without partial writes or duplicate requests
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            cached = json.loads(cache_file.read_text())
        except (OSError, ValueError):
            cached = {}
        age = time.time() - cached.get('checked_at', 0)
        if cached.get('fingerprint') == fingerprint and 0 <= age < CACHE_SECONDS:
            print('Package update check: cached results (15-minute TTL)')
            messages = cached['messages']
        else:
            print('Package update check: fetching release tags and branch HEADs')
            messages, success = collect(project, resolved, tool, environment)
            if success:
                temporary = directory / 'results.tmp'
                temporary.write_text(json.dumps({'fingerprint': fingerprint,
                                                  'checked_at': time.time(), 'messages': messages}))
                temporary.replace(cache_file)
        for message in messages:
            print(message)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # An advisory dependency check must not prevent compiling or archiving
        print(warning(f'Check unavailable ({type(error).__name__}); will retry next build'))
