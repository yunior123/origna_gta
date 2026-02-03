"""
Rate Limiter for Cloud Functions
Protects against abuse and DDoS
"""
from firebase_admin import firestore
from datetime import datetime, timedelta
from typing import Tuple

class RateLimiter:
    """Simple in-memory + Firestore rate limiter"""
    
    def __init__(self, db):
        self.db = db
        self.collection = 'rate_limits'
    
    def check_rate_limit(
        self, 
        identifier: str,  # IP, user_id, email
        action: str,  # 'create_checkout', 'webhook', etc
        max_requests: int,
        window_minutes: int,
        fail_closed: bool = False  # If True, block on errors (for auth/payment)
    ) -> Tuple[bool, str]:
        """
        Returns (allowed: bool, message: str)
        
        SECURITY FIX: Added fail_closed parameter.
        - fail_closed=False (default): Fail-open for UX (product views)
        - fail_closed=True: Fail-closed for security (auth, payments)
        
        EDGE CASE FIX #4: Use Firestore transaction to prevent race conditions.
        Without transaction, concurrent requests could bypass rate limit.
        """
        now = datetime.utcnow()
        window_start = now - timedelta(minutes=window_minutes)
        
        doc_id = f"{action}_{identifier}"
        ref = self.db.collection(self.collection).document(doc_id)
        
        try:
            # FIXED: Use transaction to prevent race conditions
            @firestore.transactional
            def check_and_increment(transaction, ref):
                doc = ref.get(transaction=transaction)
                
                if doc.exists:
                    data = doc.to_dict()
                    count = data.get('count', 0)
                    first_request = data.get('first_request').replace(tzinfo=None)
                    
                    # Window expired, reset
                    if first_request < window_start:
                        transaction.set(ref, {
                            'count': 1,
                            'first_request': now,
                            'last_request': now
                        })
                        return True, "OK"
                    
                    # Within window, check limit
                    if count >= max_requests:
                        return False, f"Rate limit exceeded: {max_requests} requests per {window_minutes} minutes"
                    
                    # Increment atomically
                    transaction.update(ref, {
                        'count': count + 1,
                        'last_request': now
                    })
                    return True, "OK"
                else:
                    # First request
                    transaction.set(ref, {
                        'count': 1,
                        'first_request': now,
                        'last_request': now
                    })
                    return True, "OK"
            
            # Execute transaction
            transaction = self.db.transaction()
            return check_and_increment(transaction, ref)
                
        except Exception as e:
            print(f"⚠️ Rate limiter error: {e}")
            
            # SECURITY FIX: Fail-closed for high-stakes actions
            if fail_closed:
                return False, "Rate limiter unavailable - request blocked for security"
            
            # Fail-open for UX-critical actions (don't block legitimate users)
            return True, "OK"
    
    def get_identifier(self, req) -> str:
        """Extract identifier from request (IP or user_id)"""
        # Try user ID first
        if hasattr(req, 'auth') and req.auth:
            return f"user_{req.auth.uid}"
        
        # Fall back to IP
        if hasattr(req, 'headers'):
            # Check for forwarded IP (behind proxy)
            forwarded = req.headers.get('X-Forwarded-For', '').split(',')[0].strip()
            if forwarded:
                return f"ip_{forwarded}"
            
            # Direct IP
            remote_addr = req.headers.get('X-Real-IP', 'unknown')
            return f"ip_{remote_addr}"
        
        return "unknown"
