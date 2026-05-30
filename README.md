<p align="center">
  <img src="assets/images/logo.png" width="100" alt="Vortex Agent logo" />
</p>

<h1 align="center">Vortex Agent</h1>

<p align="center">
  An AI-powered floating command palette for Windows.<br/>
  Describe any task in plain English — Vortex figures out the steps and executes them.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue?style=flat-square" />
  <img alt="Flutter" src="https://img.shields.io/badge/built%20with-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img alt="AI" src="https://img.shields.io/badge/AI-Groq%20AI%20%7C%20Cohere-blueviolet?style=flat-square" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green?style=flat-square" />
</p>

---

## Table of Contents

- [What is Vortex?](#what-is-vortex)
- [Features](#features)
- [Demo](#demo)
- [Getting Started](#getting-started)
- [AI Providers](#ai-providers)
- [Configuration](#configuration)
- [How It Works](#how-it-works)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## What is Vortex?

Vortex Agent is a lightweight Windows desktop app that floats above all your windows as a frameless pill-shaped input bar. Press **Ctrl+Q** from anywhere, type what you want, and Vortex either answers your question inline or breaks the task into PowerShell steps and runs them automatically.

It can open apps, create and run full programs in any language, control other apps' UI, manage files, search the web, take screenshots, and much more — all from plain English.

---

## Features

| | Feature | Description |
|---|---|---|
| ⚡ | **Global hotkey** | `Ctrl+Q` summons and dismisses the palette from anywhere |
| 🎯 | **Natural language tasks** | Describe what you want — Vortex figures out the steps |
| 💬 | **Smart Q&A mode** | Questions get direct answers with markdown, inline code, and code blocks |
| 🤖 | **Multi-step automation** | Breaks tasks into PowerShell steps, executes them with live output |
| 🔍 | **App discovery** | Finds Win32, UWP, and Microsoft Store apps automatically |
| 🖱️ | **UI Automation** | Clicks buttons, fills forms, controls other apps via Windows Accessibility API |
| 🛠️ | **Code generation** | Creates and runs full programs in Python, Node, HTML, C#, Flutter, and more |
| 🔀 | **Dual AI providers** | [Groq AI](https://groq.com) primary + [Cohere](https://cohere.com) automatic fallback |
| 🔄 | **Smart routing** | Switches providers silently on rate-limit — no manual action needed |
| 🚀 | **Auto-start** | Optionally launch on Windows startup |

---

## Demo

> Press **Ctrl+Q** → type → watch it happen.

| What you type | What Vortex does |
|---|---|
| `open Spotify` | Finds and launches Spotify (Win32 or Store) |
| `create a snake game in python and run it` | Installs pygame, writes full source, launches it |
| `take a screenshot and send it to John on WhatsApp` | Screenshots, opens WhatsApp, navigates to contact, pastes and sends |
| `what is the difference between TCP and UDP` | Returns a formatted answer — nothing executed on your machine |
| `create a Flutter app called demo and open it in VS Code` | Runs `flutter create`, opens VS Code |
| `search YouTube for lo-fi music` | Scrapes the first video ID, opens it directly in Chrome |

---

## Getting Started

### Prerequisites

- Windows 10 or 11 (x64)
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) with Windows desktop support enabled
- A free API key from [Groq AI](https://console.groq.com/keys) and/or [Cohere](https://dashboard.cohere.com/api-keys)

### Run from source

```powershell
git clone https://github.com/sherimello/vortex
cd vortex_agent
flutter pub get
flutter run -d windows
```

### Build a release executable

```powershell
cd vortex_agent
flutter build windows --release
# Output: build\windows\x64\runner\Release\vortex_agent.exe
```

### Build the installer

Install [Inno Setup 6](https://jrsoftware.org/isdl.php) first:

```powershell
winget install JRSoftware.InnoSetup
```

Then compile from the repo root:

```powershell
# Inno Setup installs to LocalAppData, not Program Files
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" vortex_setup.iss
# Output: installer\VortexAgent_Setup.exe
```

---

## AI Providers

Vortex uses **[Groq AI](https://groq.com)** and **[Cohere](https://cohere.com)** as its AI backends. Both have free tiers — no credit card required.

> **Note:** Groq AI (`groq.com`) is a fast inference platform and is **not** related to xAI's Grok chatbot.

### Groq AI — Primary Provider

Groq runs open-weight models (`llama-3.3-70b`, `mixtral-8x7b`, `llama-3.1-8b`) on custom LPU hardware, delivering responses in ~1–2 seconds. Vortex uses it as the primary provider for this reason.

- **Free tier** — generous daily token limits, no credit card needed
- **Auto model selection** — picks a lighter model for simple tasks, a larger one for complex ones
- **Rate-limit handling** — on a 429, enters a 65-second cooldown (matches Groq's TPM window) then retries

### Cohere — Fallback Provider

[Cohere](https://cohere.com)'s `command-r` model kicks in automatically whenever Groq is rate-limited or its key is invalid. Its free tier has a higher per-minute quota, making it an ideal relief valve.

- **Free tier** — higher TPM quota than Groq's free tier
- **Silent failover** — Vortex switches to Cohere with no action needed from you
- **Rate-limit handling** — on a 429, enters a 30-second cooldown then retries

### Smart Routing

`SmartRouterService` manages both providers at runtime. The logic:

```
Incoming request
  │
  ├── Groq key configured + not on cooldown?
  │     ├── YES → send to Groq AI
  │     │           ├── success → return result
  │     │           └── rate-limit/error → 65s cooldown, fall through ↓
  │     └── NO  → fall through ↓
  │
  └── Cohere key configured + not on cooldown?
        ├── YES → send to Cohere
        │           ├── success → return result
        │           └── rate-limit/error → 30s cooldown, show error
        └── NO  → show "no provider available" error
```

You can run Vortex with just one key. Add both for zero-interruption failover.

---

## Configuration

On first launch, open **Settings** (gear icon in the input bar) and add your API keys.

| Provider | Get a free key | Role |
|---|---|---|
| **Groq AI** | [console.groq.com/keys](https://console.groq.com/keys) | Primary — ultra-fast LPU inference |
| **Cohere** | [dashboard.cohere.com/api-keys](https://dashboard.cohere.com/api-keys) | Fallback — higher free quota |

The Settings screen has step-by-step instructions for obtaining each key and a **Test Connection** button to verify them before saving.

---

## How It Works

```
Ctrl+Q
  │
  ▼
CommandInput (floating pill)
  │
  ▼
AgentService.executeTask(task)
  │
  ├── SmartRouterService
  │     ├── GroqService   (primary  — llama3 / mixtral)
  │     └── CohereService (fallback — command-r)
  │
  ├── AI response classified as QUESTION or TASK
  │
  ├── QUESTION ──► chatAnswer event ──► rendered markdown in AgentResultView
  │
  └── TASK ──► STEP[N] blocks parsed
                  │
                  └── FileOperationService.executePowerShellScript()
                            └── stdout / stderr streamed live to AgentResultView
```

**Step format** — the AI returns structured blocks that Vortex parses and runs sequentially:

```
STEP[1] wait=0
Open the target app
```powershell
Start-Process "spotify"
```

STEP[2] wait=2500
Click the search field and type the query
```powershell
# UI Automation script
```
```

The `wait=N` ms value delays execution before a step to give the previous one time to launch.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter — Windows desktop |
| Window management | `window_manager` |
| Global hotkey | `hotkey_manager` |
| Navigation | GetX |
| AI — primary | Groq AI API (`groq.com`) |
| AI — fallback | Cohere API (`cohere.com`) |
| HTTP client | `dio` |
| Local storage | `shared_preferences` |
| Installer | Inno Setup 6 |

---

## Project Structure

```
vortex_agent/
├── lib/
│   ├── main.dart                        # App entry, window lifecycle, hotkey
│   ├── screens/
│   │   ├── settings_screen.dart         # API keys, auto-start, connection test
│   │   └── result_screen.dart           # Standalone result display
│   ├── services/
│   │   ├── agent_service.dart           # Task orchestration and step parsing
│   │   ├── agent_prompts.dart           # System prompts (full + compact variants)
│   │   ├── smart_router_service.dart    # Groq ↔ Cohere routing and failover
│   │   ├── groq_service.dart            # Groq AI API client
│   │   ├── cohere_service.dart          # Cohere API client
│   │   ├── file_operation_service.dart  # PowerShell script execution
│   │   ├── app_discovery_service.dart   # Installed app lookup (Win32 + UWP)
│   │   ├── storage_service.dart         # Persisted settings
│   │   └── service_locator.dart         # Dependency wiring (singleton)
│   └── widgets/
│       ├── prompt_input.dart            # Floating pill input bar
│       ├── agent_result_view.dart       # Live step-by-step result UI
│       └── screen_glow.dart             # Processing glow effect
├── windows/
│   └── runner/resources/
│       └── app_icon.ico                 # App icon (multi-resolution)
├── assets/
│   └── images/
│       └── logo.png
├── vortex_setup.iss                     # Inno Setup installer script
└── pubspec.yaml
```

---

## Contributing

Pull requests are welcome. For major changes please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create a feature branch — `git checkout -b feature/my-feature`
3. Commit your changes
4. Push and open a pull request

---

## License

MIT — see [LICENSE](LICENSE) for details.
