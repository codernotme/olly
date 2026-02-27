# 🦙 Olly

![Olly Logo](assets/logo.png)

Olly is a premium, AI-powered desktop assistant featuring voice interaction, persistent memory, a built-in code editor, and multi-LLM support (Ollama, Claude, OpenAI).

## Features

- **Nice UI**: Sleek glassmorphic design with smooth animations.
- **Voice Assistant**: Integrated "Hey Olly" wake-word detection and voice responses (TTS).
- **Personal Assistant**: Persistent user memory for deeply personalized context.
- **Code Editor**: Feature-rich AI code workspace with syntax highlighting.
- **Multi-LLM**: Connect to local Ollama models or external APIs (GPT-4, Claude 3).
- **Social Bots**: Interface your local AI with Telegram and WhatsApp.
- **System Console**: Native terminal and log viewer for debugging and system control.

## 🚀 Getting Started

### Prerequisites

1. **Install Flutter** (3.0 or higher):
   ```bash
   flutter --version
   ```

2. **Install Ollama** (if not already installed):
   - Visit [Ollama.com](https://ollama.com) to download.

### Installation

```bash
# Clone the repository
git clone https://github.com/codernotme/olly.git
cd olly

# Install dependencies
flutter pub get

# Run Olly
flutter run -d linux # or macos/windows
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── providers/
│   ├── log_provider.dart        # Console & system log management
│   ├── chat_provider.dart       # Chat sessions & memory
│   ├── settings_provider.dart   # App settings & API keys
│   └── agent_provider.dart      # Agent management
└── screens/
    ├── main_shell.dart          # Navigation shell
    ├── chat_screen.dart         # Chat & Voice interface
    ├── terminal_screen.dart     # System Console
    ├── editor_screen.dart       # Code Workspace
    └── settings_screen.dart     # Configuration
```

Built with ❤️ by the Olly team.
