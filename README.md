# Codex Desktop Plugin Repair Safety Kit

A conservative Windows toolkit for diagnosing a Codex Desktop state where the
Browser, Chrome, or Computer Use plugin is visible but its runtime tool is not
available in a newly created task.

- `Test-CodexDesktopPluginHealth.ps1` performs read-only checks.
- `Repair-StaleNodeReplPipeConfig.ps1` removes only stale, task-specific native
  pipe entries from the `node_repl` environment table. It is a dry run unless
  `-Apply` is supplied, and it creates a timestamped backup before writing.

It does **not** modify the Microsoft Store package, WindowsApps, application
signatures, browser profiles, authentication data, or unrelated plugins.

## Usage

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Test-CodexDesktopPluginHealth.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Repair-StaleNodeReplPipeConfig.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Repair-StaleNodeReplPipeConfig.ps1 -Apply
```

After a repair, fully exit and reopen Codex Desktop yourself, then create a new
task. Tool availability is determined when a task starts.

## Safety notes

- Review every script before running it.
- Keep backups private; configuration can contain sensitive local values.
- Never paste full logs or configuration files into public issues.
- Store updates may change runtime details. Prefer the latest official package.
- A visible plugin entry is not proof that its runtime transport works.

