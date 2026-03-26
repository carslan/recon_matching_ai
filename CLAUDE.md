## Immediate Load
Immediately read these files at session start before doing anything else:
- Memory.md
- LastAction.md
- Features.md
- TODOS/active.md
- active.version
- Session Notes/{latest session based on timestamp}

### Session Start Behavior
1. Read all immediate-load files above
2. Confirm active version: read `active.version`, verify symlinks at `source_code/frontend` and `source_code/backend`
3. Present TODOS/active.md to user — ask if priorities have changed or if new items should be added before proceeding
4. If LastAction.md shows an incomplete action, surface it and ask whether to resume or deprioritize
5. Search Mem0 for relevant context: `search_memory(query="recon-matching", user_id="recon-matching")` — surface anything useful before starting work

### Deferred Load Rules
- Never read source_code unless a code task is confirmed
- Load Docs/ files only when directly relevant to the task at hand
- Load logs/ only when debugging


### Memory.md
Persistent facts about this app that must never be forgotten across sessions.
Examples: why a key architectural decision was made, a constraint that cannot change, a past failure and what caused it, a hard dependency.

**Read:** Always, at session start.
**Write:** When something happens that must be remembered in future sessions a decision with lasting impact, a confirmed constraint, a non-obvious behavior. Append only. Never delete entries unless explicitly told to.

---                                                                                                                                 

### LastAction.md

A single entry describing the most recent action taken. Used for session recovery when context is lost between conversations.

**Read:** Always, at session start. If `Status: IN_PROGRESS`, surface it to the user and ask whether to resume or deprioritize before touching anything else.
**Write:** After every meaningful action. Overwrite the entire file each time only the last action matters. Use this format:
Date: YYYY-MM-DD HH:MM
Action:
Reasoning:
Target:
Outcome:
Status: COMPLETE | IN_PROGRESS | FAILED

---                                                             
### Features.md
The authoritative list of features this app currently has. Declarative only what exists now, not what is planned (plans go in TODOS). Each feature has a name, a short description of what it does, and its current state (active / deprecated / broken).

**Read:** At session start, and when planning a new feature to avoid duplication or conflict.
**Write:** When a feature is added, changed, or removed. Keep it current — this file is what Claude uses to understand the app without reading all the source code.

---                                                                                                                                 

### TODOS/active.md
The current work list. Each item has a status: `not started` or `in progress`.
**Read:** At session start. After reading, present the list to the user and ask:
"Are these still the priorities, or do you want to add/change anything before we start?" 
Do not begin any work until this handshake is done.
**Write:** Update status as work progresses. Move completed items to `TODOS/completed.md`
— never delete them from `active.md`, just move them.Format:                                                                                                                             [YYYY-MM-DD] Short title

Status: not started | in progress
Description: what needs to be done and why

### TODOS/completed.md
Archive of finished TODO items. Append only — never modify existing entries.
Read only when explicitly asked about history or to avoid re-doing past work.

---                                                             

### versions/{version}/updates.md
A changelog for a specific version. Documents all changes made in that version:
new features, fixes, removals, documentation updates, config changes.

**Read:** When debugging a regression, reviewing change history, or before cutting a new version.
**Write:** After every meaningful change within a version. Append only. Use this format:
YYYY-MM-DD HH:MM —

Type: feature | fix | removal | refactor | docs | config
Description: what changed and why

---

### Session Notes
Read the latest session notes by looking at the filename. filename will contain the timestamp, and pick the latest session file and read what happened.

during the active session, if you need more history, you can read the historical sessions as needed.

sessions location: `/home/che/LocalAppStore/Apps/recon-matching/Session Notes`

---

## Intelligence Layer (Obsidian & Mem0)

Two additional memory tools are available during development sessions. Use them alongside the file-based memory system above — they are not replacements.

### Obsidian
Vault location: `~/.claude/obsidian_vault/projects/recon-matching/`

**Write to Obsidian when:**
- An architectural decision is made that has lasting impact beyond this app's Memory.md
- A pattern or solution is discovered that could benefit other projects
- Cross-project knowledge is generated (e.g. a reusable approach, a gotcha with a library)

**How:** Use `obsidian-mcp` tools to write/update notes in `projects/recon-matching/`.
Suggested files: `decisions.md`, `context.md`, `notes.md`

**Do not duplicate** what is already in Memory.md — Obsidian is for knowledge that benefits from being searchable across projects.

### Mem0
Scope all Mem0 operations to this app using `user_id="recon-matching"`.

**Write to Mem0 when:**
- A non-obvious constraint or behavior is confirmed (e.g. "port 4023 is hardcoded in nginx config")
- A user preference specific to this app is established
- A bug root cause is identified that could recur
- A pattern is discovered about how this app behaves under certain conditions

**How:** Use `add_memory(content="...", user_id="recon-matching")` after meaningful discoveries.

**Search Mem0** at session start (step 5 above) and whenever starting a new task that might benefit from past context.

### When NOT to use them
- Do not write to Obsidian/Mem0 for routine actions already captured in LastAction.md or updates.md
- Do not duplicate Memory.md content into Mem0 — they serve different scopes
- Mem0 is for facts. Obsidian is for knowledge. Session Notes are for narrative.

---

## Directory Structure
Application must have this structure at minimum:

```
Apps/recon-matching/
├── start.sh                    ← starts the process, writes PID to .pid, logs to server.log
├── stop.sh                     ← kills process by PID from .pid file
├── restart.sh                  ← calls stop.sh, waits 1 second, calls start.sh
├── url.info                    ← single line: http://10.219.31.248:{port}
├── server.log                  ← created at runtime by start.sh (stdout/stderr of the process)
├── active.version              ← a text file that shows actively running version
├── logs/                       ← application's internal structured logs.
    └── $date (YYYY-MM-DD)
        └── HH_MM_ss.log        ← the time log has started 
├── public/
    └── icon.svg                ← app icon shown in LocalAppStore (72x72, dark background)
├── source_code/
    ├── frontend                ← front-end related code (by using `active.version` a symlink to `versions/{active.version}/frontend)
    └── backend                 ← backend related code   (by using `active.version` a symlink to `versions/{active.version}/backend)
├── backup/                     
        └── {YYYY-MM-DD_HHMMSS}
            └── v{version_number}
                ├── frontend/
                └── backend/            
├── versions/
    └── v1
        └── frontend/
            └──  ...
        └── backend/
            └──  ...
        └── updates.md          ← all made changes, code changes, improvements, new features, dropped features, fixes, documentation updates, etc ...
├── Docs/
    ├── implementation.md       ← business logic, architecture, decisions, data flow, roadmap
    ├── how-to-use.md           ← end-user guide: how to run, access, and operate the app
    └── config.md               ← all configurable parameters, env vars, and how to change them
├── TODOS/
    ├── active.md               ← TODO list items with status [in progress, not started yet]
    └── completed.md            ← TODO list items that are completed
├── Session Notes/
    └── sesssion_{yyyy_mm_dd_HH_MM}.md
    └── session_...
├── LastAction.md               ← the last action was taken by agent with explanation, reasoning, target goal and outcome. This way in case 
                                  we lose the session for some reason, we always have the ability of recovering
                                  must be `machine-readable` formatting
                                  ```example
                                   ## Last Action
                                   **Date:** 2026-03-24 14:32
                                   **Action:** Refactored auth middleware to use JWT
                                   **Reasoning:** Old session token storage flagged by security review
                                   **Target:** Complete stateless auth, remove redis session dependency
                                   **Outcome:** INCOMPLETE — frontend still sending cookie headers, needs update in source_code/frontend/src/api.js
                                   **Status:** IN_PROGRESS
                                   ```
├── Memory.md                   ← Memories related to application history that must be always remembered
├── Features.md                 ← All available (existing and working and implemented) features of the application and how they work and what they do
```

---

## Server Scripts
If and when you need to understand `start.sh, stop.sh, restart.sh` then read the file
`/home/che/LocalAppStore/Apps/recon-matching/ServerScripts.md`

---

## Backup 

**Before Update**
Before making any code changes to an existing application, the entire app directory must be backed up first.

**Backup location:**
```
/home/che/LocalAppStore/Apps/recon-matching/backup/{YYYY-MM-DD_HHMMSS}/...
```

**Backup steps:**
1. Create the backup directory: `mkdir -p /home/che/LocalAppStore/Apps/recon-matching/backup/{YYYY-MM-DD_HHMMSS}`
2. Copy the full frontendt directory : `cp -r /home/che/LocalAppStore/Apps/recon-matching/versions/v{active.version}/frontend/. /home/che/LocalAppStore/Apps/recon-matching/backup/{YYYY-MM-DD_HHMMSS}/v{active.version}/frontend`
3. Copy the full frontendt directory : `cp -r /home/che/LocalAppStore/Apps/recon-matching/versions/v{active.version}/backend/. /home/che/LocalAppStore/Apps/recon-matching/backup/{YYYY-MM-DD_HHMMSS}/v{active.version}/backend`
4. Confirm the backup exists before touching any source file
5. Only then proceed with code changes

The timestamp in the backup directory name uses the local time at the moment of backup (`date +%Y-%m-%d_%H%M%S`).

Backups are never deleted automatically. If disk space is a concern, the user will manage cleanup manually.

## Logging Standard

All applications must use structured logging at **INFO level**.

Rules:
- Log only critical events and operations — not every function call or loop iteration
- Examples of what TO log: app started, app stopped, request received, external API called, error occurred, background job completed, configuration loaded
    - whatever considered critical
- Examples of what NOT to log: debug traces, variable dumps, routine health checks, every SSE ping

For Python apps use `loguru`:
```python
from loguru import logger
logger.info("Server started on port {port}", port=4002)
logger.error("Failed to connect to database: {err}", err=e)
```

For Node.js apps use `console.log` with ISO timestamps or a simple logger.

The `logs/` directory inside the app is for the application's own structured logs.
`server.log` in the app root is the raw stdout/stderr from the process (written by `start.sh`).
Both serve different purposes — do not conflate them.

---

## Documentation
**`implementation.md`** — written for the next developer or Claude agent who will maintain or extend this app. Must include:
- Why this app was built (the need/problem it solves)
- Architecture overview (components, data flow)
- Key technical decisions and why they were made
- Known limitations
- Dependencies and external services used

**`how-to-use.md`** — written for the end user. Must include:
- How to start and access the app
- Step-by-step usage instructions
- All available features explained
- Common troubleshooting

**`config.md`** — written for anyone who needs to change the app's behaviour. Must include:
- Every environment variable or config file entry
- What each setting does
- Valid values and defaults
- Which settings require a restart to take effect

## Post-Task Save Protocol

After **every** task completes — whether it is a code change, bug fix, feature addition, investigation, or decision — check each required file and save if anything changed:

1. **LastAction.md** — always overwrite with the completed action, outcome, and `Status: COMPLETE`
2. **Features.md** — update if any feature was added, changed, broken, or fixed
3. **Memory.md** — append if any new architectural decision, constraint, bug root cause, or non-obvious behavior was discovered
4. **versions/{active.version}/updates.md** — append a changelog entry if any code changed
5. **TODOS/active.md** — mark items `in progress` or move completed ones to `TODOS/completed.md`
6. **Obsidian** — if any architectural decision, cross-project pattern, or reusable knowledge was generated, write it to `~/.claude/obsidian_vault/projects/recon-matching/`
7. **Mem0** — if any non-obvious constraint, bug root cause, or app-specific behavior was confirmed, add it: `add_memory(content="...", user_id="recon-matching")`

**If the task outcome was wrong or later corrected:**
- Update `LastAction.md` with the corrected outcome and what was wrong
- Update `Features.md` if the feature description was inaccurate
- Update `Memory.md` if a previously saved fact was wrong — correct it in place, do not leave stale entries

Do not wait to be reminded. These saves are part of task completion, not optional follow-up.

---

## Important
The loaded application might be in old structure. for now, if not present, then create files and folder structures for;
- `versions` structure
- `active.version` file
- `TODOS` structure
- `LastAction.md` file
- `Memory.md` file
- `Features.md` file

and accordingly when needed work on them.
