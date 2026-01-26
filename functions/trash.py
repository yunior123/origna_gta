
# def validate_request_method(req: https_fn.Request, allowed_method: str = "POST") -> Optional[https_fn.Response]:
#     """Validate HTTP request method"""
#     if req.method == "OPTIONS":
#         return https_fn.Response("", status=204)
    
#     if req.method != allowed_method:
#         return https_fn.Response(
#             json.dumps({"error": f"Method not allowed. Use {allowed_method}"}),
#             status=405,
#             headers={"Content-Type": "application/json"}
#         )
#     return None


# def create_error_response(error_message: str, status_code: int = 400) -> https_fn.Response:
#     """Create standardized error response"""
#     return https_fn.Response(
#         json.dumps({"error": error_message, "success": False}),
#         status=status_code,
#         headers={"Content-Type": "application/json"}
#     )


# def create_success_response(data: Dict[str, Any], status_code: int = 200) -> https_fn.Response:
#     """Create standardized success response"""
#     response_data = {**data, "success": True}
#     return https_fn.Response(
#         json.dumps(response_data),
#         status=status_code,
#         headers={"Content-Type": "application/json"}
#     )


# @https_fn.on_request(cors=cors_config, timeout_sec=60)
# def create_payment_intent(req: https_fn.Request) -> https_fn.Response:
#     """
#     Create a Stripe Payment Intent
    
#     Request body:
#     {
#         "amount": 1000,  // Amount in cents (e.g., $10.00)
#         "currency": "usd",  // Currency code
#         "customerId": "cus_xxx",  // Optional: Stripe customer ID
#         "description": "Product purchase",  // Optional
#         "metadata": {  // Optional
#             "orderId": "order_123",
#             "userId": "user_456"
#         },
#         "receiptEmail": "customer@example.com"  // Optional
#     }
    
#     Response:
#     {
#         "clientSecret": "pi_xxx_secret_xxx",
#         "paymentIntentId": "pi_xxx",
#         "amount": 1000,
#         "currency": "usd",
#         "success": true
#     }
#     """
#     try:
#         # Validate request method
#         method_check = validate_request_method(req, "POST")
#         if method_check:
#             return method_check
        
#         # Parse request body
#         try:
#             data = req.get_json()
#         except Exception:
#             return create_error_response("Invalid JSON in request body")
        
#         # Validate required fields
#         amount = data.get("amount")
#         if not amount:
#             return create_error_response("Missing required field: amount")
        
#         if not isinstance(amount, int) or amount < 50:
#             return create_error_response("Invalid amount. Must be an integer >= 50 (cents)")
        
#         currency = data.get("currency", "usd").lower()
#         customer_id = data.get("customerId")
#         description = data.get("description", "Payment")
#         metadata = data.get("metadata", {})
#         receipt_email = data.get("receiptEmail")
        
#         # Validate customer ID if provided
#         if customer_id:
#             try:
#                 stripe.Customer.retrieve(customer_id)
#             except stripe.error.InvalidRequestError:
#                 return create_error_response("Invalid customer ID", 400)
        
#         # Create payment intent parameters
#         intent_params = {
#             "amount": int(amount),
#             "currency": currency,
#             "description": description,
#             "automatic_payment_methods": {"enabled": True},
#             "metadata": {
#                 **metadata,
#                 "created_via": "firebase_function",
#                 "timestamp": datetime.utcnow().isoformat()
#             }
#         }
        
#         # Add optional parameters
#         if customer_id:
#             intent_params["customer"] = customer_id
        
#         if receipt_email:
#             intent_params["receipt_email"] = receipt_email
        
#         # Create the payment intent
#         intent = stripe.PaymentIntent.create(**intent_params)
        
#         # Store payment intent in Firestore for auditing
#         try:
#             payment_doc = {
#                 "paymentIntentId": intent.id,
#                 "amount": amount,
#                 "currency": currency,
#                 "status": intent.status,
#                 "description": description,
#                 "customerId": customer_id,
#                 "metadata": metadata,
#                 "createdAt": firestore.SERVER_TIMESTAMP,
#                 "updatedAt": firestore.SERVER_TIMESTAMP
#             }
            
#             db.collection("payment_intents").document(intent.id).set(payment_doc)
#         except Exception as firestore_error:
#             print(f"Warning: Could not save to Firestore: {firestore_error}")
#             # Continue anyway since payment intent was created
        
#         # Return success response
#         return create_success_response({
#             "clientSecret": intent.client_secret,
#             "paymentIntentId": intent.id,
#             "amount": intent.amount,
#             "currency": intent.currency,
#             "status": intent.status
#         })
        
#     except stripe.error.CardError as e:
#         print(f"Card error: {str(e)}")
#         return create_error_response(f"Card error: {e.user_message}", 402)
    
#     except stripe.error.RateLimitError as e:
#         print(f"Rate limit error: {str(e)}")
#         return create_error_response("Too many requests. Please try again later.", 429)
    
#     except stripe.error.InvalidRequestError as e:
#         print(f"Invalid request error: {str(e)}")
#         return create_error_response(f"Invalid request: {str(e)}", 400)
    
#     except stripe.error.AuthenticationError as e:
#         print(f"Authentication error: {str(e)}")
#         return create_error_response("Authentication failed. Please contact support.", 500)
    
#     except stripe.error.StripeError as e:
#         print(f"Stripe error: {str(e)}")
#         return create_error_response(f"Payment processing error: {str(e)}", 500)
    
#     except Exception as e:
#         print(f"Unexpected error creating payment intent: {str(e)}")
#         return create_error_response(f"Internal server error: {str(e)}", 500)


# @https_fn.on_request(cors=cors_config, timeout_sec=30)
# def create_customer(req: https_fn.Request) -> https_fn.Response:
#     """
#     Create a Stripe Customer
    
#     Request body:
#     {
#         "email": "user@example.com",  // Required
#         "name": "John Doe",  // Optional
#         "phone": "+1234567890",  // Optional
#         "userId": "firebase_uid",  // Optional: Firebase user ID
#         "metadata": {}  // Optional
#     }
    
#     Response:
#     {
#         "customerId": "cus_xxx",
#         "email": "user@example.com",
#         "name": "John Doe",
#         "success": true
#     }
#     """
#     try:
#         # Validate request method
#         method_check = validate_request_method(req, "POST")
#         if method_check:
#             return method_check
        
#         # Parse request body
#         try:
#             data = req.get_json()
#         except Exception:
#             return create_error_response("Invalid JSON in request body")
        
#         # Validate required fields
#         email = data.get("email")
#         if not email or "@" not in email:
#             return create_error_response("Valid email is required")
        
#         name = data.get("name")
#         phone = data.get("phone")
#         user_id = data.get("userId")
#         metadata = data.get("metadata", {})
        
#         # Check if customer already exists for this user
#         if user_id:
#             try:
#                 user_ref = db.collection("users").document(user_id)
#                 user_doc = user_ref.get()
                
#                 if user_doc.exists:
#                     existing_customer_id = user_doc.to_dict().get("stripeCustomerId")
#                     if existing_customer_id:
#                         try:
#                             # Verify customer still exists in Stripe
#                             existing_customer = stripe.Customer.retrieve(existing_customer_id)
#                             return create_success_response({
#                                 "customerId": existing_customer.id,
#                                 "email": existing_customer.email,
#                                 "name": existing_customer.name,
#                                 "alreadyExists": True
#                             })
#                         except stripe.error.InvalidRequestError:
#                             # Customer was deleted from Stripe, create new one
#                             pass
#             except Exception as firestore_error:
#                 print(f"Warning: Could not check Firestore: {firestore_error}")
#                 # Continue to create customer anyway
        
#         # Create customer parameters
#         customer_params = {
#             "email": email,
#             "metadata": {
#                 **metadata,
#                 "created_via": "firebase_function"
#             }
#         }
        
#         if name:
#             customer_params["name"] = name
        
#         if phone:
#             customer_params["phone"] = phone
        
#         if user_id:
#             customer_params["metadata"]["firebase_uid"] = user_id
        
#         # Create Stripe customer
#         customer = stripe.Customer.create(**customer_params)
        
#         # Store customer in Firestore
#         try:
#             customer_data = {
#                 "stripeCustomerId": customer.id,
#                 "email": email,
#                 "name": name,
#                 "phone": phone,
#                 "createdAt": firestore.SERVER_TIMESTAMP,
#                 "updatedAt": firestore.SERVER_TIMESTAMP
#             }
            
#             if user_id:
#                 db.collection("users").document(user_id).set(customer_data, merge=True)
            
#             # Also store in customers collection
#             db.collection("customers").document(customer.id).set(customer_data)
#         except Exception as firestore_error:
#             print(f"Warning: Could not save to Firestore: {firestore_error}")
#             # Continue anyway since customer was created
        
#         return create_success_response({
#             "customerId": customer.id,
#             "email": customer.email,
#             "name": customer.name,
#             "alreadyExists": False
#         })
        
#     except stripe.error.StripeError as e:
#         print(f"Stripe error creating customer: {str(e)}")
#         return create_error_response(f"Error creating customer: {str(e)}", 500)
    
#     except Exception as e:
#         print(f"Unexpected error creating customer: {str(e)}")
#         return create_error_response(f"Internal server error: {str(e)}", 500)


# @https_fn.on_request(cors=cors_config, timeout_sec=30)
# def confirm_payment(req: https_fn.Request) -> https_fn.Response:
#     """
#     Confirm and retrieve payment status
    
#     Request body:
#     {
#         "paymentIntentId": "pi_xxx"
#     }
    
#     Response:
#     {
#         "status": "succeeded",
#         "amount": 1000,
#         "currency": "usd",
#         "paymentIntentId": "pi_xxx",
#         "success": true
#     }
#     """
#     try:
#         # Validate request method
#         method_check = validate_request_method(req, "POST")
#         if method_check:
#             return method_check
        
#         # Parse request body
#         try:
#             data = req.get_json()
#         except Exception:
#             return create_error_response("Invalid JSON in request body")
        
#         payment_intent_id = data.get("paymentIntentId")
        
#         if not payment_intent_id:
#             return create_error_response("Missing required field: paymentIntentId")
        
#         # Retrieve payment intent from Stripe
#         intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        
#         # Update Firestore
#         try:
#             payment_update = {
#                 "status": intent.status,
#                 "updatedAt": firestore.SERVER_TIMESTAMP
#             }
            
#             if intent.status == "succeeded":
#                 payment_update["succeededAt"] = firestore.SERVER_TIMESTAMP
#                 if intent.charges and intent.charges.data:
#                     charge = intent.charges.data[0]
#                     payment_update["chargeId"] = charge.id
#                     payment_update["receiptUrl"] = charge.receipt_url
            
#             db.collection("payment_intents").document(intent.id).update(payment_update)
#         except Exception as firestore_error:
#             print(f"Warning: Could not update Firestore: {firestore_error}")
#             # Continue anyway since we have the payment status
        
#         receipt_url = None
#         if intent.charges and intent.charges.data:
#             receipt_url = intent.charges.data[0].receipt_url
        
#         return create_success_response({
#             "status": intent.status,
#             "amount": intent.amount,
#             "currency": intent.currency,
#             "paymentIntentId": intent.id,
#             "description": intent.description,
#             "receiptUrl": receipt_url
#         })
        
#     except stripe.error.InvalidRequestError as e:
#         print(f"Invalid payment intent ID: {str(e)}")
#         return create_error_response("Invalid payment intent ID", 404)
    
#     except stripe.error.StripeError as e:
#         print(f"Stripe error confirming payment: {str(e)}")
#         return create_error_response(f"Error confirming payment: {str(e)}", 500)
    
#     except Exception as e:
#         print(f"Unexpected error confirming payment: {str(e)}")
#         return create_error_response(f"Internal server error: {str(e)}", 500)


# @https_fn.on_request(cors=cors_config, timeout_sec=30)
# def get_payment_methods(req: https_fn.Request) -> https_fn.Response:
#     """
#     Get all payment methods for a customer
    
#     Request body:
#     {
#         "customerId": "cus_xxx"
#     }
    
#     Response:
#     {
#         "paymentMethods": [...],
#         "success": true
#     }
#     """
#     try:
#         # Validate request method
#         method_check = validate_request_method(req, "POST")
#         if method_check:
#             return method_check
        
#         # Parse request body
#         try:
#             data = req.get_json()
#         except Exception:
#             return create_error_response("Invalid JSON in request body")
        
#         customer_id = data.get("customerId")
        
#         if not customer_id:
#             return create_error_response("Missing required field: customerId")
        
#         # Get payment methods from Stripe
#         payment_methods = stripe.PaymentMethod.list(
#             customer=customer_id,
#             type="card"
#         )
        
#         # Format payment methods for response
#         formatted_methods = []
#         for pm in payment_methods.data:
#             formatted_methods.append({
#                 "id": pm.id,
#                 "brand": pm.card.brand,
#                 "last4": pm.card.last4,
#                 "expMonth": pm.card.exp_month,
#                 "expYear": pm.card.exp_year
#             })
        
#         return create_success_response({
#             "paymentMethods": formatted_methods
#         })
        
#     except stripe.error.StripeError as e:
#         print(f"Stripe error getting payment methods: {str(e)}")
#         return create_error_response(f"Error retrieving payment methods: {str(e)}", 500)
    
#     except Exception as e:
#         print(f"Unexpected error getting payment methods: {str(e)}")
#         return create_error_response(f"Internal server error: {str(e)}", 500)
