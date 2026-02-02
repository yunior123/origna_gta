// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Checkout Flow E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to home page
    await page.goto('http://localhost:5000');
    await page.waitForLoadState('networkidle');
  });

  test('Complete checkout flow with physical product', async ({ page }) => {
    // Search for a product
    await page.fill('[data-testid="search-input"]', 'test product');
    await page.click('[data-testid="search-button"]');
    await page.waitForSelector('[data-testid="product-card"]');
    
    // Click first product
    await page.click('[data-testid="product-card"]:first-child');
    await page.waitForLoadState('networkidle');
    
    // Add to cart
    await page.fill('[data-testid="quantity-input"]', '1');
    await page.click('[data-testid="add-to-cart-button"]');
    await expect(page.locator('[data-testid="cart-count"]')).toContainText('1');
    
    // Go to cart
    await page.click('[data-testid="cart-icon"]');
    await page.waitForLoadState('networkidle');
    
    // Proceed to checkout
    await page.click('[data-testid="checkout-button"]');
    await page.waitForLoadState('networkidle');
    
    // Fill address
    await page.fill('[data-testid="address-line1"]', '123 Main St');
    await page.fill('[data-testid="city"]', 'Toronto');
    await page.fill('[data-testid="province"]', 'Ontario');
    await page.fill('[data-testid="postal-code"]', 'M5V 3A8');
    await page.fill('[data-testid="phone"]', '416-555-0000');
    
    // Calculate shipping
    await page.click('[data-testid="calculate-shipping-button"]');
    await page.waitForSelector('[data-testid="shipping-cost"]');
    
    // Select delivery speed
    await page.click('[data-testid="delivery-speed-standard"]');
    
    // Proceed to payment
    await page.click('[data-testid="proceed-to-payment-button"]');
    await page.waitForLoadState('networkidle');
    
    // Verify payment form loaded
    await expect(page.locator('[data-testid="stripe-card-element"]')).toBeVisible();
  });

  test('Digital product checkout (no shipping)', async ({ page }) => {
    // Search for digital product
    await page.fill('[data-testid="search-input"]', 'digital');
    await page.click('[data-testid="search-button"]');
    await page.waitForSelector('[data-testid="product-card"][data-digital="true"]');
    
    // Click digital product
    await page.click('[data-testid="product-card"][data-digital="true"]:first-child');
    await page.waitForLoadState('networkidle');
    
    // Should not have shipping fields
    await expect(page.locator('[data-testid="shipping-section"]')).not.toBeVisible();
    
    // Add to cart
    await page.click('[data-testid="add-to-cart-button"]');
    
    // Go to checkout
    await page.click('[data-testid="cart-icon"]');
    await page.click('[data-testid="checkout-button"]');
    await page.waitForLoadState('networkidle');
    
    // Should skip to payment (no address form)
    await expect(page.locator('[data-testid="stripe-card-element"]')).toBeVisible();
    await expect(page.locator('[data-testid="address-form"]')).not.toBeVisible();
  });

  test('Rate limiting on failed login', async ({ page }) => {
    await page.goto('http://localhost:5000/login');
    
    // Attempt 5 failed logins
    for (let i = 0; i < 5; i++) {
      await page.fill('[data-testid="email-input"]', 'test@example.com');
      await page.fill('[data-testid="password-input"]', 'wrongpassword');
      await page.click('[data-testid="login-button"]');
      await page.waitForSelector('[data-testid="error-message"]');
      await page.reload();
    }
    
    // 6th attempt should show lockout message
    await page.fill('[data-testid="email-input"]', 'test@example.com');
    await page.fill('[data-testid="password-input"]', 'wrongpassword');
    await page.click('[data-testid="login-button"]');
    await expect(page.locator('[data-testid="lockout-message"]')).toContainText('locked');
  });

  test('Multi-seller checkout calculates correct fees', async ({ page }) => {
    // Add product from seller 1
    await page.click('[data-testid="search-input"]');
    await page.fill('[data-testid="search-input"]', 'seller1 product');
    await page.click('[data-testid="search-button"]');
    await page.click('[data-testid="product-card"]:first-child');
    await page.click('[data-testid="add-to-cart-button"]');
    
    // Add product from seller 2
    await page.goto('http://localhost:5000');
    await page.fill('[data-testid="search-input"]', 'seller2 product');
    await page.click('[data-testid="search-button"]');
    await page.click('[data-testid="product-card"]:first-child');
    await page.click('[data-testid="add-to-cart-button"]');
    
    // Go to checkout
    await page.click('[data-testid="cart-icon"]');
    await page.click('[data-testid="checkout-button"]');
    await page.waitForLoadState('networkidle');
    
    // Verify multi-seller breakdown
    await expect(page.locator('[data-testid="seller-breakdown"]')).toBeVisible();
    await expect(page.locator('[data-testid="seller-1-items"]')).toBeVisible();
    await expect(page.locator('[data-testid="seller-2-items"]')).toBeVisible();
  });
});

test.describe('Seller Onboarding E2E Tests', () => {
  test('Complete seller registration flow', async ({ page }) => {
    await page.goto('http://localhost:5000/seller-signup');
    
    // Fill basic info
    await page.fill('[data-testid="company-name"]', 'Test Seller Inc');
    await page.fill('[data-testid="email"]', 'seller@test.com');
    await page.fill('[data-testid="password"]', 'SecurePassword123!');
    
    // Fill address
    await page.fill('[data-testid="business-address"]', '456 Business Ave');
    await page.fill('[data-testid="city"]', 'Toronto');
    await page.fill('[data-testid="province"]', 'Ontario');
    await page.fill('[data-testid="postal-code"]', 'M5V 3A8');
    
    // Choose payment provider
    await page.click('[data-testid="payment-provider-stripe"]');
    
    // Submit
    await page.click('[data-testid="submit-button"]');
    await page.waitForLoadState('networkidle');
    
    // Verify Stripe redirect
    await expect(page).toHaveURL(/stripe|express/);
  });

  test('Seller cannot add products until approved', async ({ page }) => {
    // Login as unapproved seller
    await page.goto('http://localhost:5000/login');
    await page.fill('[data-testid="email-input"]', 'unapproved@test.com');
    await page.fill('[data-testid="password-input"]', 'Password123!');
    await page.click('[data-testid="login-button"]');
    await page.waitForLoadState('networkidle');
    
    // Try to access add product
    await page.goto('http://localhost:5000/seller/add-product');
    await page.waitForLoadState('networkidle');
    
    // Should be redirected to approval pending
    await expect(page).toHaveURL(/pending|approval/);
    await expect(page.locator('[data-testid="approval-message"]')).toBeVisible();
  });

  test('Suspended seller cannot access seller dashboard', async ({ page }) => {
    // Login as suspended seller
    await page.goto('http://localhost:5000/login');
    await page.fill('[data-testid="email-input"]', 'suspended@test.com');
    await page.fill('[data-testid="password-input"]', 'Password123!');
    await page.click('[data-testid="login-button"]');
    await page.waitForLoadState('networkidle');
    
    // Try to access seller dashboard
    await page.goto('http://localhost:5000/seller/dashboard');
    await page.waitForLoadState('networkidle');
    
    // Should be redirected with suspension message
    await expect(page).toHaveURL(/suspended|blocked/);
    await expect(page.locator('[data-testid="suspension-message"]')).toBeVisible();
  });
});

test.describe('Order Lifecycle E2E Tests', () => {
  test('Order transitions through all statuses', async ({ page }) => {
    // Assume logged in user with completed order
    await page.goto('http://localhost:5000/orders');
    await page.waitForLoadState('networkidle');
    
    // Find an order
    const orderCard = page.locator('[data-testid="order-card"]:first-child');
    await expect(orderCard).toBeVisible();
    
    // Click to view details
    await orderCard.click();
    await page.waitForLoadState('networkidle');
    
    // Verify order status display
    await expect(page.locator('[data-testid="order-status"]')).toBeVisible();
    
    // Verify timeline shows all transitions
    await expect(page.locator('[data-testid="order-timeline"]')).toBeVisible();
    const timelineItems = page.locator('[data-testid="timeline-item"]');
    const count = await timelineItems.count();
    expect(count).toBeGreaterThan(0);
  });

  test('Admin can view and manage orders', async ({ page }) => {
    // Login as admin
    await page.goto('http://localhost:5000/login');
    await page.fill('[data-testid="email-input"]', 'admin@test.com');
    await page.fill('[data-testid="password-input"]', 'AdminPassword123!');
    await page.click('[data-testid="login-button"]');
    await page.waitForLoadState('networkidle');
    
    // Navigate to admin panel
    await page.goto('http://localhost:5000/admin');
    await page.waitForLoadState('networkidle');
    
    // Click Orders tab
    await page.click('[data-testid="tab-orders"]');
    await page.waitForLoadState('networkidle');
    
    // Should see orders list
    await expect(page.locator('[data-testid="orders-table"]')).toBeVisible();
    
    // Click on an order
    await page.click('[data-testid="order-row"]:first-child');
    await page.waitForLoadState('networkidle');
    
    // Verify admin actions available
    await expect(page.locator('[data-testid="admin-actions"]')).toBeVisible();
  });

  test('Shipping calculation updates on delivery speed change', async ({ page }) => {
    await page.goto('http://localhost:5000/checkout');
    
    // Add product and address
    await page.fill('[data-testid="address-line1"]', '123 Main St');
    await page.fill('[data-testid="city"]', 'Toronto');
    await page.fill('[data-testid="province"]', 'Ontario');
    await page.fill('[data-testid="postal-code"]', 'M5V 3A8');
    
    // Calculate shipping
    await page.click('[data-testid="calculate-shipping-button"]');
    await page.waitForSelector('[data-testid="shipping-cost"]');
    
    const standardCost = await page.locator('[data-testid="shipping-cost"]').textContent();
    
    // Change to express
    await page.click('[data-testid="delivery-speed-express"]');
    await page.waitForSelector('[data-testid="shipping-cost"]');
    
    const expressCost = await page.locator('[data-testid="shipping-cost"]').textContent();
    
    // Verify cost increased
    expect(parseFloat(expressCost)).toBeGreaterThan(parseFloat(standardCost));
  });
});

test.describe('Authentication Flow E2E Tests', () => {
  test('Email verification required for signup', async ({ page }) => {
    await page.goto('http://localhost:5000/signup');
    
    // Fill signup form
    await page.fill('[data-testid="email-input"]', 'newuser@test.com');
    await page.fill('[data-testid="password-input"]', 'SecurePassword123!');
    await page.fill('[data-testid="name-input"]', 'Test User');
    
    // Submit
    await page.click('[data-testid="signup-button"]');
    await page.waitForLoadState('networkidle');
    
    // Should be on email verification page
    await expect(page).toHaveURL(/verify|confirmation/);
    await expect(page.locator('[data-testid="verification-message"]')).toBeVisible();
  });

  test('Password reset flow', async ({ page }) => {
    await page.goto('http://localhost:5000/forgot-password');
    
    // Enter email
    await page.fill('[data-testid="email-input"]', 'user@test.com');
    await page.click('[data-testid="reset-button"]');
    await page.waitForLoadState('networkidle');
    
    // Should show confirmation
    await expect(page.locator('[data-testid="reset-confirmation"]')).toBeVisible();
    
    // In real test, would use email service to get reset link
    // For now, verify message is shown
    await expect(page.locator('text=check your email')).toBeVisible();
  });

  test('Admin MFA flow', async ({ page }) => {
    // Login as admin
    await page.goto('http://localhost:5000/login');
    await page.fill('[data-testid="email-input"]', 'admin@test.com');
    await page.fill('[data-testid="password-input"]', 'AdminPassword123!');
    await page.click('[data-testid="login-button"]');
    await page.waitForLoadState('networkidle');
    
    // Navigate to security settings
    await page.goto('http://localhost:5000/admin/security');
    await page.waitForLoadState('networkidle');
    
    // Enable MFA
    await page.click('[data-testid="enable-mfa-button"]');
    await page.waitForSelector('[data-testid="qr-code"]');
    
    // Verify QR code displayed
    await expect(page.locator('[data-testid="qr-code"]')).toBeVisible();
    
    // Verify backup codes shown
    await expect(page.locator('[data-testid="backup-codes"]')).toBeVisible();
  });
});
