<div align="center">

<img src="Resources/AppIcon.png" width="128" height="128" alt="mailto: Logo" />

# mailto:

### The lightweight, on-demand `mailto:` router for macOS.

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple&style=flat-square)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift&style=flat-square)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-40%20Passing-brightgreen?style=flat-square)](#development--testing)
[![Resource Usage](https://img.shields.io/badge/Idle%20CPU-0%25-success?style=flat-square)](#architecture--efficiency)

<p align="center">
  <b>Route clicked email links to your preferred desktop client, webmail, or clipboard — with zero background overhead.</b>
</p>

</div>

---

## 💡 Why mailto:?

When you click an email link in Slack, Chrome, Safari, or Notion, macOS stubbornly attempts to launch a full-featured desktop mail client. If you use webmail (like Gmail or Outlook 365) or multiple mail accounts for personal and work communication, this behavior is disruptive.

**mailto: solves this cleanly:**
- Intercepts all system-wide `mailto:` links.
- Evaluates your personalized routing rules (e.g. work emails go to Gmail, personal to Apple Mail).
- Bypasses rules on demand by holding the `Fn` modifier key.
- **Terminates immediately after routing** — consuming **0% CPU and 0 MB RAM** while idle.

---

## ✨ Features

- ⚡️ **Zero Background Footprint:** Operates as a silent background agent (`LSUIElement`). It launches on-demand when a link is clicked, routes the message in milliseconds, and exits cleanly.
- 🎯 **Priority Rule Engine:** First-match rule evaluation supporting:
  - Exact domain match (e.g., `@company.com`)
  - Subdomains match (e.g., `*.corp.internal`)
  - Full email address match (e.g., `boss@company.com`)
  - Source application filtering (e.g., only route links clicked inside Slack)
- ⌨️ **Fn Key Superpower:** Hold the `Fn` (or Globe) key while clicking any email link to bypass all rules and trigger your configured Alternative target (e.g., Copy to Clipboard or personal client).
- 🌐 **First-Class Webmail Support:** Pre-configured deep-linking for 8 major webmail providers:
  - **Gmail**
  - **Outlook 365 & Outlook.com**
  - **Fastmail**
  - **Yahoo Mail**
  - **Yandex Mail**
  - **AOL Mail**
  - **Zoho Mail**
- 🔗 **Custom URL Templates:** Expand dynamic tokens like `{to}`, `{cc}`, `{bcc}`, `{subject}`, `{body}`, and `{domain}` into your custom web CRM or internal ticketing tools.
- 📋 **Copy to Clipboard:** Route links directly to your clipboard when you simply want the email address without composing a message.
- 🛡️ **Self-Loop & Recursion Protection:** Detects if an external application delegates back to `mailto:`, preventing infinite loops.
- 🚀 **Built-in First-Run Onboarding:** Interactive 3-step setup wizard with one-click silent registration as the default email handler.

---

## 📥 Installation

### Option 1: Homebrew (Recommended) 🍺
Install with a single command via Homebrew:

```bash
brew install --cask atalayhuryasar/tap/mailto
```

*(Or tap the repository first: `brew tap atalayhuryasar/tap && brew install --cask mailto`)*

### Option 2: Pre-built Binary
1. Download the latest `mailto.zip` from [GitHub Releases](https://github.com/atalayhuryasar/mailto/releases).
2. Unzip and drag `Mailto.app` to your `/Applications` folder.
3. Launch `Mailto.app` and follow the 3-step onboarding wizard.

> **Note on macOS Security (Gatekeeper):** Because `mailto:` is a free, open-source community tool without a paid Apple Developer certificate, macOS will block un-notarized internet downloads by default on first launch:
> - Click **Done** on the dialog.
> - Go to **System Settings > Privacy & Security**, scroll down to the **Security** section, and click **Open Anyway**.
> - *(Alternatively, run `xattr -cr /Applications/Mailto.app` in Terminal to instantly bypass the quarantine flag).*

### Option 3: Mac App Store *(Coming Soon)*
`mailto:` is currently being prepared for the Mac App Store. Check back soon for the 1-click App Store install.

### Option 4: Build from Source
Requirements: macOS 14.0+, Xcode 16+ or Swift 6.0+ toolchain.

```bash
# 1. Clone repository
git clone https://github.com/atalayhuryasar/mailto.git
cd mailto

# 2. Build release bundle
./scripts/build-app.sh

# 3. Open the built application
open "build/Mailto.app"
```

---

## 🛠️ Usage & Configuration

### Setting as Default Mail Client
`mailto:` needs to be registered as your system's default `mailto:` handler. You can do this with a single click inside the **General** settings tab or the first-run onboarding screen.

### Configuring Rules
1. Open settings (`open "build/Mailto.app"` or launch from Applications).
2. Go to the **Rules** tab and click **Add Rule (+)**.
3. Specify your matching condition:
   - **Matcher Type:** Domain, Domain & Subdomains, or Exact Email Address.
   - **Target:** Webmail provider, Native macOS client, Custom URL, or Clipboard.
   - *(Optional)* **Source App:** Restrict the rule to only trigger from specific apps (e.g., Slack or Microsoft Teams).
4. Drag and drop rules to adjust priority (first matching rule wins).

### The Fn Key Shortcut
Hold the **`Fn`** key on your Mac keyboard while clicking any mailto link to immediately route to your **Alternative Email App** (configured in General settings), ignoring all custom rules.

---

## 🗺️ Roadmap

- [ ] 🧩 **Chrome & Safari WebExtensions:** Native Manifest V3 extensions to intercept in-browser `mailto:` clicks directly into webmail tabs with zero OS handoff.
- [ ] 🏪 **Mac App Store Release:** Official distribution with sandbox entitlements.
- [ ] ⌨️ **Configurable Modifier Keys:** Support Option (`⌥`), Command (`⌘`), and Control (`⌃`) in addition to `Fn`.
- [ ] 🌍 **Localization:** Multi-language interface support (Turkish, German, French, Spanish, Japanese).

---

## 🧪 Development & Testing

`mailto:` is developed strictly using Test-Driven Development (TDD). The core library (`MailtoCore`) is fully decoupled from AppKit UI for rapid, deterministic testing.

```bash
# Run full suite of 40 unit and integration tests
swift test

# Run end-to-end bundle verification script
./scripts/verify-scenarios.sh

# Clean reset and reinstall
./scripts/reinstall.sh
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
