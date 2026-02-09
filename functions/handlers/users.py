"""
User Management Handlers
- User profile updates
- Tax exemption management
"""

from typing import Any

from firebase_functions import https_fn

from function_options import DEFAULT_OPTIONS
from schema_constants import Collections, Fields
from utils import create_success_response

_db = None


def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db
    if _db is None:
        from firebase_admin import firestore
        _db = firestore.client()
    return _db


def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP."""
    from firebase_admin import firestore
    return firestore.SERVER_TIMESTAMP


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_user_profile(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Update user profile fields including tax exemption.
    
    Request data:
        - taxExemption: {gstNumber: "123456789RT0001"} | null (optional)
        - address: Address object (optional)
        - name: string (optional)
        
    Security:
        - User can only update their own profile
        - GST number validation (basic format check)
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    data = req.data
    
    # Build update data
    update_data = {
        Fields.UPDATED_AT: get_server_timestamp(),
    }
    
    # Handle tax exemption update
    if 'taxExemption' in data:
        tax_exemption = data['taxExemption']
        
        if tax_exemption is None:
            # Remove tax exemption
            update_data[Fields.TAX_EXEMPTION] = None
        else:
            gst_number = tax_exemption.get('gstNumber', '').strip().upper()
            
            # Basic GST number validation (Canadian format: 123456789RT0001)
            if gst_number:
                import re
                # Canadian GST/HST/QST numbers: 9 digits + RT/QST + 4 digits
                if not re.match(r'^\d{9}[A-Z]{2}\d{4}$', gst_number):
                    raise https_fn.HttpsError(
                        'invalid-argument',
                        'Invalid GST number format. Expected: 123456789RT0001'
                    )
                
                update_data[Fields.TAX_EXEMPTION] = {
                    'gstNumber': gst_number,
                    'verified': False,  # Could add CRA verification in future
                    'updatedAt': get_server_timestamp(),
                }
    
    # Handle address update
    if 'address' in data:
        from models.base import Address
        try:
            address = Address(**data['address'])
            update_data[Fields.ADDRESS] = address.model_dump()
        except Exception as e:
            raise https_fn.HttpsError('invalid-argument', f'Invalid address: {str(e)}')
    
    # Handle name update
    if 'name' in data:
        name = data['name'].strip()
        if len(name) < 2 or len(name) > 60:
            raise https_fn.HttpsError(
                'invalid-argument',
                'Name must be between 2 and 60 characters'
            )
        update_data[Fields.NAME] = name
    
    # Update user document
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_ref.update(update_data)
    
    return create_success_response({
        'updated': True,
        'fields': list(update_data.keys()),
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_user_profile(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Get current user's profile including tax exemption status.
    
    Returns:
        User profile data with tax exemption info
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    
    # Return safe profile data
    return create_success_response({
        'uid': user_id,
        'email': user_data.get(Fields.EMAIL),
        'name': user_data.get(Fields.NAME),
        'address': user_data.get(Fields.ADDRESS),
        'taxExemption': user_data.get(Fields.TAX_EXEMPTION),
        'roles': user_data.get(Fields.ROLES, ['buyer']),
        'createdAt': user_data.get(Fields.CREATED_AT),
        'updatedAt': user_data.get(Fields.UPDATED_AT),
    })
