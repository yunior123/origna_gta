#!/usr/bin/env python3
import argparse
import os
import signal
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path


def _read_mem_used_percent_macos() -> float | None:
    try:
        vm = subprocess.run(["vm_stat"], capture_output=True, text=True, check=True)
        sysctl = subprocess.run(
            ["sysctl", "-n", "hw.memsize"],
            capture_output=True,
            text=True,
            check=True,
        )

        total_bytes = float(sysctl.stdout.strip())
        page_size = 4096.0
        free_pages = 0.0
        speculative_pages = 0.0

        for line in vm.stdout.splitlines():
            line = line.strip()
            if line.startswith("Mach Virtual Memory Statistics") and "page size of" in line:
                try:
                    part = line.split("page size of", 1)[1].split("bytes", 1)[0].strip()
                    page_size = float(part)
                except Exception:
                    page_size = 4096.0
                continue

            if ":" not in line:
                continue

            key, value = line.split(":", 1)
            pages = value.strip().rstrip(".").replace(".", "")
            pages = pages.replace("\t", "").replace(" ", "")
            if not pages.isdigit():
                continue

            page_count = float(pages)
            if key.strip() == "Pages free":
                free_pages = page_count
            elif key.strip() == "Pages speculative":
                speculative_pages = page_count

        available_bytes = (free_pages + speculative_pages) * page_size
        used_ratio = 1.0 - max(0.0, min(1.0, available_bytes / total_bytes))
        return used_ratio * 100.0
    except Exception:
        return None


def _read_disk_used_percent(path: Path) -> float | None:
    try:
        usage = shutil.disk_usage(path)
        if usage.total <= 0:
            return None
        return (usage.used / usage.total) * 100.0
    except Exception:
        return None


def _resource_watchdog(
    process: subprocess.Popen,
    project_dir: Path,
    mem_limit_pct: float,
    disk_limit_pct: float,
    check_interval_sec: int,
    stop_event: threading.Event,
) -> None:
    while not stop_event.is_set() and process.poll() is None:
        mem_used = _read_mem_used_percent_macos()
        disk_used = _read_disk_used_percent(project_dir)

        if mem_used is not None and mem_used >= mem_limit_pct:
            print(
                f"⛔ Resource guard: RAM used {mem_used:.1f}% >= {mem_limit_pct:.1f}%. Killing flutter drive to protect machine.",
                flush=True,
            )
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except Exception:
                pass
            return

        if disk_used is not None and disk_used >= disk_limit_pct:
            print(
                f"⛔ Resource guard: Disk used {disk_used:.1f}% >= {disk_limit_pct:.1f}%. Killing flutter drive to protect machine.",
                flush=True,
            )
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except Exception:
                pass
            return

        time.sleep(max(2, check_interval_sec))


def _cleanup_automation_processes(*, include_chromedriver: bool = False) -> None:
    patterns = [
        "flutter drive --driver=test_driver/integration_test.dart",
        "Google Chrome.*--user-data-dir=.*/scoped_dir",
        "Google Chrome.*--test-type=webdriver",
    ]

    if include_chromedriver:
        patterns.insert(0, "chromedriver --port=4444")

    for pattern in patterns:
        try:
            subprocess.run(["pkill", "-f", pattern], check=False)
        except Exception:
            pass


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run flutter drive with a hard timeout and kill process group on timeout.",
    )
    parser.add_argument("--timeout", type=int, default=900, help="Timeout in seconds")
    parser.add_argument(
        "--project-dir",
        default="origna_gta",
        help="Project directory where flutter drive is executed",
    )
    parser.add_argument(
        "--target",
        default="integration_test/all_tests.dart",
        help="Integration test target",
    )
    parser.add_argument(
        "--driver",
        default="test_driver/integration_test.dart",
        help="Driver file",
    )
    parser.add_argument("--device", default="chrome", help="Flutter device")
    parser.add_argument(
        "--mem-limit-pct",
        type=float,
        default=92.0,
        help="Stop run if RAM usage reaches this percentage",
    )
    parser.add_argument(
        "--disk-limit-pct",
        type=float,
        default=95.0,
        help="Stop run if disk usage reaches this percentage",
    )
    parser.add_argument(
        "--resource-check-interval",
        type=int,
        default=10,
        help="Resource watchdog check interval (seconds)",
    )
    args = parser.parse_args()

    lock_path = Path(tempfile.gettempdir()) / "origna_gta_flutter_drive.lock"
    lock_fd = None

    root_dir = Path(__file__).resolve().parents[1]
    project_dir = (root_dir / args.project_dir).resolve()

    cmd = [
        "flutter",
        "drive",
        "--no-pub",
        f"--driver={args.driver}",
        f"--target={args.target}",
        "-d",
        args.device,
        "--dart-define=ENVIRONMENT=dev",
        "--dart-define=USE_EMULATORS=false",
    ]

    if args.device == "web-server":
        cmd.extend([
            "--browser-name=chrome",
            "--headless",
            "--dart-define=FIREBASE_PROJECT_ID=orignagta-dev",
        ])

    print(f"▶ Running: {' '.join(cmd)}")
    print(f"▶ CWD: {project_dir}")
    print(f"▶ Hard timeout: {args.timeout}s")
    print(
        f"▶ Resource guard: RAM<{args.mem_limit_pct:.1f}% Disk<{args.disk_limit_pct:.1f}% (every {args.resource_check_interval}s)",
    )

    _cleanup_automation_processes()

    try:
        lock_fd = os.open(str(lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.write(lock_fd, str(os.getpid()).encode())
    except FileExistsError:
        existing_pid = None
        try:
            raw = lock_path.read_text().strip()
            existing_pid = int(raw) if raw else None
        except Exception:
            existing_pid = None

        is_running = False
        if existing_pid:
            try:
                os.kill(existing_pid, 0)
                is_running = True
            except OSError:
                is_running = False

        if is_running:
            print(f"⛔ Une exécution flutter drive est déjà en cours (pid={existing_pid}).")
            return 2

        try:
            lock_path.unlink()
        except Exception:
            pass

        lock_fd = os.open(str(lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.write(lock_fd, str(os.getpid()).encode())

    process = subprocess.Popen(cmd, cwd=str(project_dir), preexec_fn=os.setsid)
    stop_event = threading.Event()
    watcher = threading.Thread(
        target=_resource_watchdog,
        args=(
            process,
            project_dir,
            args.mem_limit_pct,
            args.disk_limit_pct,
            args.resource_check_interval,
            stop_event,
        ),
        daemon=True,
    )
    watcher.start()

    try:
        return process.wait(timeout=args.timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        print(f"⛔ Hard-timeout atteint ({args.timeout}s): process group killed")
        return 124
    finally:
        stop_event.set()
        try:
            watcher.join(timeout=1)
        except Exception:
            pass
        _cleanup_automation_processes()
        try:
            if lock_fd is not None:
                os.close(lock_fd)
        except Exception:
            pass
        try:
            if lock_path.exists():
                lock_path.unlink()
        except Exception:
            pass


if __name__ == "__main__":
    sys.exit(main())
