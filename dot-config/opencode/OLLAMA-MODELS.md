# Ollama Models for OpenCode Agents

## Required Models

| Model | Size | Context | Agent(s) | Pull Command |
|-------|------|---------|----------|--------------|
| deepseek-r1:70b | 43GB | 128K | Muse | `ollama pull deepseek-r1:70b` |
| deepseek-r1:32b | 20GB | 128K | Demiurge | `ollama pull deepseek-r1:32b` |
| qwen3-coder:30b | 19GB | 256K | Sage | `ollama pull qwen3-coder:30b` |
| devstral:24b | 14GB | 128K | Scribe | `ollama pull devstral:24b` |
| qwen2.5-coder:7b | 5GB | 32K | Pyre, Archivist | `ollama pull qwen2.5-coder:7b` |

**Total Storage**: ~101GB

## Memory Analysis (128GB M2 Ultra)

| Scenario | Active Models | VRAM | Status |
|----------|--------------|------|--------|
| Muse + Sage + Archivist | 70b + 30b + 7b | ~67GB | Safe |
| Muse + Scribe + Archivist | 70b + 24b + 7b | ~62GB | Safe |
| ALL models loaded | Total | ~101GB | Fits with margin |

## Declarative Management (Nix)

Models are managed declaratively in `nix-configs/modules/hosts/studio.nix`:
```nix
services.ollama.models = [
  "deepseek-r1:70b"
  "deepseek-r1:32b"
  "qwen3-coder:30b"
  "devstral:24b"
  "qwen2.5-coder:7b"
];
```

Run `darwin-rebuild switch` to pull any missing models.

## Manual Pull (All Models)

```bash
ollama pull deepseek-r1:70b
ollama pull deepseek-r1:32b
ollama pull qwen3-coder:30b
ollama pull devstral:24b
ollama pull qwen2.5-coder:7b
```
