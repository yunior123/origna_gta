/**
 * OrignaGTA — Address CRUD API E2E Tests
 * =======================================
 * Comprehensive coverage of address operations: create, read, update, delete, set default.
 * Tests validation: Canadian postal codes, E.164 phone numbers.
 */
import { test, expect, describe } from 'bun:test';
import {
  callOk,
  callExpectError,
  uid,
} from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

describe('Address CRUD API', () => {
  test('AC1: Create address with valid fields', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const result = await callOk('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    expect(result).toBeTruthy();
    expect(result.addressId || result.id).toBeTruthy();
  });

  test('AC2: Get address by ID', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Create first
    const created = await callOk('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    const addressId = created.addressId || created.id;

    // Fetch
    const fetched = await callOk('get_address', {
      addressId,
    }, auth.idToken);

    expect(fetched).toBeTruthy();
    expect(fetched.fullName).toBe('John Doe');
  });

  test('AC3: Update address details', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Create
    const created = await callOk('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    const addressId = created.addressId || created.id;

    // Update
    const updated = await callOk('update_address', {
      addressId,
      city: 'Vancouver',
      province: 'BC',
      postalCode: 'V6B 4X6',
    }, auth.idToken);

    expect(updated.success || updated.updated).toBeTruthy();

    // Verify update
    const fetched = await callOk('get_address', { addressId }, auth.idToken);
    expect(fetched.city).toBe('Vancouver');
    expect(fetched.province).toBe('BC');
  });

  test('AC4: Delete address', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const created = await callOk('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    const addressId = created.addressId || created.id;

    // Delete
    const deleted = await callOk('delete_address', {
      addressId,
    }, auth.idToken);

    expect(deleted.success || deleted.deleted).toBeTruthy();
  });

  test('AC5: Set default address', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const created = await callOk('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    const addressId = created.addressId || created.id;

    // Set as default
    const result = await callOk('set_default_address', {
      addressId,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('AC6: List user addresses', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const result = await callOk('get_user_addresses', {}, auth.idToken);

    expect(result).toBeTruthy();
    expect(Array.isArray(result.addresses || result.items)).toBe(true);
  });

  test('AC7: Postal code must match Canadian format', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const err = await callExpectError('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'INVALID', // Not matching pattern
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    expect(err).toBeTruthy();
    expect(['invalid-argument', 'failed-precondition']).toContain(err?.code);
  });

  test('AC8: Valid postal codes pass validation', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const validPostalCodes = ['M5V 3A8', 'V6B 4X6', 'K1A 0B1'];
    
    for (const postalCode of validPostalCodes) {
      const result = await callOk('create_address', {
        fullName: `Test ${uid()}`,
        streetAddress: '123 Main St',
        city: 'Toronto',
        province: 'ON',
        postalCode,
        country: 'Canada',
        phoneNumber: '+14165551234',
      }, auth.idToken);

      expect(result.addressId || result.id).toBeTruthy();
    }
  });

  test('AC9: Phone number must be E.164 format', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const err = await callExpectError('create_address', {
      fullName: 'John Doe',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '416-555-1234', // Invalid format
    }, auth.idToken);

    expect(err).toBeTruthy();
  });

  test('AC10: Valid phone numbers pass validation', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const validPhones = ['+14165551234', '+12505551234', '+13135551234'];
    
    for (const phone of validPhones) {
      const result = await callOk('create_address', {
        fullName: `Test ${uid()}`,
        streetAddress: '123 Main St',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
        phoneNumber: phone,
      }, auth.idToken);

      expect(result.addressId || result.id).toBeTruthy();
    }
  });

  test('AC11: Full name is required', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    const err = await callExpectError('create_address', {
      fullName: '', // Empty
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth.idToken);

    expect(err).toBeTruthy();
  });

  test('AC12: Unauthenticated address operations fail', async () => {
    const err = await callExpectError('get_user_addresses', {}, 'invalid-token-xxx');
    expect(['unauthenticated', 'failed-precondition']).toContain(err?.code);
  });

  test('AC13: User can only access own addresses', async () => {
    const auth1 = await signIn(BUYER_EMAIL);
    const auth2 = await signIn(TEST_ACCOUNTS.SELLER_EMAIL);
    
    // Create address as buyer
    const created = await callOk('create_address', {
      fullName: 'Buyer Address',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165551234',
    }, auth1.idToken);

    const addressId = created.addressId || created.id;

    // Try to fetch as different user
    const err = await callExpectError('get_address', {
      addressId,
    }, auth2.idToken);

    expect(['permission-denied', 'not-found']).toContain(err?.code);
  });
});
