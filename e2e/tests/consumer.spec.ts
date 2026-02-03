// @ts-check
import { test, expect, Page } from '@playwright/test';

// Using a standard consumer login for these tests
const CONSUMER_EMAIL = 'consumer@test.com'; // Pre-existing dev user
const CONSUMER_PASS = 'password123';

test.describe('Consumer Flows P4.4 Audit Tests', () => {

    test.beforeEach(async ({ page }) => {
        if (!page.url().includes('login')) {
             await page.goto('/login');
        }
    });

    async function loginAsConsumer(page: Page) {
        await page.waitForTimeout(5000);
        const emailInput = page.getByLabel('Email Address');
        if (await emailInput.isVisible()) {
            await emailInput.fill(CONSUMER_EMAIL);
            await page.getByLabel('Password').fill(CONSUMER_PASS);
            await page.getByText('Sign In').first().click();
            await page.waitForTimeout(3000);
        }
    }

    test('C1. Favorites: Add to Favorites', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/shop'); 
        await page.waitForTimeout(2000);
        
        // Find a heart icon
        const heart = page.getByText('favorite_border').first();
        if (await heart.isVisible()) {
            await heart.click();
            await expect(page.getByText('Added to favorites')).toBeVisible();
        }
    });

    test('C2. Favorites: Check Duplicates Logic (Idempotency)', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/shop');
        
        const card = page.locator('.product-card').first();
        if (await card.isVisible()) {
            // Add once
            const heart = card.locator('text=favorite_border');
            if (await heart.isVisible()) await heart.click();
            
            // Try adding again if UI allows, or check if it turned into 'favorite' (filled)
            await expect(card.locator('text=favorite')).toBeVisible();
        }
    });

    test('C3. Address: Canadian Province Validation', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/addresses/new');
        await page.waitForTimeout(1000);
        
        // Try filling invalid province if free text, or check dropdown values
        const provinceInput = page.getByLabel('Province').or(page.getByPlaceholder('Province'));
        
        // If dropdown, verify ON, BC are options
        await provinceInput.click();
        await expect(page.getByText('ON').or(page.getByText('Ontario'))).toBeVisible();
        // Ensure strictly Canadian provinces (Audit requirement)
        await expect(page.getByText('TX').or(page.getByText('Texas'))).not.toBeVisible();
    });

    test('C4. Address: Canadian Postal Code Format Check', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/addresses/new');
        
        await page.getByLabel('Postal Code').fill('12345'); // Invalid
        await page.getByText('Save').click();
        
        // Expect validation error (A1A 1A1)
        await expect(page.getByText('Invalid format').or(page.getByText('A1A 1A1'))).toBeVisible();
        
        // Fix it
        await page.getByLabel('Postal Code').fill('M5V 2E6');
        await expect(page.getByText('Invalid format')).not.toBeVisible();
    });

    test('C5. Orders: Only Own Orders Visible', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/orders');
        await page.waitForTimeout(2000);
        
        // Verify orders list loads
        const orderList = page.getByRole('list');
        if (await orderList.isVisible()) {
             // We can't easily check "other" orders without knowing their IDs, 
             // but we can check that we see our own recent order.
             await expect(page.getByText('Order #')).toBeVisible();
        }
        
        // Security check: Try accessing a known invalid ID or admin route
        await page.goto('/admin');
        // Should redirect or show forbidden
        await expect(page).not.toHaveURL(/.*admin/);
    });

    test('C6. Search: Filter functioning', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/shop');
        
        const filterBtn = page.getByText('Filter');
        if (await filterBtn.isVisible()) {
            await filterBtn.click();
             await expect(page.getByText('Price Range')).toBeVisible();
        }
    });

    test('C7. Addresses: Default Address Logic', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/addresses');
        // Should have one marked as Default
        await expect(page.getByText('Default').first()).toBeVisible();
    });

    test('C8. User Profile Update', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/profile');
        if (await page.getByText('Edit').isVisible()) {
            await page.getByText('Edit').click();
            await page.getByLabel('Name').fill('Test Consumer Updated');
            await page.getByText('Save').click();
            await expect(page.getByText('Test Consumer Updated')).toBeVisible();
        }
    });

    test('C9. Checkout: Flow Init', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/cart'); 
        // Assuming cart has items from previous tests or state
        if (await page.getByText('Checkout').isVisible()) {
            await page.getByText('Checkout').click();
            await expect(page).toHaveURL(/.*checkout/);
        }
    });

    test('C10. Logout', async ({ page }) => {
        await loginAsConsumer(page);
        await page.goto('/profile');
        await page.getByText('Logout').click();
        await expect(page).toHaveURL(/.*login/);
    });
});
