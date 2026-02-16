#!/usr/bin/env python3
import argparse
import os
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime
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


def _cleanup() -> None:
    patterns = [
        "flutter drive",
        "chromedriver",
        "Google Chrome.*--test-type=webdriver",
        "Google Chrome.*--user-data-dir=.*/scoped_dir",
        "Google Chrome.*org-dartlang-app",
    ]
    for pattern in patterns:
        try:
            subprocess.run(["pkill", "-f", pattern], check=False)
        except Exception:
            pass

    try:
        Path("/tmp/origna_gta_flutter_drive.lock").unlink(missing_ok=True)
    except Exception:
        pass


def _run_attempt(
    root: Path,
    timeout_sec: int,
    mem_limit_pct: float,
    disk_limit_pct: float,
    check_interval_sec: int,
    env: dict,
    attempt_log: Path,
) -> int:
    cmd = [
        "flutter",
        "drive",
        "--no-pub",
        "--driver=test_driver/integration_test.dart",
        "--target=integration_test/all_tests.dart",
        "-d",
        "web-server",
        "--browser-name=chrome",
        "--headless",
        "--dart-define=ENVIRONMENT=dev",
        "--dart-define=USE_EMULATORS=false",
        "--dart-define=FIREBASE_PROJECT_ID=orignagta-dev",
    ]

    project_dir = root / "origna_gta"
    started = time.time()

    with attempt_log.open("w", encoding="utf-8") as log_file:
        log_file.write(f"START {datetime.now().isoformat()}\n")
        log_file.write("CMD: " + " ".join(cmd) + "\n\n")
        log_file.flush()

        chromedriver = subprocess.Popen(
            ["chromedriver", "--port=4444"],
            cwd=str(root),
            env=env,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            preexec_fn=os.setsid,
        )
        time.sleep(1.5)

        process = subprocess.Popen(
            cmd,
            cwd=str(project_dir),
            env=env,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            preexec_fn=os.setsid,
        )

        while process.poll() is None:
            elapsed = time.time() - started
            if elapsed >= timeout_sec:
                os.killpg(process.pid, signal.SIGKILL)
                log_file.write(f"\n⛔ attempt timeout ({timeout_sec}s)\n")
                log_file.flush()
                try:
                    os.killpg(chromedriver.pid, signal.SIGKILL)
                except Exception:
                    pass
                return 124

            mem_used = _read_mem_used_percent_macos()
            disk_used = _read_disk_used_percent(root)

            if mem_used is not None and mem_used >= mem_limit_pct:
                os.killpg(process.pid, signal.SIGKILL)
                log_file.write(
                    f"\n⛔ resource guard RAM: {mem_used:.1f}% >= {mem_limit_pct:.1f}%\n",
                )
                log_file.flush()
                try:
                    os.killpg(chromedriver.pid, signal.SIGKILL)
                except Exception:
                    pass
                return 137

            if disk_used is not None and disk_used >= disk_limit_pct:
                os.killpg(process.pid, signal.SIGKILL)
                log_file.write(
                    f"\n⛔ resource guard disk: {disk_used:.1f}% >= {disk_limit_pct:.1f}%\n",
                )
                log_file.flush()
                try:
                    os.killpg(chromedriver.pid, signal.SIGKILL)
                except Exception:
                    pass
                return 137

            time.sleep(max(2, check_interval_sec))

        try:
            os.killpg(chromedriver.pid, signal.SIGKILL)
        except Exception:
            pass
        return process.returncode or 0


def _wait_for_resources(
    root: Path,
    mem_limit_pct: float,
    disk_limit_pct: float,
    check_interval_sec: int,
    max_wait_sec: int,
    summary,
) -> bool:
    started = time.time()
    while time.time() - started < max_wait_sec:
        mem_used = _read_mem_used_percent_macos()
        disk_used = _read_disk_used_percent(root)

        mem_ok = mem_used is None or mem_used < mem_limit_pct
        disk_ok = disk_used is None or disk_used < disk_limit_pct
        if mem_ok and disk_ok:
            return True

        summary.write(
            f"Waiting resources... RAM={mem_used if mem_used is not None else 'n/a'} "
            f"Disk={disk_used if disk_used is not None else 'n/a'}\n",
        )
        summary.flush()
        time.sleep(max(2, check_interval_sec))

    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Run integration tests autonomously for several hours with safe guards.")
    parser.add_argument("--hours", type=float, default=5.0, help="Supervisor runtime in hours")
    parser.add_argument("--attempt-timeout", type=int, default=900, help="Timeout per attempt in seconds")
    parser.add_argument("--cooldown", type=int, default=20, help="Cooldown seconds between attempts")
    parser.add_argument("--mem-limit-pct", type=float, default=96.0, help="Max RAM usage percentage before kill")
    parser.add_argument("--disk-limit-pct", type=float, default=96.0, help="Max disk usage percentage before kill")
    parser.add_argument("--check-interval", type=int, default=5, help="Resource check interval in seconds")
    parser.add_argument("--preflight-wait", type=int, default=180, help="Max seconds to wait for resources before skipping an attempt")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    logs_dir = root / "logs" / "integration"
    logs_dir.mkdir(parents=True, exist_ok=True)

    summary_path = logs_dir / f"supervisor_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    latest_path = logs_dir / ".latest_run"

    end_at = time.time() + (args.hours * 3600)
    attempt = 0

    env = os.environ.copy()
    env["ENVIRONMENT"] = "dev"
    env["USE_EMULATORS"] = "false"
    env["FIREBASE_PROJECT_ID"] = "orignagta-dev"

    with summary_path.open("w", encoding="utf-8") as summary:
        summary.write(f"Supervisor started: {datetime.now().isoformat()}\n")
        summary.write(f"Will run for ~{args.hours} hours\n")
        summary.flush()

        while time.time() < end_at:
            attempt += 1
            _cleanup()

            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            attempt_log = logs_dir / f"supervised_attempt_{attempt:03d}_{stamp}.log"
            latest_path.write_text(str(attempt_log), encoding="utf-8")

            summary.write(f"\nAttempt {attempt} start: {datetime.now().isoformat()}\n")
            summary.write(f"Log: {attempt_log}\n")
            summary.flush()

            resources_ready = _wait_for_resources(
                root=root,
                mem_limit_pct=args.mem_limit_pct,
                disk_limit_pct=args.disk_limit_pct,
                check_interval_sec=args.check_interval,
                max_wait_sec=args.preflight_wait,
                summary=summary,
            )
            if not resources_ready:
                summary.write(f"Attempt {attempt} skipped: resources not ready after preflight wait\n")
                summary.flush()
                if time.time() + args.cooldown >= end_at:
                    break
                time.sleep(max(5, args.cooldown))
                continue

            exit_code = _run_attempt(
                root=root,
                timeout_sec=args.attempt_timeout,
                mem_limit_pct=args.mem_limit_pct,
                disk_limit_pct=args.disk_limit_pct,
                check_interval_sec=args.check_interval,
                env=env,
                attempt_log=attempt_log,
            )

            summary.write(f"Attempt {attempt} exit_code={exit_code} at {datetime.now().isoformat()}\n")
            summary.flush()

            if time.time() + args.cooldown >= end_at:
                break
            time.sleep(max(5, args.cooldown))

        _cleanup()
        summary.write(f"\nSupervisor finished: {datetime.now().isoformat()}\n")
        summary.flush()

    print(f"Supervisor summary: {summary_path}")
    print(f"Latest attempt log pointer: {latest_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
