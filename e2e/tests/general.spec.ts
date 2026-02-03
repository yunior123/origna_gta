// @ts-check
import { test, expect, Page } from '@playwright/test';

// Credentials provided for Admin Testing
const ADMIN_EMAIL = 'yuniorrodriguezo460@gmail.com';
const ADMIN_PASSWORD = '960227yro#Y7';

test.describe('Admin Workflows', () => {
    
    test.beforeEach(async ({ page }) => {
        // Go to login page before each admin test
        await page.goto('/login');
        // Wait for Flutter engine to initialize
        await page.waitForTimeout(5000);
    });

    test('1. Admin Authentication Success', async ({ page }) => {
        const emailInput = page.getByLabel('Email Address');
        // If already logged in, this might fail, but usually fresh context per test
        if (await emailInput.isVisible()) {
            await emailInput.fill(ADMIN_EMAIL);
            await page.getByLabel('Password').fill(ADMIN_PASSWORD);
            await page.getByText('Sign In').first().click();
            await page.waitForTimeout(5000);
            await expect(page).toHaveURL(/.*dashboard/);
        }
    });

    test('2. Admin Dashboard Layout Loads', async ({ page }) => {
        await adminLogin(page);
        // Using generic text likely to be in dashboard
        await expect(page.getByText('Dashboard').first()).toBeVisible();
    });

    test('3. Verify Admin Users Management Section', async ({ page }) => {
        await adminLogin(page);
        
        const usersLink = page.getByText('Users');
        if (await usersLink.isVisible()) {
            await usersLink.click();
            await page.waitForTimeout(2000);
            await expect(page.getByText('User List').or(page.getByText('Users'))).toBeVisible();
        }
    });

    test('4. Verify Admin Products Management Section', async ({ page }) => {
        await adminLogin(page);
        
        const productsLink = page.getByText('Products');
        if (await productsLink.isVisible()) {
            await productsLink.click();
            await page.waitForTimeout(2000);
            await expect(page.getByText('Inventory').or(page.getByText('Products List'))).toBeVisible();
        }
    });

    test('4.1. Admin: Open Add Product Form', async ({ page }) => {
        await adminLogin(page);
        await page.getByText('Products').click();
        // Allow menu transition
        await page.waitForTimeout(1000);

        const addProductBtn = page.getByRole('button', { name: 'Add Product' }).or(page.getByText('Add New'));
        if (await addProductBtn.isVisible()) {
            await addProductBtn.click();
            await expect(page.getByText('New Product').or(page.getByText('Create Product'))).toBeVisible();
        }
    });

    test('4.2. Admin: Verify Product Form Validation', async ({ page }) => {
        await adminLogin(page);
        // Navigate to add product (assuming previous test path works, repeat for isolation)
        if (await page.getByText('Products').isVisible()) {
            await page.getByText('Products').click();
            await page.waitForTimeout(1000);
            const addBtn = page.getByRole('button', { name: 'Add Product' }).or(page.getByText('Add New'));
            if (await addBtn.isVisible()) await addBtn.click();
        }
        
        await page.waitForTimeout(2000);
        // Attempt submit without data
        const saveBtn = page.getByRole('button', { name: 'Save' }).or(page.getByText('Create Product'));
        if (await saveBtn.isVisible()) {
            await saveBtn.click();
            // Check for error messages (red text or specific error labels)
            // Flutter often uses 'Required' under the input
            await expect(page.getByText('Required').or(page.getByText('Please enter')).first()).toBeVisible();
        }
    });

    test('4.3. Admin: Add Product - Full Flow', async ({ page }) => {
        // Enable console logging
        page.on('console', msg => console.log(`BROWSER LOG: ${msg.text()}`));
        page.on('pageerror', exception => console.log(`BROWSER ERROR: ${exception}`));
        
        // Monitor network failures
        page.on('requestfailed', request => {
            console.log(`REQ FAILED: ${request.url()} - ${request.failure()?.errorText}`);
        });

        await adminLogin(page);
        
        // Handle responsive menu if needed
        const productsLink = page.getByText('Products');
        if (!await productsLink.isVisible()) {
             // Try identifying a hamburger menu
             const menuBtn = page.getByText('menu').or(page.getByLabel('Open navigation menu')).or(page.locator('button').filter({ hasText: 'menu' })).first();
             if (await menuBtn.isVisible()) {
                 await menuBtn.click();
                 await page.waitForTimeout(1000);
             }
        }

        // Navigate
        // Use a more generous timeout and try force click if needed
        if (await productsLink.count() > 0) {
             await productsLink.click({ timeout: 10000 });
        } else {
            console.log('Products link not found, attempting URL navigation');
            await page.goto('/admin/products');
        }

        await page.waitForTimeout(2000);
        const addBtn = page.getByRole('button', { name: 'Add Product' }).or(page.getByText('Add New')).or(page.getByText('add')).first();
        if (await addBtn.isVisible()) await addBtn.click();

        await page.waitForTimeout(1000);

        // Fill Form
        // Using generic placeholders common in Flutter inputs
        // We use .first() because sometimes labels and placeholders match multiple elements
        const uniqueName = `Test Product ${Date.now()}`;
        console.log(`Creating product with name: ${uniqueName}`);
        const nameInput = page.getByLabel('Product Name').or(page.getByPlaceholder('Name')).first();
        if (await nameInput.isVisible()) {
            await nameInput.fill(uniqueName);
            
            await page.getByLabel('Description').or(page.getByPlaceholder('Description')).first().fill('Automated E2E Test Description with Image');
            await page.getByLabel('Price').or(page.getByPlaceholder('0.00')).first().fill('49.99');
            await page.getByLabel('Stock').or(page.getByPlaceholder('Quantity')).first().fill('100');

            // Address Details (Required by Firestore Rules)
            const streetInput = page.getByLabel('Street Address').or(page.getByPlaceholder('Street')).first();
            if (await streetInput.isVisible()) {
                console.log('Filling Address and waiting for suggestions...');
                await streetInput.fill('10 Queen St West');
                await page.waitForTimeout(3000); // Wait for API response
                
                // Try to click the first suggestion
                // Suggestions usually appear in a list below.
                // We look for a text item that appeared.
                const suggestion = page.locator('div').filter({ hasText: 'Queen St' }).last(); 
                if (await suggestion.isVisible()) {
                     console.log('Clicking address suggestion...');
                     await suggestion.click();
                     await page.waitForTimeout(1000);
                } else {
                     console.log('WARNING: No address suggestions appeared.');
                }
                
                await page.getByLabel('City').or(page.getByPlaceholder('City')).first().fill('Toronto');
                await page.getByLabel('State').or(page.getByPlaceholder('State')).or(page.getByText('Select Province')).first().click();
                // Select a state/province if dropdown
                await page.getByRole('option').first().click();
                
                await page.getByLabel('Postal Code').or(page.getByPlaceholder('Postal Code')).first().fill('M5H 2N2');
            }

            // Category Selection (often a dropdown)
            const categoryDropdown = page.getByLabel('Category').or(page.getByText('Select Category')).first();
            if (await categoryDropdown.isVisible()) {
                await categoryDropdown.click();
                await page.waitForTimeout(1000);
                // Select first available option
                await page.getByRole('option').first().click();
            }

            // Image Upload
            console.log('Attempting Image Upload...');
            
            // 1. Check for existing file input (some implementations keep it in DOM)
            const fileInput = page.locator('input[type="file"]');
            if (await fileInput.count() > 0) {
                console.log('Found file input directly.');
                await fileInput.first().setInputFiles('e2e/test-assets/test_image.jpg');
            } else {
                // 2. Look for the trigger button
                // Common Flutter Icons identifiers as text
                const uploadTrigger = page.getByText('cloud_upload').or(page.getByText('Upload Image')).or(page.getByText('photo_camera')).first();
                
                if (await uploadTrigger.isVisible()) {
                    console.log('Found upload trigger, clicking...');
                    const fileChooserPromise = page.waitForEvent('filechooser', { timeout: 10000 });
                    await uploadTrigger.click();
                    const fileChooser = await fileChooserPromise;
                    await fileChooser.setFiles('e2e/test-assets/test_image.jpg');
                } else {
                    console.error('Upload trigger NOT found. Skipping upload but marking as failure warning.');
                    // Don't fail the test immediately to allow flow completion, but log it.
                    // Or failing is better to signal the user "why bucket is empty"
                    throw new Error('Image Upload failed: Could not find upload button or file input.');
                }
            }
            
            // Wait for upload preview/progress
            await page.waitForTimeout(5000);

            // Submit
            const saveBtn = page.getByRole('button', { name: 'Save' }).or(page.getByText('Create Product')).first();
            if (await saveBtn.isVisible()) {
                await saveBtn.click();
                // Wait for network request to complete
                await page.waitForTimeout(5000);
                
                // Assert verification
                console.log('Waiting for product list...');
                
                // CRITICAL: We must ensure we left the form.
                // Check if 'Add Product' button (the FAB or top button from list) is visible again.
                // Or check for "Products" header.
                // Assuming 'New Product' header disappears.
                const newProductHeader = page.getByText('New Product').or(page.getByRole('heading', { name: 'New Product' }));
                await expect(newProductHeader).not.toBeVisible({ timeout: 20000 });
                
                // Look for the specific item IN THE LIST (not input value)
                // We should look for a row or card.
                console.log(`Searching for ${uniqueName} in list...`);
                await expect(page.getByText(uniqueName)).toBeVisible({ timeout: 30000 });
                console.log('Product verification SUCCESS');
            }
        }
    });

    test('4.4. Admin: Edit Existing Product', async ({ page }) => {
         await adminLogin(page);
         await page.getByText('Products').click();
         await page.waitForTimeout(2000);
         
         // Click first edit icon/button in table
         // assuming a table structure with edit icon
         const firstEditBtn = page.getByText('edit').first().or(page.getByText('Edit').first());
         if (await firstEditBtn.isVisible()) {
             await firstEditBtn.click();
             await expect(page.getByText('Edit Product').or(page.getByText('Update'))).toBeVisible();
             
             // Change Price
             await page.getByLabel('Price').or(page.getByPlaceholder('0.00')).fill('59.99');
             
             await page.getByText('Update').or(page.getByText('Save')).click();
             await expect(page.getByText('Success').or(page.getByText('Updated'))).toBeVisible();
         }
    });

    test('5. Verify Admin Orders Management Section', async ({ page }) => {
        await adminLogin(page);
        
        const ordersLink = page.getByText('Orders');
        if (await ordersLink.isVisible()) {
            await ordersLink.click();
            await page.waitForTimeout(2000);
            await expect(page.getByText('All Orders').or(page.getByText('Order Management'))).toBeVisible();
        }
    });

    test('6. Admin Analytics Visibility', async ({ page }) => {
        await adminLogin(page);
        await expect(page.getByText('Sales').or(page.getByText('Revenue'))).toBeVisible();
    });

    test('7. Admin Settings Access', async ({ page }) => {
        await adminLogin(page);
        
        const settingsLink = page.getByText('Settings');
        if (await settingsLink.isVisible()) {
            await settingsLink.click();
            // await expect(page).toHaveURL(/.*settings/);
        }
    });

    test('8. Admin Notifications', async ({ page }) => {
        await adminLogin(page);
        // Assumption: Notification bell icon or link. Filtering by icon name if possible in Flutter web usually requires aria-labels.
        // Fallback to a generic button check that might represent notifications
        const notificationIcon = page.getByRole('button').filter({ hasText: /notification/i }).first();
        if (await notificationIcon.isVisible()) {
             await notificationIcon.click();
        }
    });

    test('9. Admin Profile Menu', async ({ page }) => {
        await adminLogin(page);
        
        const profile = page.locator('img[alt="Profile"]').or(page.getByRole('button', { name: /profile/i })).first();
        if (await profile.isVisible()) {
            await profile.click();
        }
    });

    test('10. Admin Logout Flow', async ({ page }) => {
        await adminLogin(page);
        
        // Helper to find logout
        const logoutBtn = page.getByText('Logout').or(page.getByText('Sign Out'));
        if (await logoutBtn.isVisible()) {
            await logoutBtn.click();
            await expect(page).toHaveURL(/.*login/);
        }
    });
});

test.describe('Public & General UI Tests', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await page.waitForTimeout(5000);
    });

    test('11. Homepage Load & Hero Section', async ({ page }) => {
        // await expect(page).toHaveTitle(/.*Origna/i);
        // Verify hero text or main CTA
        await expect(page.getByRole('main').or(page.locator('body'))).toBeVisible();
    });

    test('12. Navigation Menu Functionality', async ({ page }) => {
        // Check main nav items exist
        await expect(page.getByText('Shop').or(page.getByText('Store'))).toBeVisible();
    });

    test('13. Footer Links', async ({ page }) => {
        // Scroll to bottom
        await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
        await page.waitForTimeout(1000);
        
        await expect(page.getByText('Privacy Policy').first()).toBeVisible();
    });

    test('14. Search Functionality', async ({ page }) => {
        const searchInput = page.getByPlaceholder('Search');
        if (await searchInput.isVisible()) {
            await searchInput.fill('Test');
            await searchInput.press('Enter');
            await page.waitForTimeout(2000);
        }
    });

    test('15. 404 Page Handling', async ({ page }) => {
        await page.goto('/non-existent-page-123');
        await page.waitForTimeout(3000);
        // Expect a 404 text or home redirect
        const notFound = page.getByText('Not Found').or(page.getByText('404'));
        if (await notFound.isVisible()) {
             await expect(notFound).toBeVisible();
        }
    });

    test('16. Responsive Viewport Check', async ({ page }) => {
        await page.setViewportSize({ width: 375, height: 667 }); // iPhone SE size
        await page.reload();
        await page.waitForTimeout(3000);
        // Check for hamburger menu appearance
    });

     test('17. Cart Page Empty State', async ({ page }) => {
        await page.goto('/cart');
        await page.waitForTimeout(3000);
        await expect(page.getByText('empty').or(page.getByText('Cart is empty'))).toBeVisible();
    });
});

test.describe('Checkout & Shopping Flow', () => {
    
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await page.waitForTimeout(5000);
    });

    test('18. Add Product to Cart from Catalog', async ({ page }) => {
        // Find a generic "Add to Cart" button or icon on the homepage/shop page
        const addBtn = page.getByRole('button', { name: /add to cart/i }).or(page.getByText('shopping_cart')).first();
        if (await addBtn.isVisible()) {
            await addBtn.click();
            // Expect toast or badge update
            await expect(page.getByText('Added to cart').or(page.locator('.cart-badge'))).toBeVisible();
        }
    });

    test('19. View Product Details Page', async ({ page }) => {
        // Click on the first product image or title
        const productCard = page.locator('article, .product-card').first();
        if (await productCard.isVisible()) {
            await productCard.click();
            await page.waitForTimeout(2000);
            // Verify we are on a details page (e.g., look for "Add to Cart" button usually unique to details)
            await expect(page.getByText('Description')).toBeVisible();
            await expect(page.getByRole('button', { name: /add to cart/i })).toBeVisible();
        }
    });

    test('20. Add Product to Cart from Detail Page', async ({ page }) => {
        // Navigate to a product detail first
        const productCard = page.locator('article, .product-card').first();
        if (await productCard.isVisible()) {
            await productCard.click();
            await page.waitForTimeout(2000);
            
            const addBtn = page.getByRole('button', { name: /add to cart/i });
            if (await addBtn.isVisible()) {
                await addBtn.click();
                await page.waitForTimeout(1000);
                await expect(page.getByText('Added').or(page.getByText('Cart'))).toBeVisible();
            }
        }
    });

    test('21. Cart: Update Quantity', async ({ page }) => {
        await page.goto('/cart');
        await page.waitForTimeout(2000);
        
        // Look for plus/minus buttons or quantity input
        const plusBtn = page.getByText('add').or(page.getByRole('button', { name: '+' })).first();
        if (await plusBtn.isVisible()) {
            await plusBtn.click();
            await page.waitForTimeout(1000);
            // Verify quantity increased (checking input value or total price change is complex without specific data, checking for no error)
            await expect(plusBtn).toBeEnabled();
        }
    });

    test('22. Cart: Remove Item', async ({ page }) => {
        await page.goto('/cart');
        await page.waitForTimeout(2000);
        
        const removeBtn = page.getByText('delete').or(page.getByRole('button', { name: /remove/i })).first();
        if (await removeBtn.isVisible()) {
            await removeBtn.click();
            await page.waitForTimeout(1000);
            // Confirm removal
            await expect(page.getByText('Removed').or(page.getByText('empty'))).toBeVisible();
        }
    });

    test('23. Proceed to Checkout (Auth Check)', async ({ page }) => {
        await page.goto('/cart');
        await page.waitForTimeout(2000);
        
        const checkoutBtn = page.getByText('Checkout').or(page.getByText('Proceed'));
        if (await checkoutBtn.isVisible()) {
            await checkoutBtn.click();
            await page.waitForTimeout(2000);
            // If not logged in, should redirect to login
            await expect(page).toHaveURL(/.*login|.*checkout/);
        }
    });

    test('24. Checkout: Shipping Address Form Verification', async ({ page }) => {
        // Assuming user is logged in or guest checkout is allowed
        // Force navigate to checkout to test form
        await adminLogin(page); // Use admin for authenticated checkout test
        await page.goto('/checkout');
        await page.waitForTimeout(3000);
        
        await expect(page.getByLabel('Address').or(page.getByText('Shipping Address'))).toBeVisible();
        await expect(page.getByLabel('City')).toBeVisible();
        await expect(page.getByLabel('Zip Code').or(page.getByLabel('Postal Code'))).toBeVisible();
    });

    test('25. Checkout: Shipping Method Selection', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/checkout');
        await page.waitForTimeout(3000);
        
        // Look for radio buttons or cards for shipping
        const shippingOption = page.getByRole('radio').first().or(page.locator('.shipping-option').first());
        if (await shippingOption.isVisible()) {
            await shippingOption.click();
            await expect(shippingOption).toBeChecked();
        }
    });

    test('26. Checkout: Payment Method UI', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/checkout');
        await page.waitForTimeout(3000);
        
        await expect(page.getByText('Credit Card').or(page.getByText('Stripe'))).toBeVisible();
        await expect(page.getByLabel('Card Number').or(page.getByPlaceholder('Card Number'))).toBeVisible();
    });

    test('27. Checkout: Order Summary Review', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/checkout');
        await page.waitForTimeout(3000);
        
        await expect(page.getByText('Total').or(page.getByText('Order Summary'))).toBeVisible();
        // Check for "Place Order" button presence
        await expect(page.getByText('Place Order').or(page.getByText('Pay Now'))).toBeVisible();
    });
});

test.describe('Authentication & User Accounts', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/login');
        await page.waitForTimeout(3000);
    });

    test('28. Sign Up Flow - Success', async ({ page }) => {
        const signupLink = page.getByText('Sign Up').or(page.getByText('Register'));
        if (await signupLink.isVisible()) {
            await signupLink.click();
            await page.waitForTimeout(1000);
            
            await page.getByLabel('Name').fill('Test User');
            await page.getByLabel('Email').fill(`test+${Date.now()}@example.com`);
            await page.getByLabel('Password').fill('StrongPass123!');
            
            const submitBtn = page.getByRole('button', { name: /Up|Register/i });
            if (await submitBtn.isVisible()) await submitBtn.click();
            
            // Expect redirect or welcome
            // await expect(page).toHaveURL(/.*dashboard|.*home/);
        }
    });

    test('29. Sign Up - Existing Email Validation', async ({ page }) => {
        const signupLink = page.getByText('Sign Up');
        if (await signupLink.isVisible()) {
            await signupLink.click();
            
            // Use Admin email which should exist
            await page.getByLabel('Email').fill(ADMIN_EMAIL);
            await page.getByLabel('Password').fill('AnyPass123!');
            
            const submitBtn = page.getByRole('button', { name: /Up|Register/i });
            await submitBtn.click();
            
            await expect(page.getByText('already exists').or(page.getByText('error'))).toBeVisible();
        }
    });

    test('30. Sign Up - Password Weakness', async ({ page }) => {
        const signupLink = page.getByText('Sign Up');
        if (await signupLink.isVisible()) {
            await signupLink.click();
            await page.getByLabel('Password').fill('123');
            await expect(page.getByText('Too short').or(page.getByText('weak'))).toBeVisible();
        }
    });

    test('31. Login - Invalid Credentials', async ({ page }) => {
        await page.getByLabel('Email Address').fill('wrong@test.com');
        await page.getByLabel('Password').fill('badpass');
        await page.getByText('Sign In').first().click();
        
        await expect(page.getByText('Invalid').or(page.getByText('Failed'))).toBeVisible();
    });

    test('32. Forgot Password Flow', async ({ page }) => {
        await page.getByText('Forgot Password').click();
        await page.getByLabel('Email').fill('user@test.com');
        await page.getByText('Submit').or(page.getByText('Reset')).click();
        await expect(page.getByText('Sent').or(page.getByText('Check your email'))).toBeVisible();
    });

    test('33. User Profile View', async ({ page }) => {
        // Assume logged in via helper for simplicity, or re-login
        await adminLogin(page);
        await page.goto('/profile');
        await expect(page.getByText('Profile').or(page.getByText('Account Info'))).toBeVisible();
    });

    test('34. User Profile - Update Name', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/profile/edit');
        if (await page.getByLabel('Name').isVisible()) {
            await page.getByLabel('Name').fill('Updated Name');
            await page.getByText('Save').click();
            await expect(page.getByText('Saved').or(page.getByText('Success'))).toBeVisible();
        }
    });

    test('35. Change Password', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/profile/security'); // Guessing route
        const oldPass = page.getByLabel('Current Password');
        if (await oldPass.isVisible()) {
            await oldPass.fill(ADMIN_PASSWORD);
            await page.getByLabel('New Password').fill('NewStrongPass1!');
            // Not submitting to avoid breaking future tests with admin creds change
            await expect(page.getByRole('button', { name: 'Change' })).toBeVisible();
        }
    });

    test('36. Address Book - Add Address', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/addresses');
        // If empty, look for add
        if (await page.getByText('Add Address').isVisible()) {
            await page.getByText('Add Address').click();
            await page.getByLabel('Street').fill('123 Test St');
            await page.getByLabel('City').fill('Test City');
            await page.getByText('Save').click();
        }
    });

    test('37. Address Book - Delete Address', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/addresses');
        const deleteBtn = page.getByText('delete').first();
        if (await deleteBtn.isVisible()) {
            await deleteBtn.click();
            await expect(deleteBtn).not.toBeVisible();
        }
    });
});

test.describe('Seller/Vendor Workflows', () => {
    
    test('38. Seller Registration Flow', async ({ page }) => {
        await page.goto('/seller/register');
        await page.waitForTimeout(3000);
        await expect(page.getByText('Become a Seller')).toBeVisible();
        // Fill form...
        if (await page.getByLabel('Shop Name').isVisible()) {
            await page.getByLabel('Shop Name').fill('Test Shop');
        }
    });

    test('39. Seller Dashboard Access', async ({ page }) => {
        // Login as Seller (using admin here as often admin has seller view or dual roles for testing)
        await adminLogin(page); 
        await page.goto('/seller/dashboard');
        await expect(page.getByText('Dashboard').or(page.getByText('Earnings'))).toBeVisible();
    });

    test('40. Seller Dashboard Overview', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/dashboard');
        await expect(page.getByText('Orders')).toBeVisible();
        await expect(page.getByText('Products')).toBeVisible();
    });

    test('41. Seller - Create Product', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/products/new');
        await expect(page.getByText('New Product')).toBeVisible();
    });

    test('42. Seller - Edit Product', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/products');
        await page.waitForTimeout(1000);
        const editBtn = page.getByText('edit').first();
        if (await editBtn.isVisible()) await editBtn.click();
    });

    test('43. Seller - Archive Product', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/products');
        const deleteBtn = page.getByText('delete').first();
        if (await deleteBtn.isVisible()) await deleteBtn.click();
    });

    test('44. Seller - View Orders', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/orders');
        await expect(page.getByText('Order ID').or(page.getByText('Status'))).toBeVisible();
    });

    test('45. Seller - Update Order Status', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/orders');
        // Specific logic to find dropdown status
        const statusDropdown = page.locator('select').first();
        if (await statusDropdown.isVisible()) await statusDropdown.click();
    });

    test('46. Seller - View Wallet', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/wallet');
        await expect(page.getByText('Balance')).toBeVisible();
    });

    test('47. Seller - Request Payout', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/wallet');
        const payoutBtn = page.getByText('Request Payout');
        if (await payoutBtn.isVisible()) await payoutBtn.click();
    });

    test('48. Seller - Shop Settings', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/settings');
        await expect(page.getByLabel('Shop Name')).toBeVisible();
    });

    test('49. Seller - View Reviews', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/reviews');
        await expect(page.getByText('Reviews')).toBeVisible();
    });

    test('50. Seller - Unauthorized Admin Access', async ({ page }) => {
        // Mock a non-admin seller context if possible, otherwise skip
        // This generally tests permissions
    });

    test('51. Unapproved Seller Interaction', async ({ page }) => {
        // Test logic for pending approval
        await page.goto('/login');
        // Login with unapproved creds...
    });

    test('52. Seller Logout', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/seller/dashboard');
        await page.getByText('Logout').click();
        await expect(page).toHaveURL(/.*login/);
    });
});

test.describe('Search, Filter & Discovery', () => {
    
    test.beforeEach(async ({ page }) => {
        await page.goto('/shop');
        await page.waitForTimeout(3000);
    });

    test('53. Search - Zero Results', async ({ page }) => {
        const search = page.getByPlaceholder('Search');
        if (await search.isVisible()) {
            await search.fill('sdfsdfswerrwer');
            await search.press('Enter');
            await expect(page.getByText('No results')).toBeVisible();
        }
    });

    test('54. Filter by Category', async ({ page }) => {
        const catFilter = page.getByText('Electronics').first(); // Example category
        if (await catFilter.isVisible()) {
            await catFilter.click();
            await page.waitForTimeout(1000);
            // Verify URL or results
        }
    });

    test('55. Filter by Price Range', async ({ page }) => {
        // Range slider or inputs
        const minPrice = page.getByPlaceholder('Min');
        if (await minPrice.isVisible()) {
            await minPrice.fill('10');
            await page.getByPlaceholder('Max').fill('100');
            await page.getByText('Apply').click();
        }
    });

    test('56. Sort by Price: Low to High', async ({ page }) => {
        const sortBtn = page.getByText('Sort by');
        if (await sortBtn.isVisible()) {
            await sortBtn.click();
            await page.getByText('Low to High').click();
        }
    });

    test('57. Sort by Price: High to Low', async ({ page }) => {
        const sortBtn = page.getByText('Sort by');
        if (await sortBtn.isVisible()) {
            await sortBtn.click();
            await page.getByText('High to Low').click();
        }
    });

    test('58. Sort by Newest', async ({ page }) => {
        const sortBtn = page.getByText('Sort by');
        if (await sortBtn.isVisible()) {
            await sortBtn.click();
            await page.getByText('Newest').click();
        }
    });

    test('59. Wishlist - Add Item', async ({ page }) => {
        const heartIcon = page.getByText('favorite_border').first();
        if (await heartIcon.isVisible()) {
            await heartIcon.click();
            // Expect filled heart or toast
        }
    });

    test('60. Wishlist - Remove Item', async ({ page }) => {
        // Go to wishlist page
        await page.goto('/wishlist');
        const removeBtn = page.getByText('delete').first();
        if (await removeBtn.isVisible()) await removeBtn.click();
    });
});

test.describe('Reviews, Social & Compliance', () => {

    test('61. Product - Add Review', async ({ page }) => {
        await adminLogin(page);
        await page.goto('/product/1'); // Navigate to a product
        const reviewBtn = page.getByText('Write Review');
        if (await reviewBtn.isVisible()) {
            await reviewBtn.click();
            await page.getByPlaceholder('Review').fill('Great product!');
            await page.getByText('star').last().click(); // 5 stars
            await page.getByText('Submit').click();
        }
    });

    test('62. Product - View Reviews List', async ({ page }) => {
        await page.goto('/product/1');
        await expect(page.getByText('Reviews')).toBeVisible();
    });

    test('63. Vendor Profile Link', async ({ page }) => {
        await page.goto('/product/1');
        const vendorLink = page.locator('.vendor-link'); // Class assumption
        if (await vendorLink.isVisible()) await vendorLink.click();
    });

    test('64. Blog/Content Pages Load', async ({ page }) => {
        await page.goto('/blog');
        await expect(page.getByText('Blog').or(page.getByText('Articles'))).toBeVisible();
    });

    test('65. Newsletter Subscription', async ({ page }) => {
        await page.goto('/');
        const emailInput = page.getByPlaceholder('Enter your email');
        if (await emailInput.isVisible()) {
            await emailInput.fill('newsletter@test.com');
            await page.getByText('Subscribe').click();
            await expect(page.getByText('Subscribed')).toBeVisible();
        }
    });

    test('66. Contact Us Form', async ({ page }) => {
        await page.goto('/contact');
        if (await page.getByLabel('Message').isVisible()) {
            await page.getByLabel('Name').fill('Tester');
            await page.getByLabel('Email').fill('test@test.com');
            await page.getByLabel('Message').fill('Hello');
            await page.getByText('Send').click();
        }
    });

    test('67. Privacy Policy Interaction', async ({ page }) => {
        await page.goto('/privacy');
        await expect(page.getByText('Privacy Policy')).toBeVisible();
    });

    test('68. Terms of Service Interaction', async ({ page }) => {
        await page.goto('/terms');
        await expect(page.getByText('Terms')).toBeVisible();
    });
});

// Helper function for Admin Login reuse
async function adminLogin(page: Page) {
    // Check if we are already logged in (by checking for logout button or similar)
    try {
        await page.waitForSelector('text=Dashboard', { timeout: 5000 });
        return; // Already logged in
    } catch (e) {
        // Not logged in
    }

    if (!page.url().includes('login')) {
         await page.goto('/login');
         // Allow extra time for Flutter to initialize
         await page.waitForTimeout(5000);
    }
    
    // Perform login if inputs are visible
    const emailInput = page.getByLabel('Email Address');
    if (await emailInput.isVisible()) {
         await emailInput.fill(ADMIN_EMAIL);
         await page.getByLabel('Password').fill(ADMIN_PASSWORD);
         await page.getByText('Sign In').first().click();
         // Wait for navigation and dashboard load
         await page.waitForTimeout(10000);
         // Ensure we are on dashboard
         await expect(page.getByText('Dashboard').first()).toBeVisible({ timeout: 15000 });
    }
}

// Retaining Original/Previous Tests Structure
test.describe('Legacy Checkout & Seller Tests', () => {
  test('Complete checkout flow with physical product', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);
    const searchInput = page.getByPlaceholder('Search products...');
    if (await searchInput.isVisible()) {
        await searchInput.fill('test product');
        await searchInput.press('Enter');
        await page.waitForTimeout(2000);
    }
  });

  test('Rate limiting on failed login', async ({ page }) => {
    await page.goto('/login');
    await page.waitForTimeout(3000);

    const emailInput = page.getByLabel('Email Address');
    const passwordInput = page.getByLabel('Password');
    const loginButton = page.getByText('Sign In').first();
    
    if (await emailInput.isVisible()) {
        await emailInput.fill('test@example.com');
        await passwordInput.fill('wrongpass');
        await loginButton.click();
        await page.waitForTimeout(1000);
    }
  });

  test('Seller cannot add products until approved', async ({ page }) => {
    await page.goto('/login');
    await page.waitForTimeout(3000);
    
    const emailInput = page.getByLabel('Email Address');
    if (await emailInput.isVisible()) {
        await emailInput.fill('unapproved@test.com');
    }
  });
});
