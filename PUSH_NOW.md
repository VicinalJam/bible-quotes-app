# 🚀 Wypchnij Kod na GitHub - INSTRUKCJA

## ⚡ Opcja 1: Skrypt Automatyczny (ZALECANA)

```bash
cd /Users/imac27/CascadeProjects/bible_quotes_app

# Utwórz repozytorium na GitHub
# Wejdź na: https://github.com/new
# - Name: bible-quotes-app
# - Description: Flutter app with Bible quotes matched to your mood
# - Public
# - ☐ Initialize with README (puste!)
# Kliknij "Create repository"

# Następnie w terminalu:
./push_to_github.sh TWOJ_USERNAME_GITHUB

# Przykład:
./push_to_github.sh johndoe
```

**Skrypt zapyta o hasło do GitHub.**

---

## ⚡ Opcja 2: Szybkie Komendy (dla zaawansowanych)

```bash
cd /Users/imac27/CascadeProjects/bible_quotes_app

# 1. Utwórz repozytorium na github.com/new
#    (puste, bez README, bez .gitignore)

# 2. Podaj swoją nazwę użytkownika:
USERNAME="TWOJ_USERNAME"  # <-- ZASTĄP!

# 3. Wypchnij kod:
git remote add origin https://github.com/$USERNAME/bible-quotes-app.git
git branch -M main
git push -u origin main

# 4. Podaj hasło kiedy zapyta
```

---

## ⚡ Opcja 3: Git Bundle (Bez Internetu)

Jeśli masz ograniczony dostęp do sieci, użyj pliku bundle:

```bash
# Plik bundle został utworzony:
# /Users/imac27/CascadeProjects/bible_quotes_app/bible-quotes-app.bundle

# Na innym komputerze z dostępem do GitHub:
git clone bible-quotes-app.bundle bible-quotes-app
cd bible-quotes-app
git remote add origin https://github.com/TWOJ_USERNAME/bible-quotes-app.git
git push -u origin main
```

---

## 🔧 Generowanie GitHub Token (Opcjonalnie - Bezpieczniejsze)

Zamiast hasła możesz użyć tokena:

1. Wejdź na: https://github.com/settings/tokens
2. Kliknij "Generate new token (classic)"
3. Nadaj nazwę: "Bible Quotes App"
4. Zaznacz uprawnienia:
   - ✅ repo
   - ✅ workflow
5. Kliknij "Generate token"
6. **SKOPIUJ TOKEN** (pokaże się tylko raz!)

Następnie:
```bash
./push_to_github.sh TWOJ_USERNAME ghp_XXXXXXXXXXX
```

---

## ✅ Weryfikacja Po Wypchnięciu

### Sprawdź lokalnie:
```bash
git log --oneline --graph --all -5
# Powinieneś zobaczyć:
# * 9ce30d7 (HEAD -> main, origin/main) Add GitHub setup instructions
# * ffc554a Initial commit: Bible Quotes App with Flutter
```

### Sprawdź na GitHub:
1. Wejdź na: `https://github.com/TWOJ_USERNAME/bible-quotes-app`
2. Powinieneś zobaczyć wszystkie pliki
3. Kliknij zakładkę **Actions** (powinna być zielona ✅)

---

## 📊 Co Się Stanie Po Wypchnięciu

| Czas | Akcja | Status |
|------|-------|--------|
| **0:00** | Push kodu na GitHub | ⏳ |
| **0:30** | GitHub Actions startuje | 🚀 |
| **2:00** | Analiza kodu (`flutter analyze`) | ✅/❌ |
| **5:00** | Testy jednostkowe (`flutter test`) | ✅/❌ |
| **13:00** | Build Android APK | 📦 |
| **25:00** | Build iOS (bez podpisu) | 📦 |
| **Koniec** | Wszystkie artefakty gotowe | 🎉 |

**Sprawdź wyniki:** https://github.com/TWOJ_USERNAME/bible-quotes-app/actions

---

## 🎬 Po Poprawnym Buildzie

### Pobierz APK:
1. Wejdź w **Actions** → **build-android**
2. Scroll down do **Artifacts**
3. Pobierz `app-release.apk`

### Zainstaluj na telefonie:
```bash
# Podłącz telefon przez USB
adb install app-release.apk

# Lub wyślij plik na telefon i zainstaluj
```

---

## 🆘 Rozwiązywanie Problemów

### Problem: `Permission denied`
```bash
# Sprawdź czy repozytorium istnieje
curl https://api.github.com/repos/TWOJ_USERNAME/bible-quotes-app

# Sprawdź czy jesteś zalogowany w git
git config user.name
git config user.email
```

### Problem: `Could not resolve host`
```bash
# Sprawdź połączenie internetowe
ping github.com

# Spróbuj przez SSH zamiast HTTPS
git remote set-url origin git@github.com:TWOJ_USERNAME/bible-quotes-app.git
```

### Problem: `Repository not found`
```bash
# Upewnij się że repozytorium jest PUBLICZNE
# Lub masz dostęp do repozytorium prywatnego
```

---

## 📦 Pliki Gotowe do Wypchnięcia

```
/Users/imac27/CascadeProjects/bible_quotes_app/
├── ✅ .git/ (repozytorium z 2 commitami)
├── ✅ .github/workflows/flutter.yml (CI/CD)
├── ✅ lib/ (kod źródłowy)
├── ✅ android/ (konfiguracja Android)
├── ✅ ios/ (konfiguracja iOS)
├── ✅ assets/ (cytaty)
├── ✅ push_to_github.sh (skrypt)
├── ✅ bible-quotes-app.bundle (pakiet git)
└── ✅ [wszystkie pozostałe pliki]
```

**Wszystko gotowe do wypchnięcia! 🚀**

---

## 📝 Podsumowanie Komend

```bash
cd /Users/imac27/CascadeProjects/bible_quotes_app

# Opcja A - Skrypt (zalecane)
./push_to_github.sh TWOJ_USERNAME

# Opcja B - Ręcznie
USERNAME="TWOJ_USERNAME"
git remote add origin https://github.com/$USERNAME/bible-quotes-app.git
git push -u origin main

# Opcja C - Z tokenem (bezpieczniejsze)
./push_to_github.sh TWOJ_USERNAME ghp_XXXXXX
```

---

**Gotowe? Wypchnij teraz! 🎉**
