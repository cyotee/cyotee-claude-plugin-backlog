---
description: Force exit from stop hook loop (escape hatch)
argument-hint: [reason]
allowed-tools: Bash
---

# Force Stop

Emergency escape hatch when the stop hook is looping and you need to exit.

**Arguments:** $ARGUMENTS

## Instructions

This command creates an exit flag that the stop hook will honor, then outputs a promise tag.

### Step 1: Create Exit Flag

```bash
mkdir -p .claude
touch .claude/backlog-exit
```

### Step 2: Output Promise

Output the following (the stop hook will see this and allow exit):

```
<promise>BLOCKED: user_forced_stop</promise>
```

**Do not output anything else after the promise tag.**
