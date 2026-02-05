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

# Create a real Response class for tests
class MockResponse:
    """Mock Firebase Response that behaves like a real response"""
    def __init__(self, body, status=200, headers=None, mimetype='text/plain'):
        self.status_code = status
        if isinstance(body, bytes):
            self.response = [body]
        else:
            self.response = [body.encode('utf-8') if isinstance(body, str) else body]
        self.headers = headers or {}
        self.mimetype = mimetype

# Patch the module before it's imported by test files
sys.modules['firebase_functions'] = MagicMock()
sys.modules['firebase_functions'].https_fn = MagicMock()
sys.modules['firebase_functions'].https_fn.on_call = decorator_passthrough
sys.modules['firebase_functions'].https_fn.on_request = decorator_passthrough
sys.modules['firebase_functions'].https_fn.CallableRequest = Mock
sys.modules['firebase_functions'].https_fn.HttpsError = MockHttpsError
sys.modules['firebase_functions'].https_fn.Response = MockResponse
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
    sinon évite l'initialisation pour les tests unitaires.
    """
    # Vérifier si l'émulateur est configuré
    using_emulator = os.getenv('FIRESTORE_EMULATOR_HOST') is not None
    
    # Éviter la double initialisation
    app = None
    if not firebase_admin._apps:
        if using_emulator:
            # Mode émulateur - utiliser les credentials par défaut
            print("🔧 Initialisation Firebase Admin avec l'émulateur Firestore")
            firebase_admin.initialize_app(options={
                'projectId': 'demo-test-project'
            })
            app = firebase_admin.get_app()
        else:
            # Mode mock - initialiser pour tests qui le nécessitent
            print("🔧 Firebase Admin: Mode test unitaire")
            mock_cred = Mock(spec=credentials.Certificate)
            firebase_admin.initialize_app(credential=mock_cred, options={
                'projectId': 'test-project'
            })
            app = firebase_admin.get_app()
    else:
        app = firebase_admin.get_app()
    
    yield app
    
    # Cleanup at end of session ONLY if we have exactly one app remaining
    # This prevents issues with multiple test files trying to initialize Firebase
    if firebase_admin._apps:
        try:
            remaining_apps = len(firebase_admin._apps)
            if remaining_apps == 1:
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
def reset_handler_globals():
    """
    Reset global variables in handler modules before each test
    to prevent state pollution between tests.
    """
    # Import handlers to reset their module-level globals
    from handlers import payment_stripe, products
    
    # Reset module-level caches
    payment_stripe._db = None
    payment_stripe._rate_limiter = None
    payment_stripe._firestore = None
    
    yield
    
    # Cleanup after test
    payment_stripe._db = None
    payment_stripe._rate_limiter = None
    payment_stripe._firestore = None


@pytest.fixture(scope="function", autouse=True)
def mock_firestore_client(monkeypatch):
    """
    Automatically mock Firestore client for all tests.
    This patches get_db() in payment_stripe and products modules.
    """
    from unittest.mock import MagicMock, Mock
    from handlers import payment_stripe, products
    
    # Create a comprehensive mock Firestore client
    mock_db = MagicMock()
    
    # Mock collection operations
    mock_collection = MagicMock()
    mock_db.collection.return_value = mock_collection
    
    # Mock document operations  
    mock_doc_ref = MagicMock()
    mock_collection.document.return_value = mock_doc_ref
    
    # Setup method chaining for where/limit/get patterns
    mock_collection.where.return_value = mock_collection
    mock_collection.limit.return_value = mock_collection
    mock_collection.get.return_value = []
    
    # Mock transaction support
    mock_transaction = MagicMock()
    mock_db.transaction.return_value = mock_transaction
    
    # Patch get_db to return our mock
    def mock_get_db():
        return mock_db
    
    monkeypatch.setattr(payment_stripe, 'get_db', mock_get_db)
    monkeypatch.setattr(products, 'get_db', mock_get_db)
    
    # Also mock stripe to prevent API calls
    from unittest.mock import MagicMock
    mock_stripe = MagicMock()
    mock_stripe.api_key = "STRIPE_SECRET_KEY_REDACTED"
    monkeypatch.setattr(payment_stripe, 'stripe', mock_stripe)
    
    yield mock_db



def create_mock_seller_doc(suspended=False, onboarded=True, charges=True, payouts=True):
    """Helper to create a mocked seller document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "roles": ["seller"],
        "suspended": suspended,
        "onboardingCompleted": onboarded,
        "chargesEnabled": charges,
        "payoutsEnabled": payouts,
        "email": "seller@example.com",
        "stripeAccountId": "acct_test_123"
    }
    return doc


def create_mock_product_doc(product_id='prod_123', price=50.00, stock_quantity=100, seller_id='seller_123'):
    """Helper to create a mocked product document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "productId": product_id,
        "name": "Test Product",
        "price": price,
        "stockQuantity": stock_quantity,
        "sellerId": seller_id,
        "imageUrls": ["http://example.com/image.jpg"],
        "categoryId": 1,
        "description": "Test description"
    }
    return doc


def create_mock_user_doc(email='user@example.com', name='Test User'):
    """Helper to create a mocked user document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "email": email,
        "displayName": name,
        "roles": ["buyer"]
    }
    return doc


def create_mock_order_doc(order_id='order_123', payment_status='paid', status='processing'):
    """Helper to create a mocked order document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "orderId": order_id,
        "paymentStatus": payment_status,
        "status": status,
        "items": [{
            "productId": "prod_123",
            "sellerId": "seller_123",
            "quantity": 2,
            "price": 50.00,
            "deliveryStatus": "pending"
        }],
        "amount": 100.00,
        "totalAmount": 100,
        "stripePaymentIntentId": "pi_test_123"
    }
    return doc


@pytest.fixture
def mock_seller_doc():
    """Create a properly mocked seller document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "roles": ["seller"],
        "suspended": False,
        "onboardingCompleted": True,
        "chargesEnabled": True,
        "payoutsEnabled": True,
        "email": "seller@example.com",
        "stripeAccountId": "acct_test_123"
    }
    return doc


@pytest.fixture
def mock_product_doc():
    """Create a properly mocked product document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "productId": "prod_123",
        "name": "Test Product",
        "price": 50.00,
        "stockQuantity": 100,
        "sellerId": "seller_123",
        "imageUrls": ["http://example.com/image.jpg"],
        "categoryId": 1,
        "description": "Test description"
    }
    return doc


@pytest.fixture
def mock_user_doc():
    """Create a properly mocked user document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "email": "user@example.com",
        "displayName": "Test User",
        "roles": ["buyer"]
    }
    return doc


@pytest.fixture
def mock_order_doc():
    """Create a properly mocked order document"""
    doc = Mock()
    doc.exists = True
    doc.to_dict.return_value = {
        "orderId": "order_123",
        "paymentStatus": "paid",
        "status": "processing",
        "items": [{
            "productId": "prod_123",
            "sellerId": "seller_123",
            "quantity": 2,
            "price": 50.00,
            "deliveryStatus": "pending"
        }],
        "amount": 100.00,
        "stripePaymentIntentId": "pi_test_123"
    }
    return doc


@pytest.fixture
def valid_checkout_data():
    """Provides valid checkout data for testing checkout endpoints"""
    return {
        'items': [{'productId': 'prod_123', 'quantity': 2, 'price': 50.00, 'sellerId': 'seller_123', 'name': 'Test Product'}],
        'shippingAddress': {
            'street': '123 Main St',
            'city': 'Toronto',
            'province': 'ON',
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


# ===== COMPREHENSIVE MOCK HELPER FUNCTIONS =====

def create_mock_seller_doc(suspended=False, onboarded=True, charges_enabled=True, payouts_enabled=True, 
                          seller_id='seller_123', email='seller@example.com', name='Test Seller'):
    """
    Creates a complete mock seller document with all required fields.
    
    Args:
        suspended: Whether the seller account is suspended
        onboarded: Whether onboarding is completed
        charges_enabled: Whether charges are enabled
        payouts_enabled: Whether payouts are enabled
        seller_id: The seller's ID
        email: The seller's email
        name: The seller's display name
    
    Returns:
        MagicMock object representing a Firestore document snapshot
    """
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = seller_id
    mock_doc.to_dict.return_value = {
        'sellerId': seller_id,
        'email': email,
        'displayName': name,
        'suspended': suspended,
        'onboardingCompleted': onboarded,
        'chargesEnabled': charges_enabled,
        'payoutsEnabled': payouts_enabled,
        'stripeConnectId': f'acct_{seller_id}',
        'createdAt': MagicMock(),
        'updatedAt': MagicMock()
    }
    return mock_doc


def create_mock_product_doc(product_id='prod_123', name='Test Product', price=50.00, 
                           stock_quantity=10, seller_id='seller_123', 
                           image_urls=None, deleted=False):
    """
    Creates a complete mock product document.
    
    Args:
        product_id: Product ID
        name: Product name
        price: Product price
        stock_quantity: Available stock
        seller_id: ID of the seller
        image_urls: List of image URLs
        deleted: Whether product is deleted
    
    Returns:
        MagicMock object representing a Firestore document snapshot
    """
    if image_urls is None:
        image_urls = ['https://example.com/image.jpg']
    
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = product_id
    mock_doc.to_dict.return_value = {
        'productId': product_id,
        'name': name,
        'price': price,
        'stockQuantity': stock_quantity,
        'sellerId': seller_id,
        'imageUrls': image_urls,
        'description': f'Description for {name}',
        'category': 'test_category',
        'deleted': deleted,
        'createdAt': MagicMock(),
        'updatedAt': MagicMock()
    }
    return mock_doc


def create_mock_user_doc(user_id='test_user_123', email='test@example.com', 
                        display_name='Test User', role='consumer'):
    """
    Creates a complete mock user document.
    
    Args:
        user_id: User ID
        email: User email
        display_name: User's display name
        role: User role (consumer/seller/admin)
    
    Returns:
        MagicMock object representing a Firestore document snapshot
    """
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = user_id
    mock_doc.to_dict.return_value = {
        'userId': user_id,
        'email': email,
        'displayName': display_name,
        'role': role,
        'createdAt': MagicMock(),
        'updatedAt': MagicMock()
    }
    return mock_doc


def create_mock_order_doc(order_id='order_123', consumer_id='test_user_123', 
                         status='pending', payment_status='authorized', items=None, 
                         total_amount=100.00, seller_id='seller_123'):
    """
    Creates a complete mock order document.
    
    Args:
        order_id: Order ID
        consumer_id: Consumer's user ID
        status: Order status (pending/processing/shipped/delivered/cancelled)
        payment_status: Payment status (authorized/captured/refunded)
        items: List of order items
        total_amount: Order total
        seller_id: ID of the seller
    
    Returns:
        MagicMock object representing a Firestore document snapshot
    """
    if items is None:
        items = [
            {
                'productId': 'prod_123',
                'quantity': 2,
                'price': 50.00,
                'name': 'Test Product'
            }
        ]
    
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = order_id
    mock_doc.to_dict.return_value = {
        'orderId': order_id,
        'consumerId': consumer_id,
        'status': status,
        'paymentStatus': payment_status,
        'items': items,
        'totalAmount': total_amount,
        'sellerId': seller_id,
        'stripePaymentIntentId': 'pi_test_123',
        'createdAt': MagicMock(),
        'updatedAt': MagicMock()
    }
    return mock_doc


def setup_mock_db_for_product_lookup(mock_db, product_data=None):
    """
    Sets up a mock Firestore database to return product data on lookups.
    Combined with seller lookup for complete checkout support.
    
    Args:
        mock_db: The mock Firestore database instance
        product_data: Dictionary of product_id -> product_data to return
    
    Returns:
        The configured mock_db instance
    """
    if product_data is None:
        product_data = {'prod_123': create_mock_product_doc()}
    
    # Create a unified document getter that handles all document lookups
    all_docs = dict(product_data)
    
    # Add some default sellers if not already present
    if 'seller_123' not in all_docs:
        all_docs['seller_123'] = create_mock_seller_doc()
    
    def make_doc_ref(doc_id):
        """Create a mock document reference"""
        mock_doc_ref = MagicMock()
        mock_doc_ref.id = doc_id
        
        if doc_id in all_docs:
            mock_doc_ref.get.return_value = all_docs[doc_id]
        else:
            not_found_doc = MagicMock()
            not_found_doc.exists = False
            mock_doc_ref.get.return_value = not_found_doc
        
        return mock_doc_ref
    
    # Create unified collection mock
    mock_collection = MagicMock()
    mock_collection.document = make_doc_ref
    mock_db.collection.return_value = mock_collection
    
    return mock_db


def setup_mock_db_for_seller_lookup(mock_db, seller_data=None):
    """
    Sets up a mock Firestore database to return seller data on lookups.
    
    Args:
        mock_db: The mock Firestore database instance
        seller_data: Dictionary of seller_id -> seller_data to return
    
    Returns:
        The configured mock_db instance
    """
    if seller_data is None:
        seller_data = {'seller_123': create_mock_seller_doc()}
    
    # Setup transaction mock for transactional lookups
    def make_doc_ref(doc_id):
        """Create a mock document reference"""
        mock_doc_ref = MagicMock()
        mock_doc_ref.id = doc_id
        
        if doc_id in seller_data:
            mock_doc_ref.get.return_value = seller_data[doc_id]
        else:
            not_found_doc = MagicMock()
            not_found_doc.exists = False
            mock_doc_ref.get.return_value = not_found_doc
        
        return mock_doc_ref
    
    # For transaction.get(doc_ref)
    def transaction_get_side_effect(doc_ref):
        doc_id = doc_ref.id if hasattr(doc_ref, 'id') else str(doc_ref)
        if doc_id in seller_data:
            return seller_data[doc_id]
        not_found = MagicMock()
        not_found.exists = False
        return not_found
    
    mock_transaction = MagicMock()
    mock_transaction.get.side_effect = transaction_get_side_effect
    mock_db.transaction.return_value = mock_transaction
    
    # Also ensure collection().document() works
    mock_collection = MagicMock()
    mock_collection.document = make_doc_ref
    mock_db.collection.return_value = mock_collection
    
    return mock_db


def pytest_runtest_setup(item):
    """
    Vérifie les prérequis avant d'exécuter un test.
    Skip les tests marqués 'emulator' si l'émulateur n'est pas configuré.
    """
    if 'emulator' in item.keywords:
        if not os.getenv('FIRESTORE_EMULATOR_HOST'):
            pytest.skip("Test nécessite l'émulateur Firestore. "
                       "Définir FIRESTORE_EMULATOR_HOST pour l'activer.")


# ============================================================================
# COMPREHENSIVE FIRESTORE MOCK BUILDER
# ============================================================================

class FirestoreMockBuilder:
    """
    Comprehensive builder for creating realistic Firestore mocks
    that support complete document chains, transactions, and batch operations.
    """
    
    def __init__(self):
        self.documents = {}  # Store: {collection_name: {doc_id: doc_data}}
        self.queries = {}    # Store: {query_key: results}
    
    def add_document(self, collection_name, doc_id, doc_data):
        """Add a document to mock storage"""
        if collection_name not in self.documents:
            self.documents[collection_name] = {}
        self.documents[collection_name][doc_id] = doc_data
        return self
    
    def add_seller(self, seller_id='seller_123', suspended=False, onboarded=True):
        """Add a seller document"""
        return self.add_document('users', seller_id, {
            "roles": ["seller"],
            "suspended": suspended,
            "onboardingCompleted": onboarded,
            "chargesEnabled": True,
            "payoutsEnabled": True,
            "email": f"{seller_id}@example.com",
            "stripeAccountId": f"acct_{seller_id}"
        })
    
    def add_product(self, product_id='prod_123', seller_id='seller_123', price=50.00, stock=100):
        """Add a product document"""
        return self.add_document('products', product_id, {
            "productId": product_id,
            "name": "Test Product",
            "price": price,
            "stockQuantity": stock,
            "sellerId": seller_id,
            "imageUrls": ["http://example.com/image.jpg"],
            "categoryId": 1,
            "description": "Test description"
        })
    
    def add_user(self, user_id='user_123', email='user@example.com', name='Test User'):
        """Add a user document"""
        return self.add_document('users', user_id, {
            "email": email,
            "displayName": name,
            "roles": ["buyer"]
        })
    
    def add_order(self, order_id='order_123', payment_status='paid', order_status='processing'):
        """Add an order document"""
        return self.add_document('orders', order_id, {
            "orderId": order_id,
            "paymentStatus": payment_status,
            "orderStatus": order_status,
            "status": order_status,
            "items": [{
                "productId": "prod_123",
                "sellerId": "seller_123",
                "quantity": 2,
                "price": 50.00,
                "deliveryStatus": "pending"
            }],
            "amount": 100.00,
            "stripePaymentIntentId": "pi_test_123"
        })
    
    def build_mock_db(self):
        """Build a complete mock database"""
        mock_db = MagicMock()
        builder = self
        
        # Create collection() method that returns collection mocks
        def collection_impl(collection_name):
            # Normalize collection_name: accept enums, mock objects with .value, or other objects
            if hasattr(collection_name, 'value'):
                collection_name = collection_name.value
            elif not isinstance(collection_name, str):
                try:
                    collection_name = str(collection_name)
                except Exception:
                    collection_name = repr(collection_name)

            mock_collection = MagicMock()
            
            # Create document() method that returns document refs
            def document_impl(doc_id=None):
                if doc_id is None:
                    doc_id = 'auto_generated_id'
                mock_doc_ref = MagicMock()
                mock_doc_ref.id = doc_id
                
                # Create get() method that returns document snapshots
                def get_impl(transaction=None):
                    # Return the stored document if present, else a not-found snapshot
                    col = collection_name
                    if hasattr(col, 'value'):
                        col = col.value
                    if col in builder.documents and doc_id in builder.documents[col]:
                        mock_doc = MagicMock()
                        mock_doc.exists = True
                        mock_doc.to_dict.return_value = builder.documents[col][doc_id]
                        mock_doc.id = doc_id
                        return mock_doc
                    mock_doc = MagicMock()
                    mock_doc.exists = False
                    return mock_doc
                
                mock_doc_ref.get = get_impl
                
                # Create update() and set() methods
                def update_impl(data):
                    if collection_name not in builder.documents:
                        builder.documents[collection_name] = {}
                    builder.documents[collection_name][doc_id].update(data)
                
                def set_impl(data, merge=False):
                    if collection_name not in builder.documents:
                        builder.documents[collection_name] = {}
                    if merge and doc_id in builder.documents[collection_name]:
                        builder.documents[collection_name][doc_id].update(data)
                    else:
                        builder.documents[collection_name][doc_id] = data
                
                mock_doc_ref.update = update_impl
                mock_doc_ref.set = set_impl
                mock_doc_ref.delete = MagicMock()
                
                return mock_doc_ref
            
            mock_collection.document = document_impl
            
            # Create where() method for queries
            def where_impl(field, operator, value):
                mock_query = MagicMock()
                
                def get_impl():
                    results = []
                    if collection_name in builder.documents:
                        for doc_id, doc_data in builder.documents[collection_name].items():
                            if field in doc_data:
                                if operator == '==' and doc_data[field] == value:
                                    mock_doc = MagicMock()
                                    mock_doc.id = doc_id
                                    mock_doc.to_dict.return_value = doc_data
                                    results.append(mock_doc)
                                elif operator == 'in' and doc_data[field] in value:
                                    mock_doc = MagicMock()
                                    mock_doc.id = doc_id
                                    mock_doc.to_dict.return_value = doc_data
                                    results.append(mock_doc)
                    return MagicMock(docs=results)
                
                mock_query.get = get_impl
                mock_query.where = where_impl  # Support chaining
                return mock_query
            
            mock_collection.where = where_impl
            
            # Create add() method for creating new documents
            def add_impl(data):
                import uuid
                new_id = str(uuid.uuid4())
                if collection_name not in builder.documents:
                    builder.documents[collection_name] = {}
                builder.documents[collection_name][new_id] = data
                return (MagicMock(id=new_id), new_id)
            
            mock_collection.add = add_impl
            
            # Create limit() method
            def limit_impl(count):
                mock_query = MagicMock()
                mock_query.get = MagicMock(return_value=MagicMock(docs=[]))
                return mock_query
            
            mock_collection.limit = limit_impl
            
            return mock_collection
        
        mock_db.collection = collection_impl
        
        # Create transaction() method
        def transaction_impl():
            mock_transaction = MagicMock()

            def get_impl(doc_ref):
                # Extract doc_id from reference-like objects (support .id, .path)
                doc_id = None
                if hasattr(doc_ref, 'id'):
                    doc_id = getattr(doc_ref, 'id')
                elif hasattr(doc_ref, 'path'):
                    try:
                        doc_id = str(doc_ref.path).split('/')[-1]
                    except Exception:
                        doc_id = str(doc_ref)
                else:
                    doc_id = str(doc_ref)

                # Find collection and return the matching stored document
                for collection_name, docs in builder.documents.items():
                    # Normalize collection_name keys if they are not strings
                    key = collection_name.value if hasattr(collection_name, 'value') else collection_name
                    if doc_id in docs:
                        mock_doc = MagicMock()
                        mock_doc.exists = True
                        mock_doc.to_dict.return_value = docs[doc_id]
                        mock_doc.id = doc_id
                        return mock_doc

                mock_doc = MagicMock()
                mock_doc.exists = False
                return mock_doc

            mock_transaction.get = get_impl
            mock_transaction.update = MagicMock()
            mock_transaction.set = MagicMock()
            mock_transaction.delete = MagicMock()
            
            return mock_transaction
        
        mock_db.transaction = transaction_impl
        mock_db.batch = MagicMock(return_value=MagicMock())
        
        return mock_db


@pytest.fixture
def firestore_mock_builder():
    """Fixture providing a Firestore mock builder"""
    return FirestoreMockBuilder()
