# AI Cover Letter Generator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

A native macOS application (Apple Silicon optimized) that generates professional cover letters using AI models running locally or via CLI. It automatically extracts context from your CV (PDF) and analyzes the job description to write a tailored letter.

---

## 🇬🇧 English

### Features
*   **Drag & Drop:** Simply drop your CV (PDF) to extract text and contact details automatically.
*   **Auto-Language Detection:** Writes the letter in the same language as the job description (English or French).
*   **Smart Signature:** Automatically appends your contact details and a professional closing matching the language.
*   **Multiple AI Providers:** Supports Google Gemini (via CLI) and local models via OpenCode.
*   **PDF Export:** Export formatted, justified PDFs with a single click.

### Prerequisites

To use this application, you need **at least one** of the following CLI tools installed on your Mac. You can install them via Homebrew.

**Option 1: Gemini CLI (Recommended for speed/quality)**
```bash
brew install gemini-cli
# You will need to configure your API key:
# gemini configure
```

**Option 2: OpenCode (For local models)**
```bash
brew install opencode
# Ensure you have models downloaded or configured
```

**Option 3: Mistral Vibe**
```bash
brew install mistral-vibe
```

### Installation

1.  Download the latest release from the [Releases](https://github.com/yourusername/LetterGenerator/releases) page.
2.  Unzip `LetterGenerator.zip`.
3.  Move `LetterGenerator.app` to your **Applications** folder.
4.  **First Launch:** Right-click the app and select **Open**. (This is required because the app is signed with an ad-hoc certificate).

### Usage
1.  **Drop your CV:** Drag your PDF CV into the drop zone. The app will auto-fill your name, phone, and email.
2.  **Paste Job Description:** Copy and paste the job text.
3.  **Select Model:** Choose your preferred AI model from the list.
4.  **Generate:** Click "Generate Letter".
5.  **Export:** Edit if needed, then export as PDF.

---

## 🇫🇷 Français

### Fonctionnalités
*   **Glisser-Déposer :** Déposez simplement votre CV (PDF) pour extraire le texte et vos coordonnées automatiquement.
*   **Détection de Langue Auto :** Rédige la lettre dans la même langue que l'annonce (Anglais ou Français).
*   **Signature Intelligente :** Ajoute automatiquement vos coordonnées et une formule de politesse adaptée à la langue.
*   **Multi-Modèles IA :** Supporte Google Gemini (via CLI) et des modèles locaux via OpenCode.
*   **Export PDF :** Exportez des PDF formatés et justifiés en un clic.

### Prérequis

Pour utiliser cette application, vous devez avoir installé **au moins l'un** des outils CLI suivants sur votre Mac. Vous pouvez les installer via Homebrew.

**Option 1 : Gemini CLI (Recommandé pour la vitesse/qualité)**
```bash
brew install gemini-cli
# Vous devrez configurer votre clé API :
# gemini configure
```

**Option 2 : OpenCode (Pour les modèles locaux)**
```bash
brew install opencode
# Assurez-vous d'avoir téléchargé ou configuré vos modèles
```

**Option 3 : Mistral Vibe**
```bash
brew install mistral-vibe
```

### Installation

1.  Téléchargez la dernière version depuis la page [Releases](https://github.com/yourusername/LetterGenerator/releases).
2.  Décompressez `LetterGenerator.zip`.
3.  Déplacez `LetterGenerator.app` dans votre dossier **Applications**.
4.  **Premier Lancement :** Faites un clic-droit sur l'application et sélectionnez **Ouvrir**. (Ceci est nécessaire car l'application est signée avec un certificat ad-hoc).

### Utilisation
1.  **Déposez votre CV :** Glissez votre CV PDF dans la zone dédiée. L'app remplira automatiquement votre nom, téléphone et email.
2.  **Collez l'Annonce :** Copiez et collez le texte de l'offre d'emploi.
3.  **Choisissez le Modèle :** Sélectionnez votre modèle IA préféré dans la liste.
4.  **Générez :** Cliquez sur "Générer la Lettre".
5.  **Exportez :** Éditez si nécessaire, puis exportez en PDF.
