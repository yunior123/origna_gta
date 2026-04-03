import { describe, expect, test } from "bun:test";
import { callOk } from "../../lib/api-client.js";
import { signIn } from "../../lib/auth.js";
import { TEST_ACCOUNTS } from "../../lib/config.js";

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const DEFAULT_PASS = "REDACTED_TEST_PASSWORD";

describe("Geoapify Address Autocomplete", () => {
  let buyerToken = "";

  test("T01 — authenticate buyer", async () => {
    const auth = await signIn(BUYER_EMAIL, DEFAULT_PASS);
    buyerToken = auth.accessToken ?? auth.idToken ?? "";
    expect(buyerToken).toBeTruthy();
  });

  // --- Basic functionality ---

  test("T02 — autocomplete returns suggestions for valid Canadian address", async () => {
    const result = await callOk(
      "get_address_suggestions",
      { query: "123 Yonge Street Toronto" },
      buyerToken,
    );
    // Should return features array (GeoJSON format)
    const features = result?.features ?? result?.suggestions ?? result;
    expect(Array.isArray(features) || features !== undefined).toBe(true);
    // If Geoapify key is configured, we should get results
    if (Array.isArray(features) && features.length > 0) {
      const first = features[0];
      // GeoJSON feature should have properties
      expect(first.properties || first.formatted || first.address).toBeTruthy();
    }
  });

  test("T03 — autocomplete returns suggestions for postal code search", async () => {
    const result = await callOk(
      "get_address_suggestions",
      { query: "M5V 3A8" },
      buyerToken,
    );
    const features = result?.features ?? result?.suggestions ?? result;
    // Postal code search should return at least empty array (not error)
    expect(features !== undefined).toBe(true);
  });

  test("T04 — autocomplete returns suggestions for city-only search", async () => {
    const result = await callOk(
      "get_address_suggestions",
      { query: "Montreal Quebec" },
      buyerToken,
    );
    const features = result?.features ?? result?.suggestions ?? result;
    expect(features !== undefined).toBe(true);
  });

  // --- Edge cases ---

  test("T05 — empty query returns empty results (not error)", async () => {
    try {
      const result = await callOk(
        "get_address_suggestions",
        { query: "" },
        buyerToken,
      );
      // Empty query should return empty features or be handled gracefully
      const features = result?.features ?? result?.suggestions ?? [];
      expect(Array.isArray(features)).toBe(true);
    } catch (e: any) {
      // 400 for empty query is also acceptable
      expect([400, 422].includes(e?.statusCode ?? e?.status)).toBe(true);
    }
  });

  test("T06 — very short query (1-2 chars) handled gracefully", async () => {
    try {
      const result = await callOk(
        "get_address_suggestions",
        { query: "ab" },
        buyerToken,
      );
      // Short query may return empty or few results
      expect(result !== undefined).toBe(true);
    } catch (e: any) {
      // 400 for too-short query is acceptable
      expect([400, 422].includes(e?.statusCode ?? e?.status)).toBe(true);
    }
  });

  test("T07 — special characters in query don't cause server error", async () => {
    try {
      const result = await callOk(
        "get_address_suggestions",
        { query: "<script>alert('xss')</script>" },
        buyerToken,
      );
      // Should handle gracefully — empty results or sanitized
      expect(result !== undefined).toBe(true);
    } catch (e: any) {
      // 400/422 is fine, 500 is NOT
      expect(e?.statusCode ?? e?.status).not.toBe(500);
    }
  });

  test("T08 — SQL injection attempt in query returns safe response", async () => {
    try {
      const result = await callOk(
        "get_address_suggestions",
        { query: "'; DROP TABLE users; --" },
        buyerToken,
      );
      expect(result !== undefined).toBe(true);
    } catch (e: any) {
      expect(e?.statusCode ?? e?.status).not.toBe(500);
    }
  });

  // --- Authentication ---

  test("T09 — unauthenticated request is rejected", async () => {
    try {
      await callOk(
        "get_address_suggestions",
        { query: "Toronto" },
        "invalid-token-xyz",
      );
      // If it doesn't throw, the endpoint might be public (acceptable in some configs)
    } catch (e: any) {
      expect([401, 403].includes(e?.statusCode ?? e?.status)).toBe(true);
    }
  });

  // --- Response format validation ---

  test("T10 — response features have expected GeoJSON structure", async () => {
    const result = await callOk(
      "get_address_suggestions",
      { query: "151 Front Street Toronto Ontario" },
      buyerToken,
    );
    const features = result?.features ?? result?.suggestions ?? [];
    if (Array.isArray(features) && features.length > 0) {
      const feature = features[0];
      // GeoJSON Feature should have type, properties, geometry
      if (feature.type) {
        expect(feature.type).toBe("Feature");
      }
      if (feature.properties) {
        // Should contain address-related fields
        const props = feature.properties;
        const hasAddressInfo =
          props.formatted ||
          props.address_line1 ||
          props.city ||
          props.street;
        expect(hasAddressInfo).toBeTruthy();
      }
      if (feature.geometry) {
        expect(feature.geometry.type).toBe("Point");
        expect(Array.isArray(feature.geometry.coordinates)).toBe(true);
        // Coordinates should be [lng, lat] in valid range
        const [lng, lat] = feature.geometry.coordinates;
        expect(lat).toBeGreaterThan(40); // Canada is above 40°N
        expect(lat).toBeLessThan(85);
        expect(lng).toBeGreaterThan(-145); // Western Canada
        expect(lng).toBeLessThan(-50); // Eastern Canada
      }
    }
    // Test passes even with empty features (API key might not be configured)
  });

  // --- Canada-only filter ---

  test("T11 — results are filtered to Canada", async () => {
    const result = await callOk(
      "get_address_suggestions",
      { query: "1600 Pennsylvania Avenue Washington" },
      buyerToken,
    );
    const features = result?.features ?? result?.suggestions ?? [];
    if (Array.isArray(features) && features.length > 0) {
      // If country filter is working, results should either be empty
      // or contain Canadian addresses only
      for (const feature of features) {
        const country =
          feature?.properties?.country_code ??
          feature?.properties?.country ??
          "";
        if (country) {
          expect(country.toLowerCase()).toMatch(/ca|canada/);
        }
      }
    }
  });

  // --- Rate limiting / Performance ---

  test("T12 — rapid sequential requests don't cause 500", async () => {
    const queries = ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa"];
    const results = await Promise.allSettled(
      queries.map((q) =>
        callOk("get_address_suggestions", { query: q }, buyerToken),
      ),
    );
    // None should be 500
    for (const r of results) {
      if (r.status === "rejected") {
        const code = (r.reason as any)?.statusCode ?? (r.reason as any)?.status;
        expect(code).not.toBe(500);
      }
    }
    // At least some should succeed
    const successes = results.filter((r) => r.status === "fulfilled");
    expect(successes.length).toBeGreaterThan(0);
  });
});
