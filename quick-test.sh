#!/bin/bash

# Script de lancement rapide pour les tests E2E
# Usage: ./quick-test.sh

echo "🚀 Lancement rapide des tests E2E"
echo ""

# Démarrer les services en arrière-plan
echo "📦 Démarrage des services..."
./start-e2e-services.sh > /tmp/e2e-startup.log 2>&1 &
STARTUP_PID=$!

# Attendre que les services démarrent
echo "⏳ Attente du démarrage des services (30s)..."
sleep 30

# Vérifier si les services sont prêts
if lsof -ti :5005,9099,8080 >/dev/null 2>&1; then
    echo "✅ Services prêts!"
    echo ""
    
    # Exécuter les tests
    echo "🧪 Exécution des tests..."
    cd e2e
    npx playwright test full-marketplace-e2e.spec.ts --reporter=list
    TEST_RESULT=$?
    cd ..
    
    # Afficher le résultat
    if [ $TEST_RESULT -eq 0 ]; then
        echo ""
        echo "✅ Tous les tests ont réussi!"
    else
        echo ""
        echo "⚠️ Certains tests ont échoué (code: $TEST_RESULT)"
        echo "Voir les détails dans e2e/test-results/"
    fi
    
    # Arrêter les services
    echo ""
    echo "🛑 Arrêt des services..."
    ./stop-e2e-services.sh
    
    exit $TEST_RESULT
else
    echo "❌ Les services n'ont pas démarré correctement"
    echo "Voir les logs: /tmp/e2e-startup.log"
    kill $STARTUP_PID 2>/dev/null
    exit 1
fi
