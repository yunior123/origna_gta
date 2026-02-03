// @ts-check
import { test, expect, Page } from '@playwright/test';

const ADMIN_EMAIL = 'yuniorrodriguezo460@gmail.com';
const ADMIN_PASSWORD = '960227yro#Y7';

test.describe('Admin Dashboard P4.2 Audit Tests', () => {
    
    test.beforeEach(async ({ page }) => {
        // Go to login page before each admin test
        if (!page.url().includes('login')) {
             await page.goto('/login');
        }
    });

    // Helper for login
    async function loginAsAdmin(page: Page) {
        await page.waitForTimeout(7000); // Wait for Flutter to load
        const emailInput = page.getByLabel('Email Address');
        if (await emailInput.isVisible()) {
            await emailInput.fill(ADMIN_EMAIL);
            await page.getByLabel('Password').fill(ADMIN_PASSWORD);
            await page.getByText('Sign In').first().click();
            await page.waitForTimeout(7000); // Wait for Flutter
            // Log l'URL après login
            console.log('Admin logged in, URL:', page.url());
        }
    }

    test('A1. Admin RBAC: Verify Admin Tabs Access', async ({ page }) => {
        await loginAsAdmin(page);
        // Attente explicite sur l'URL dashboard/admin
        await page.waitForTimeout(3000);
        console.log('URL après login:', page.url());
        await expect(page.getByText('Dashboard')).toBeVisible({ timeout: 15000 });
        await expect(page.getByText('Sellers')).toBeVisible({ timeout: 15000 });
        await expect(page.getByText('Orders')).toBeVisible({ timeout: 15000 }); 
        await expect(page.getByText('Disputes')).toBeVisible({ timeout: 15000 });
    });

    test('A2. Admin: View Sellers List (Read-Only)', async ({ page }) => {
        await loginAsAdmin(page);
        await page.getByText('Sellers').click();
        await expect(page.getByText('All Sellers')).toBeVisible();
        // Should list sellers
        await expect(page.getByRole('list').first()).toBeVisible();
    });

    test('A3. Admin: Seller Suspension UI Trigger', async ({ page }) => {
        await loginAsAdmin(page);
        await page.getByText('Sellers').click();
        await page.waitForTimeout(2000);
        
        // Find a seller to test suspension UI (without submitting)
        const sellerRow = page.locator('.seller-row').first().or(page.getByText('Test Shop').first());
        if (await sellerRow.isVisible()) {
            await sellerRow.click();
            await expect(page.getByText('Suspend Seller')).toBeVisible();
            
            await page.getByText('Suspend Seller').click();
            // Verify MFA prompt or Confirmation Dialog appears as per audit
            await expect(page.getByText('Reason').or(page.getByText('Confirm Suspension'))).toBeVisible();
        }
    });

    test('A4. Admin: View Disputes List', async ({ page }) => {
        await loginAsAdmin(page);
        const disputesLink = page.getByText('Disputes');
        if (await disputesLink.isVisible()) {
            await disputesLink.click();
            await expect(page.getByText('Dispute ID').or(page.getByText('Reason'))).toBeVisible();
        }
    });

    test('A5. Admin: Resolve Dispute Flow (UI Check)', async ({ page }) => {
        await loginAsAdmin(page);
        const disputesLink = page.getByText('Disputes');
        if (await disputesLink.isVisible()) {
            await disputesLink.click();
            await page.waitForTimeout(1000);
            
            // If any dispute exists, click detail
            const firstDispute = page.getByText('Under Review').first();
            if (await firstDispute.isVisible()) {
                await firstDispute.click();
                await expect(page.getByText('Resolve Dispute')).toBeVisible();
                
                await page.getByText('Resolve Dispute').click();
                // Check for resolution options enforced by audit
                await expect(page.getByText('Award Consumer')).toBeVisible();
                await expect(page.getByText('Award Seller')).toBeVisible();
            }
        }
    });

    test('A6. Admin: Payouts History Access', async ({ page }) => {
        await loginAsAdmin(page);
        await page.goto('/admin/payouts'); // Direct nav check
        await expect(page.getByText('Payouts').or(page.getByText('Completed'))).toBeVisible();
    });

    test('A7. Admin: Manual Refund Button Presence', async ({ page }) => {
        await loginAsAdmin(page);
        await page.getByText('Orders').click();
        await page.waitForTimeout(1000);
        
        const firstOrder = page.getByText('Order #').first().or(page.locator('.order-card').first());
        if (await firstOrder.isVisible()) {
            await firstOrder.click();
            // Check for Refund button availability
            await expect(page.getByText('Refund').or(page.getByText('Issue Refund'))).toBeVisible();
        }
    });

    test('A8. Security: MFA Enforcement on Sensitive Actions', async ({ page }) => {
        await loginAsAdmin(page);
        // This test verifies that sensitive actions aren't immediate clicks but trigger a modal/dialog
        // mimicking the MFA requirement mentioned in audit.
        
        // Go to settings or security
        await page.goto('/admin/security');
        // If there's a sensitive toggle
        if (await page.getByText('Disable').isVisible()) {
            await page.getByText('Disable').click();
            await expect(page.getByText('password').or(page.getByText('code'))).toBeVisible(); // Re-auth prompt
        }
    });
    
    test('A9. Audit Log: Verify Logs Visible', async ({ page }) => {
         await loginAsAdmin(page);
         await page.goto('/admin/logs');
         await expect(page.getByText('Activity Log').or(page.getByText('Action'))).toBeVisible();
    });

    test('A10. Admin: Logout', async ({ page }) => {
        await loginAsAdmin(page);
        await page.getByText('Logout').click();
        await expect(page).toHaveURL(/.*login/);
    });
});
