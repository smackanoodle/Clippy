# Clippy

A local AI assistant for the Linux desktop (built on Fedora KDE), running entirely on your own machine through [LM Studio](https://lmstudio.ai). It has two parts:

- **Clippy** (`clippy.py`): a paperclip that lives in the system tray. Ask it to dim the screen, pause the music, find a file, or tell you what's eating your RAM. It always asks before acting.
- **Clippy Daemon** (`clippy_daemon.py`): a terminal agent for command-line work. It runs shell commands, edits files, uses Agent Skills and MCP servers, and can do everything in a copy-on-write **sandbox** first so you can review the changes before they touch your real system.

Both are single Python files designed for **small local models** (tested with a 4B model on CPU with a small context window). They keep prompts and tool lists short so the model stays fast and on task.

> Not affiliated with or endorsed by Microsoft. The paperclip is drawn in code.

---

## Clippy (tray assistant)

- Lives in the tray and drops down a chat panel.
- **Two-stage tools:** keywords (or a quick router call) choose which tools the model sees, so the prompt stays small.
- **Built-in tools:** brightness, volume, media controls, Wi-Fi, Bluetooth, power profile, lock screen, open apps / URLs / System Settings pages, system info, a live system monitor, screenshots, timers, file search, text search, folder trees, reading files and listing the Trash.
- **Every action asks first.** You can let specific harmless tools (volume, brightness...) run without asking.
- Credential folders (`~/.ssh`, `~/.gnupg`, browser profiles, keyrings...) are off limits to file tools.
- A settings dialog for the model, server, context length, temperature, approvals and Clippy Daemon.
- The **`>_` button** opens Clippy Daemon in a terminal, unloading Clippy's model first if you want the RAM back.

Adding a tool means writing a function and putting a `@reg(...)` line above it.

## Clippy Daemon (terminal agent)

```sh
python3 clippy_daemon.py                       # interactive session
python3 clippy_daemon.py -p "task"             # one-shot (scripts/cron); add --yes to skip approvals
git diff | python3 clippy_daemon.py -p "write a commit message for this"
```

- **Tools:** `bash`, `read`, `write`, `edit`, `glob`, `grep`, plus any **MCP servers** from standard `mcp.json` files (stdio or HTTP).
- **Skills:** standard [Agent Skills](https://agentskills.io) folders (`<name>/SKILL.md`), the same format used by OpenClaw, Claude Code and LM Studio. It looks in `./.agents/skills`, `~/.config/clippy/skills`, `~/.agents/skills`, `~/.openclaw/skills` and `~/.lmstudio/skills`.
- **`AGENTS.md` / `CLAUDE.md`** in the working folder are added to the instructions.
- **Approvals:** `ask`, `auto-edit` or `yolo`. At any prompt you can also type feedback instead of yes/no.
- Live status line with timers, tokens/s and a context-usage bar. The conversation is compacted automatically when it gets long.

### Sandbox mode

Start with `--sandbox` (or turn it on in settings). Tools then run inside [bubblewrap](https://github.com/containers/bubblewrap):

- Your home folder is a **copy-on-write overlay**, so nothing real changes.
- System folders are read-only, credential folders are hidden and `sudo` is blocked.
- Every action is recorded.

Then:

| Command | What it does |
|---|---|
| `/review` | Shows changed files (with diffs) and the recorded actions |
| `/apply` | Replays the recorded actions on the real system one at a time, then checks that the result matches the sandbox |
| `/apply files` | Copies the sandbox's resulting files over instead (deletions go to the Trash) |
| `/discard` | Throws the sandbox away |

At each step of `/apply` you can **`[e]dit`** the step before it runs (rename a file, change a title, move it to another folder). You can also **`[r]eplace`** a piece of text, such as a project name, in that step and every step after it. Edits never touch the sandbox's own record.

### Notifications

`/notify` sets a script to run whenever a request finishes, which is handy for long jobs. It can write a starter script that shows a KDE notification and plays a sound. The script receives `CLIPPY_STATUS`, `CLIPPY_REPLY`, `CLIPPY_PROMPT`, `CLIPPY_SECONDS` and more as environment variables.

### Commands

```
/help  /tools  /skills  /mcp  /skill NAME  /mode ask|auto-edit|yolo  /cd PATH  /reset
/thinking  /review  /apply [files]  /discard  /notify [PATH|test|off]  /exit
!COMMAND   run a shell command yourself; its output is shared with the model
```

---

## Install

You need **Linux with KDE Plasma** (other desktops mostly work too), **Python 3.10+** and **LM Studio** with its `lms` CLI. LM Studio is not included: install it, download a model with tool-calling support and start its local server.

```sh
sudo dnf install -y python3-pyqt6 brightnessctl playerctl ripgrep bubblewrap   # Fedora
git clone https://github.com/smackanoodle/Clippy.git
cd Clippy
./install.sh        # checks dependencies, installs the daemon sprite, adds Clippy to autostart
python3 clippy.py &
```

`./install.sh --no-autostart` skips the login entry, and `./install.sh --uninstall` removes it. Keep `clippy.py` and `clippy_daemon.py` in the same folder, because Clippy finds the daemon next to itself.

## Configuration

Everything lives in `~/.config/clippy/`:

| File | Purpose |
|---|---|
| `settings.json` | All settings. Clippy's are top-level keys and the daemon's are `daemon_*`. Edit them in Clippy → Settings. |
| `skills/` | Your Agent Skills |
| `mcp.json` | MCP servers: `{"mcpServers": {"name": {"command": "...", "args": [...]}}}` |
| `clippy_daemon.png` | The daemon's pixel-art mascot (edit freely) |
| `notify.sh` / `notify.log` | The `/notify` script and its output |

The sandbox's data lives in `/var/tmp/clippy-sandbox-$UID`. It has to be outside `$HOME` because overlayfs won't stack a folder on top of itself.

## Credits

- **Idea, design and refinement:** [@smackanoodle](https://github.com/smackanoodle). They came up with the project, decided how it should behave and look, tested it on real hardware, and shaped it through many rounds of feedback into something actually usable day to day.
- **Code:** written by **Claude** (Anthropic's AI model) in [Claude Code](https://claude.com/claude-code), based on that direction.

## License

[GPL-3.0](LICENSE)
