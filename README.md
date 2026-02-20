# TaskSplitter ✂️

AI-powered task decomposition in your menu bar. Write a vague task, get actionable subtasks. Click "Split" again to go deeper.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- ✂️ AI splits any task into 3-5 actionable subtasks (~15 min each)
- 🔄 Recursive splitting — click "Split" on any subtask to go deeper
- ✅ Check off completed tasks
- 💾 Persistent storage (survives app restart)
- 🪶 Native Swift — ultra lightweight (100 Ko)
- 🚫 No dock icon — lives in your menu bar
- 🇫🇷 French UI

## Install

### Download (recommended)

1. Download [TaskSplitter-macOS.zip](https://github.com/Real-Pixeldrop/task-splitter/releases/latest/download/TaskSplitter-macOS.zip)
2. Unzip
3. Double-click `TaskSplitter`
4. Done — the ✂️ icon appears in your menu bar

### Terminal one-liner

```bash
curl -sL https://github.com/Real-Pixeldrop/task-splitter/releases/latest/download/TaskSplitter-macOS.zip -o /tmp/ts.zip && sudo unzip -o /tmp/ts.zip -d /usr/local/bin && TaskSplitter &
```

### From source

```bash
git clone https://github.com/Real-Pixeldrop/task-splitter.git
cd task-splitter
swift build -c release
.build/release/TaskSplitter
```

## Setup

1. Launch TaskSplitter
2. Click ⚙️ in the top-right
3. Choose your AI provider:
   - **Anthropic (Claude)** — fast and smart, needs API key
   - **OpenAI (GPT)** — versatile, needs API key
   - **Ollama (Local)** — free, runs on your Mac, no key needed
4. Start splitting tasks

## Usage

1. Click the ✂️ icon in your menu bar
2. Type a task: "Refaire le site de mon client"
3. AI splits it into subtasks automatically
4. Click **Split** on any subtask to break it down further
5. Check off tasks as you complete them

## How it works

- Uses Claude API to decompose tasks intelligently
- Each subtask is actionable and concrete (~15 min)
- Recursive: split → split → split until tasks are trivial
- History saved in `~/Library/Application Support/TaskSplitter/`

## AI Providers

| Provider | Key needed | Cost | Speed |
|----------|-----------|------|-------|
| Anthropic (Claude) | Yes | Pay per use | Fast |
| OpenAI (GPT) | Yes | Pay per use | Fast |
| Ollama (Local) | No | Free | Depends on hardware |

Get your keys:
- Anthropic: [console.anthropic.com](https://console.anthropic.com)
- OpenAI: [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- Ollama: [ollama.com](https://ollama.com) (install, then `ollama pull llama3.2`)

All config stored locally in `~/Library/Application Support/TaskSplitter/`. Never sent anywhere else.

## License

MIT
