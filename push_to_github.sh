#!/bin/bash
# Skrypt wypychania Bible Quotes App na GitHub
# Użycie: ./push_to_github.sh TWOJ_USERNAME [TOKEN]

set -e

USERNAME=${1:-""}
TOKEN=${2:-""}

if [ -z "$USERNAME" ]; then
    echo "❌ Błąd: Podaj nazwę użytkownika GitHub"
    echo "Użycie: ./push_to_github.sh TWOJ_USERNAME [TOKEN]"
    echo ""
    echo "Przykład z tokenem (bezpieczniejsze):"
    echo "  ./push_to_github.sh johndoe ghp_xxxxxxxxxxxx"
    echo ""
    echo "Przykład bez tokena (zapyta o hasło):"
    echo "  ./push_to_github.sh johndoe"
    exit 1
fi

REPO_NAME="bible-quotes-app"
REPO_URL="https://github.com/$USERNAME/$REPO_NAME"

echo "=========================================="
echo "  Bible Quotes App - Push to GitHub"
echo "=========================================="
echo ""
echo "👤 Użytkownik: $USERNAME"
echo "📦 Repozytorium: $REPO_NAME"
echo "🔗 URL: $REPO_URL"
echo ""

# Sprawdź czy to repozytorium git
if [ ! -d ".git" ]; then
    echo "❌ Błąd: To nie jest repozytorium git!"
    exit 1
fi

# Sprawdź czy repozytorium już istnieje na GitHub
echo "🔍 Sprawdzam czy repozytorium istnieje na GitHub..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$USERNAME/$REPO_NAME" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Repozytorium już istnieje na GitHub"
    REPO_EXISTS=true
elif [ "$HTTP_STATUS" = "404" ]; then
    echo "📝 Repozytorium nie istnieje - musisz je utworzyć ręcznie"
    echo ""
    echo "Zrób to teraz:"
    echo "  1. Wejdź na: https://github.com/new"
    echo "  2. Repository name: $REPO_NAME"
    echo "  3. Kliknij 'Create repository'"
    echo "  4. Wróć tutaj i uruchom skrypt ponownie"
    echo ""
    read -p "Naciśnij Enter gdy repozytorium będzie gotowe..."
else
    echo "⚠️ Nie mogę sprawdzić statusu repozytorium (status: $HTTP_STATUS)"
    echo "Kontynuuję..."
fi

echo ""
echo "📝 Konfiguracja git remote..."

# Usuń stare remote jeśli istnieje
git remote remove origin 2>/dev/null || true

# Dodaj nowy remote
if [ -n "$TOKEN" ]; then
    # Z tokenem
    git remote add origin "https://$USERNAME:$TOKEN@github.com/$USERNAME/$REPO_NAME.git"
    echo "✅ Remote skonfigurowany z tokenem"
else
    # Bez tokena
    git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"
    echo "✅ Remote skonfigurowany (bez tokena - podaj hasło przy push)"
fi

echo ""
echo "📤 Wypychanie kodu na GitHub..."
echo ""

# Ustaw branch main
git branch -M main

# Push
echo "⬆️  git push -u origin main"
echo ""

if git push -u origin main; then
    echo ""
    echo "=========================================="
    echo "  ✅ SUKCES! KOD WYPCHNIĘTY NA GITHUB!"
    echo "=========================================="
    echo ""
    echo "🔗 Repozytorium: $REPO_URL"
    echo "📊 Actions (CI/CD): $REPO_URL/actions"
    echo ""
    echo "🎬 Co się teraz stanie:"
    echo "  • GitHub Actions automatycznie uruchomi testy"
    echo "  • Build Android APK (~8 min)"
    echo "  • Build iOS (~12 min)"
    echo ""
    echo "⏰ Za ~20 min sprawdź zakładkę Actions dla wyników"
    echo ""
    
    # Sprawdź czy Actions są skonfigurowane
    if [ -f ".github/workflows/flutter.yml" ]; then
        echo "✅ GitHub Actions skonfigurowane: .github/workflows/flutter.yml"
    fi
    
else
    echo ""
    echo "❌ BŁĄD: Nie udało się wypchnąć kodu"
    echo ""
    echo "Możliwe przyczyny:"
    echo "  • Repozytorium nie istnieje na GitHub"
    echo "  • Nieprawidłowe hasło/token"
    echo "  • Brak uprawnień do repozytorium"
    echo ""
    echo "Rozwiązania:"
    echo "  1. Utwórz repozytorium na github.com/new"
    echo "  2. Sprawdź nazwę użytkownika: $USERNAME"
    echo "  3. Wygeneruj token: github.com/settings/tokens"
    echo "  4. Użyj: ./push_to_github.sh $USERNAME TWÓJ_TOKEN"
    echo ""
    exit 1
fi
