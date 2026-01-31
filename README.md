# AI Cover Letter Generator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

A modern, native macOS application designed to simplify your job application process. It leverages AI models (running locally or via CLI) to generate tailored, professional cover letters by analyzing your CV and the specific job description.

## Key Features 🚀

### 🧠 Smart Generation
*   **Context-Aware AI:** Analyzes both your uploaded CV and the Job Description to create highly relevant content.
*   **Auto-Language Detection:** Automatically writes the letter in the same language as the job ad (English 🇬🇧 or French 🇫🇷).
*   **Tone Selection:** Choose from **Professional**, **Enthusiastic**, **Confident**, or **Academic** tones.

### 👤 Profile Management (New!)
*   **Multiple Personas:** Create and save different profiles (e.g., "Fullstack Dev", "Project Manager", "Freelance").
*   **Instant Switching:** Switch between profiles in one click to auto-fill your contact details and custom instructions.

### 🎨 PDF Export & Theming
*   **Multiple Themes:** Choose from **Standard** (Clean), **Modern** (Blue Accents, Avenir font), or **Classic** (Times New Roman).
*   **Live Preview:** See exactly how your PDF will look before exporting.
*   **One-Click Export:** Generate professional, formatted PDFs instantly.

### 🛠 Tools & Utilities
*   **CV Text Inspector:** View and edit exactly what the AI text extractor "sees" in your PDF to ensure accuracy.
*   **History:** Automatically saves your generated letters. Restore previous versions anytime.
*   **Direct Copy:** Copy the text to your clipboard for quick emails or LinkedIn messages.

---

## 🛠 Prerequisites

To use this application, you need **at least one** of the following AI backends installed on your Mac:

**Option 1: Google Gemini (Recommended)**
```bash
brew install gemini-cli
# Run 'gemini configure' to set your API key
```

**Option 2: OpenCode (Local Models)**
```bash
brew install opencode
```

**Option 3: Mistral Vibe**
```bash
brew install mistral-vibe
```

---

## 🇫🇷 Français

Une application macOS native moderne conçue pour simplifier vos candidatures. Elle utilise l'IA pour générer des lettres de motivation sur-mesure en analysant votre CV et l'offre d'emploi.

## Fonctionnalités Clés 🚀

### 🧠 Génération Intelligente
*   **Analyse Contextuelle :** Croise les données de votre CV avec l'offre d'emploi.
*   **Détection de Langue :** Rédige automatiquement en Français ou Anglais selon l'offre.
*   **Choix du Ton :** Professionnel, Enthousiaste, Confiant ou Académique.

### 👤 Gestion de Profils (Nouveau !)
*   **Multi-Profils :** Créez des identités différentes (ex: "Dev Senior", "Freelance").
*   **Bascule Rapide :** Changez de profil en un clic pour charger vos coordonnées et instructions spécifiques.

### 🎨 Thèmes & Export PDF
*   **Thèmes Variés :** **Standard** (Épuré), **Moderne** (Accents Bleus), ou **Classique** (Institutionnel).
*   **Aperçu en Direct :** Visualisez le rendu final avant l'export.
*   **Export PDF :** Un fichier prêt à envoyer en un clic.

### 🛠 Outils Pratiques
*   **Inspecteur de CV :** Vérifiez et corrigez le texte extrait de votre PDF pour garantir que l'IA a les bonnes infos.
*   **Historique :** Sauvegarde automatique de vos lettres.
*   **Copie Rapide :** Copiez le texte pour un email ou LinkedIn.

## Installation

1.  Téléchargez la dernière version depuis la page Releases.
2.  Déplacez `LetterGenerator.app` dans votre dossier **Applications**.
3.  Lancez l'application (Clic-droit > Ouvrir au premier lancement).

---
*Built with ❤️ using SwiftUI & Apple Intelligence tools.*
