# 🦙 Ollama Desktop

A comprehensive Flutter desktop application for managing and interacting with Ollama — your local AI model hub.

![Ollama Desktop](https://via.placeholder.com/1200x600/6B4EFF/FFFFFF?text=Ollama+Desktop)

## ✨ Features

### 🏠 Dashboard
- At-a-glance status of your Ollama instance
- Stats for installed models, active chats, agents, and running models
- Quick action buttons for common tasks
- Recent chats overview

### 💬 Chat Interface
- **Multi-session chat** — create, switch between, and manage multiple conversation threads
- **Real-time streaming** — watch responses appear word by word
- **Markdown rendering** — beautiful rendering of code blocks, tables, lists, and more
- **Per-session settings** — unique model, temperature, and system prompt per chat
- **Message actions** — copy, regenerate responses
- **Chat history** — persistent across app restarts
- **Keyboard shortcuts** — Enter to send, Shift+Enter for newline

### 🤖 Model Management
- **Installed models** — view all locally installed models with size and metadata
- **Model library** — browse popular models with one-click install
- **Pull models** — download any model from the Ollama registry with live progress
- **Delete models** — remove models to free up disk space
- **Model selection** — switch between models from anywhere in the app

### 🧩 Sub-Agents
- **Create specialized agents** with custom roles (Coder, Researcher, Writer, Analyst)
- **Custom system prompts** per agent
- **Tool assignment** — assign tools relevant to each agent's role
- **Task execution** — run tasks and track step-by-step progress
- **Agent configuration** — tune temperature and behavior per agent

### 🔑 API Keys
- **Generate API keys** for programmatic access organization
- **Key management** — enable/disable, delete keys
- **Full API reference** — browse all Ollama endpoints with examples
- **Code snippets** — ready-to-use code examples in JavaScript

### ⚙️ Settings
- **Theme** — Light, Dark, or System automatic
- **Connection** — Custom Ollama server URL (supports remote instances)
- **Chat defaults** — streaming toggle, markdown toggle, default system prompt
- **Model defaults** — temperature and max token defaults
- **Persistent** — all settings saved and restored

## 🚀 Getting Started

### Prerequisites

1. **Install Flutter** (3.0 or higher):
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install
   flutter --version
   ```

2. **Enable desktop support:**
   ```bash
   flutter config --enable-macos-desktop
   flutter config --enable-windows-desktop
   flutter config --enable-linux-desktop
   ```

3. **Install Ollama** (if not already installed):
   - macOS: `brew install ollama`
   - Linux: `curl -fsSL https://ollama.com/install.sh | sh`
   - Windows: Download from https://ollama.com/download

### Installation

```bash
# Clone or download this project
cd ollama_desktop

# Install dependencies
flutter pub get

# Run on your platform
flutter run -d macos     # macOS
flutter run -d windows   # Windows
flutter run -d linux     # Linux
```

### Build for Distribution

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── providers/
│   ├── ollama_provider.dart     # Ollama API & model management
│   ├── chat_provider.dart       # Chat sessions & messages
│   ├── settings_provider.dart   # App settings & API keys
│   └── agent_provider.dart      # Sub-agent management
└── screens/
    ├── main_shell.dart          # Navigation shell with sidebar
    ├── dashboard_screen.dart    # Overview dashboard
    ├── chat_screen.dart         # Chat interface
    ├── models_screen.dart       # Model management
    ├── agents_screen.dart       # Sub-agent builder
    ├── api_keys_screen.dart     # API key management
    └── settings_screen.dart     # App settings
```

## 🔧 Configuration

The app connects to Ollama at `http://localhost:11434` by default. You can change this in Settings → Connection if running Ollama on a different port or machine.

## 📖 Ollama API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tags` | List installed models |
| POST | `/api/chat` | Chat completion (streaming) |
| POST | `/api/generate` | Text generation |
| POST | `/api/pull` | Download model |
| DELETE | `/api/delete` | Remove model |
| POST | `/api/embeddings` | Generate embeddings |
| GET | `/api/ps` | List running models |
| POST | `/api/show` | Model details |

## 🛠️ Tech Stack

- **Flutter** — Cross-platform UI framework
- **Provider** — State management
- **HTTP/Dio** — API communication
- **Hive + SharedPreferences** — Local data persistence
- **flutter_markdown** — Markdown rendering
- **Google Fonts** — Typography

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## 📄 License

MIT License — feel free to use, modify, and distribute.

---

Built with ❤️ using Flutter & Ollama
