#!/usr/bin/env node

/**
 * Cross-platform CLI wrapper for agent-browser
 *
 * This wrapper enables npx support on Windows where shell scripts don't work.
 * For global installs, postinstall.js patches the shims to invoke the native
 * binary directly (zero overhead).
 *
 * On Windows, this wrapper also ensures the daemon is running before
 * invoking the native binary (workaround for daemon auto-start issue).
 */

import { spawn } from 'child_process';
import { existsSync, accessSync, chmodSync, mkdirSync, constants } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { platform, arch, homedir } from 'os';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Auto-start daemon on Windows if not already running.
 * The native binary's daemon auto-start can fail on Windows,
 * so we pre-start it from Node.js.
 */
async function ensureDaemonRunning() {
  if (platform() !== 'win32') return;

  const session = process.env.AGENT_BROWSER_SESSION || 'default';
  const agentDir = join(homedir(), '.agent-browser');
  const portFile = join(agentDir, `${session}.port`);
  const pidFile = join(agentDir, `${session}.pid`);

  // If port file exists and process is alive, daemon is running
  if (existsSync(portFile) && existsSync(pidFile)) {
    try {
      const fs = await import('fs');
      const pid = parseInt(fs.readFileSync(pidFile, 'utf8').trim(), 10);
      process.kill(pid, 0); // Check if process exists
      return; // Daemon is running
    } catch {
      // Process is dead, clean up stale files and restart
    }
  }

  // Ensure directory exists
  if (!existsSync(agentDir)) {
    mkdirSync(agentDir, { recursive: true });
  }

  // Spawn daemon in detached mode
  const daemonScript = join(__dirname, '..', 'dist', 'daemon.js');
  if (!existsSync(daemonScript)) return;

  const child = spawn(process.execPath, [daemonScript], {
    detached: true,
    stdio: 'ignore',
    windowsHide: true,
    env: { ...process.env, AGENT_BROWSER_DAEMON: '1' },
  });
  child.unref();

  // Wait up to 3 seconds for port file to appear
  for (let i = 0; i < 30; i++) {
    await new Promise((resolve) => setTimeout(resolve, 100));
    if (existsSync(portFile)) return;
  }
}

// Map Node.js platform/arch to binary naming convention
function getBinaryName() {
  const os = platform();
  const cpuArch = arch();

  let osKey;
  switch (os) {
    case 'darwin':
      osKey = 'darwin';
      break;
    case 'linux':
      osKey = 'linux';
      break;
    case 'win32':
      osKey = 'win32';
      break;
    default:
      return null;
  }

  let archKey;
  switch (cpuArch) {
    case 'x64':
    case 'x86_64':
      archKey = 'x64';
      break;
    case 'arm64':
    case 'aarch64':
      archKey = 'arm64';
      break;
    default:
      return null;
  }

  const ext = os === 'win32' ? '.exe' : '';
  return `agent-browser-${osKey}-${archKey}${ext}`;
}

async function main() {
  // Pre-start daemon on Windows before invoking native binary
  await ensureDaemonRunning();

  const binaryName = getBinaryName();

  if (!binaryName) {
    console.error(`Error: Unsupported platform: ${platform()}-${arch()}`);
    process.exit(1);
  }

  const binaryPath = join(__dirname, binaryName);

  if (!existsSync(binaryPath)) {
    console.error(`Error: No binary found for ${platform()}-${arch()}`);
    console.error(`Expected: ${binaryPath}`);
    console.error('');
    console.error('Run "npm run build:native" to build for your platform,');
    console.error('or reinstall the package to trigger the postinstall download.');
    process.exit(1);
  }

  // Ensure binary is executable (fixes EACCES on macOS/Linux when postinstall didn't run,
  // e.g., when using bun which blocks lifecycle scripts by default)
  if (platform() !== 'win32') {
    try {
      accessSync(binaryPath, constants.X_OK);
    } catch {
      // Binary exists but isn't executable - fix it
      try {
        chmodSync(binaryPath, 0o755);
      } catch (chmodErr) {
        console.error(`Error: Cannot make binary executable: ${chmodErr.message}`);
        console.error('Try running: chmod +x ' + binaryPath);
        process.exit(1);
      }
    }
  }

  // Spawn the native binary with inherited stdio
  const child = spawn(binaryPath, process.argv.slice(2), {
    stdio: 'inherit',
    windowsHide: false,
  });

  child.on('error', (err) => {
    console.error(`Error executing binary: ${err.message}`);
    process.exit(1);
  });

  child.on('close', (code) => {
    process.exit(code ?? 0);
  });
}

main();
