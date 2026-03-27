---
name: debate
description: Run structured multi-agent debates from a markdown or JSON debate file using the agents-debate project runtime. Use when Codex needs to normalize legacy debate markdown, keep JSON as the canonical state, run the moderator/debater loop end-to-end, and automatically start a live local web viewer for the debate.
---

# Debate

Use the agents-debate project runtime instead of embedding debate logic in the skill itself.

## Runtime

Repository root for this installed skill: `/mnt/nas7/cysong/projects/agents-debate`.

Normalize a debate file:

```bash
python3 /mnt/nas7/cysong/projects/agents-debate/runtime/debate_state.py normalize /path/to/debate.md
```

Start the viewer server before running the debate:

```bash
python3 /mnt/nas7/cysong/projects/agents-debate/runtime/serve_viewer.py --path /path/to/debate.json
```

Run the debate:

```bash
python3 /mnt/nas7/cysong/projects/agents-debate/runtime/run_debate.py /path/to/debate.md
```

## Expectations

- Use `*.json` as the source of truth.
- Keep `*.md` as a rendered export.
- Let the runtime serialize the debate loop and state updates.
- Start the viewer server automatically whenever you run a debate through this skill.
- If the viewer server is started, tell the user to open `http://127.0.0.1:8765/`.
- Tell the user the exact JSON path being served.
- Use the viewer for live monitoring instead of parsing markdown manually when a visual timeline helps.
