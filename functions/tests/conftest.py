"""
Configuration pytest pour les tests Firebase Functions.

Ce fichier configure l'environnement de test pour Firebase Admin SDK,
incluant le support pour l'émulateur Firestore et les mocks.
Charge également les variables d'environnement depuis .env.
"""

import os
import sys
import pytest
from pathlib import Path
import firebase_admin
from firebase_admin import credentials, firestore
from unittest.mock import Mock, MagicMock, patch
from google.cloud.firestore_v1.base_client import BaseClient

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Create HttpsError mock class that is a real exception
class MockHttpsError(Exception):
    """Mock Firebase HttpsError"""
    def __init__(self, code, message):
        self.code = code
        self.message = message
        super().__init__(message)

# Patch Firebase Functions decorators and utilities BEFORE any imports
# This ensures that decorated functions don't require Firebase context
def decorator_passthrough(**kwargs):
    """Decorator that does nothing, just returns the function as-is"""
    def decorator(func):
        return func
    return decorator

# Patch the module before it's imported by test files
sys.modules['firebase_functions'] = MagicMock()
sys.modules['firebase_functions'].https_fn = MagicMock()
sys.modules['firebase_functions'].https_fn.on_call = decorator_passthrough
sys.modules['firebase_functions'].https_fn.on_request = decorator_passthrough
sys.modules['firebase_functions'].https_fn.CallableRequest = Mock
sys.modules['firebase_functions'].https_fn.HttpsError = MockHttpsError
sys.modules['firebase_functions.https_fn'] = sys.modules['firebase_functions'].https_fn

# Set TESTING environment variable to prevent Secret Manager calls
os.environ['TESTING'] = 'true'

# Set mock environment variables for secrets to avoid Secret Manager calls
os.environ['STRIPE_SECRET_KEY'] = 'STRIPE_SECRET_KEY_REDACTED'
os.environ['STRIPE_WEBHOOK_SECRET'] = 'STRIPE_WEBHOOK_SECRET_REDACTED'
os.environ['AIRWALLEX_API_KEY'] = 'mock_airwallex_api_key_for_testing'
os.environ['AIRWALLEX_CLIENT_ID'] = 'mock_airwallex_client_id_for_testing'


@pytest.fixture(scope="session", autouse=True)
def firebase_app():
    """
    Initialise Firebase Admin pour la session de test.
    
    Utilise l'émulateur Firestore si FIRESTORE_EMULATOR_HOST est défini,
    sinon initialise avec un certificat mock pour les tests unitaires.
    """
    # Vérifier si l'émulateur est configuré
    using_emulator = os.getenv('FIRESTORE_EMULATOR_HOST') is not None
    
    # Éviter la double initialisation
    if not firebase_admin._apps:
        if using_emulator:
            # Mode émulateur - utiliser les credentials par défaut
            print("🔧 Initialisation Firebase Admin avec l'émulateur Firestore")
            firebase_admin.initialize_app(options={
                'projectId': 'demo-test-project'
            })
        else:
            # Mode mock - utiliser un certificat mock
            print("🔧 Initialisation Firebase Admin avec des credentials mock")
            mock_cred = Mock(spec=credentials.Certificate)
            firebase_admin.initialize_app(credential=mock_cred, options={
                'projectId': 'test-project'
            })
    
    yield firebase_admin.get_app()
    
    # Cleanup - supprimer l'app Firebase après tous les tests
    try:
        firebase_admin.delete_app(firebase_admin.get_app())
        print("✅ Firebase Admin app supprimée")
    except Exception as e:
        print(f"⚠️ Erreur lors du cleanup Firebase: {e}")


@pytest.fixture(scope="function")
def firestore_client(firebase_app):
    """
    Fournit un client Firestore pour chaque test.
    
    En mode émulateur, retourne un vrai client connecté à l'émulateur.
    En mode mock, retourne un client mocké.
    """
    using_emulator = os.getenv('FIRESTORE_EMULATOR_HOST') is not None
    
    if using_emulator:
        # Retourner le vrai client Firestore connecté à l'émulateur
        client = firestore.client()
        yield client
        
        # Cleanup - supprimer toutes les collections de test
        try:
            collections = client.collections()
            for collection in collections:
                delete_collection(collection)
        except Exception as e:
            print(f"⚠️ Erreur lors du cleanup Firestore: {e}")
    else:
        # Retourner un client mocké
        mock_client = MagicMock(spec=BaseClient)
        yield mock_client


@pytest.fixture(scope="function")
def mock_firestore_transaction():
    """Fournit une transaction Firestore mockée pour les tests unitaires."""
    mock_transaction = MagicMock()
    mock_transaction.get = MagicMock()
    mock_transaction.set = MagicMock()
    mock_transaction.update = MagicMock()
    mock_transaction.delete = MagicMock()
    return mock_transaction


@pytest.fixture(scope="function")
def mock_firestore_batch():
    """Fournit un batch Firestore mocké pour les tests unitaires."""
    mock_batch = MagicMock()
    mock_batch.set = MagicMock()
    mock_batch.update = MagicMock()
    mock_batch.delete = MagicMock()
    mock_batch.commit = MagicMock(return_value=[])
    return mock_batch


@pytest.fixture(scope="function")
def mock_document_reference():
    """Fournit une référence de document mockée."""
    mock_doc_ref = MagicMock()
    mock_doc_ref.id = "test_doc_id"
    mock_doc_ref.path = "test_collection/test_doc_id"
    mock_doc_ref.get = MagicMock()
    mock_doc_ref.set = MagicMock()
    mock_doc_ref.update = MagicMock()
    mock_doc_ref.delete = MagicMock()
    mock_doc_ref.collection = MagicMock()
    return mock_doc_ref


@pytest.fixture(scope="function")
def mock_collection_reference():
    """Fournit une référence de collection mockée."""
    mock_col_ref = MagicMock()
    mock_col_ref.id = "test_collection"
    mock_col_ref.path = "test_collection"
    mock_col_ref.document = MagicMock()
    mock_col_ref.add = MagicMock()
    mock_col_ref.stream = MagicMock(return_value=[])
    mock_col_ref.where = MagicMock(return_value=mock_col_ref)
    mock_col_ref.order_by = MagicMock(return_value=mock_col_ref)
    mock_col_ref.limit = MagicMock(return_value=mock_col_ref)
    mock_col_ref.get = MagicMock()
    return mock_col_ref


@pytest.fixture(scope="function")
def sample_user_data():
    """Données de test pour un utilisateur."""
    return {
        'uid': 'test_user_123',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'created_at': firestore.SERVER_TIMESTAMP,
        'role': 'consumer'
    }


@pytest.fixture(scope="function")
def sample_product_data():
    """Données de test pour un produit."""
    return {
        'product_id': 'test_product_123',
        'name': 'Test Product',
        'price': 29.99,
        'currency': 'USD',
        'stock_quantity': 100,
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP
    }


@pytest.fixture(scope="function")
def sample_order_data():
    """Données de test pour une commande."""
    return {
        'order_id': 'test_order_123',
        'consumer_id': 'test_user_123',
        'status': 'pending',
        'total_amount': 29.99,
        'currency': 'USD',
        'items': [
            {
                'product_id': 'test_product_123',
                'quantity': 1,
                'price': 29.99
            }
        ],
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP
    }


def delete_collection(collection_ref, batch_size=100):
    """
    Supprime tous les documents d'une collection (helper pour cleanup).
    
    Args:
        collection_ref: Référence à la collection Firestore
        batch_size: Nombre de documents à supprimer par batch
    """
    docs = collection_ref.limit(batch_size).stream()
    deleted = 0

    for doc in docs:
        doc.reference.delete()
        deleted += 1

    if deleted >= batch_size:
        return delete_collection(collection_ref, batch_size)


def pytest_configure(config):
    """
    Configuration globale de pytest.
    Charge les variables d'environnement et configure les marqueurs.
    """
    # Charger les variables d'environnement depuis .env
    env_file = Path(__file__).parent.parent / '.env'
    
    if env_file.exists():
        print(f"\n📁 Loading environment from: {env_file}")
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                # Skip empty lines and comments
                if not line or line.startswith('#'):
                    continue
                
                # Parse key=value pairs
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    
                    # Remove quotes if present
                    if (value.startswith('"') and value.endswith('"')) or \
                       (value.startswith("'") and value.endswith("'")):
                        value = value[1:-1]
                    
                    # Set environment variable if not already set
                    if key not in os.environ:
                        os.environ[key] = value
                        
        # Verify Algolia credentials are loaded
        algolia_app_id = os.environ.get('ALGOLIA_APP_ID', '')
        algolia_write_key = os.environ.get('ALGOLIA_WRITE_API_KEY', '')
        
        if algolia_app_id and algolia_write_key:
            print(f"✅ Algolia credentials loaded: APP_ID={algolia_app_id[:4]}...")
        else:
            print("⚠️ Algolia credentials not found in .env")
    else:
        print(f"\n⚠️ No .env file found at {env_file}")
    
    # Ajouter des marqueurs personnalisés
    config.addinivalue_line(
        "markers", "integration: marquer un test comme test d'intégration"
    )
    config.addinivalue_line(
        "markers", "unit: marquer un test comme test unitaire"
    )
    config.addinivalue_line(
        "markers", "emulator: test nécessitant l'émulateur Firestore"
    )
    config.addinivalue_line(
        "markers", "slow: marquer un test comme lent"
    )


@pytest.fixture(scope="function", autouse=True)
def mock_firestore_functions():
    """
    Auto-fixture that patches all Firebase functions and dependencies
    for each test that needs them.
    """
    with patch('handlers.payment_stripe.get_db') as mock_get_db, \
         patch('handlers.payment_stripe.get_rate_limiter') as mock_get_rate_limiter, \
         patch('handlers.payment_stripe.get_server_timestamp') as mock_get_timestamp, \
         patch('handlers.payment_stripe.calculate_shipping_cost') as mock_shipping, \
         patch('handlers.payment_stripe.get_tax_rate') as mock_tax_rate, \
         patch('handlers.payment_stripe.send_email') as mock_send_email, \
         patch('firebase_functions.https_fn.on_call') as mock_on_call, \
         patch('firebase_functions.https_fn.on_request') as mock_on_request:
        
        # Setup Firestore client mock
        mock_db = MagicMock()
        mock_db.collection = MagicMock()
        mock_get_db.return_value = mock_db
        
        # Setup rate limiter mock
        mock_rate_limiter_instance = MagicMock()
        mock_rate_limiter_instance.check_rate_limit = MagicMock(return_value=(True, "OK"))
        mock_get_rate_limiter.return_value = mock_rate_limiter_instance
        
        # Setup timestamp mock
        mock_get_timestamp.return_value = firestore.SERVER_TIMESTAMP
        
        # Setup shipping cost mock
        mock_shipping.return_value = 10.00
        
        # Setup tax rate mock
        mock_tax_rate.return_value = 0.13
        
        # Setup email mock
        mock_send_email.return_value = True
        
        # Setup Firebase Functions decorators - make them identity functions
        mock_on_call.return_value = lambda func: func
        mock_on_request.return_value = lambda func: func
        
        yield {
            'db': mock_db,
            'rate_limiter': mock_rate_limiter_instance,
            'shipping_cost': mock_shipping,
            'tax_rate': mock_tax_rate,
            'send_email': mock_send_email,
            'on_call': mock_on_call,
            'on_request': mock_on_request
        }



@pytest.fixture
def valid_checkout_data():
    """Provides valid checkout data for testing checkout endpoints"""
    return {
        'items': [{'productId': 'prod_123', 'quantity': 2}],
        'shippingAddress': {
            'street': '123 Main St',
            'city': 'Toronto',
            'state': 'ON',
            'postalCode': 'M5V3A8',
            'country': 'Canada'
        },
        'subtotal': 100.00  # Valid subtotal (price * quantity = 50 * 2)
    }


@pytest.fixture
def mock_auth_user():
    """Provides a mock authenticated user"""
    auth = Mock()
    auth.uid = "test_user_123"
    auth.token = {"email": "test@example.com"}
    return auth


@pytest.fixture
def mock_product_data():
    """Provides typical mock product data"""
    return {
        'productId': 'prod_123',
        'name': 'Test Product',
        'price': 50.00,
        'stockQuantity': 10,
        'sellerId': 'seller_123',
        'imageUrls': ['https://example.com/image.jpg']
    }


def pytest_runtest_setup(item):
    """
    Vérifie les prérequis avant d'exécuter un test.
    Skip les tests marqués 'emulator' si l'émulateur n'est pas configuré.
    """
    if 'emulator' in item.keywords:
        if not os.getenv('FIRESTORE_EMULATOR_HOST'):
            pytest.skip("Test nécessite l'émulateur Firestore. "
                       "Définir FIRESTORE_EMULATOR_HOST pour l'activer.")
