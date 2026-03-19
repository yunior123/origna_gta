/**
 * Test OrignaGTA MCP Server — Agent Purchase End-to-End
 * Simulates a buyer: search → add to cart → checkout → order
 */

import { spawn } from "child_process";
import { randomUUID } from "crypto";

const API_URL = "https://api.dev.orignagta.ca";
const BUYER_EMAIL = "e2e-buyer@test.origna.ca";
const BUYER_PASSWORD = "REDACTED_TEST_PASSWORD";

interface MCPRequest {
  jsonrpc: "2.0";
  id: number | string;
  method: string;
  params?: any;
}

interface MCPResponse {
  jsonrpc: "2.0";
  id: number | string;
  result?: any;
  error?: { code: number; message: string; data?: any };
}

let nextId = 1;
const responses = new Map<number | string, MCPResponse>();
const responsePending = new Map<number | string, { resolve: Function; reject: Function }>();

function sendMCPRequest(method: string, params?: any): Promise<MCPResponse> {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const request: MCPRequest = { jsonrpc: "2.0", id, method };
    if (params) request.params = params;

    responsePending.set(id, { resolve, reject });
    setTimeout(() => reject(new Error(`Timeout waiting for response id ${id}`)), 10000);

    const line = JSON.stringify(request) + "\n";
    process.stdout.write(`[MCP REQUEST] ${JSON.stringify(request)}\n`);
    serverProcess.stdin?.write(line);
  });
}

function handleMCPResponse(data: string) {
  const lines = data.split("\n");
  for (const line of lines) {
    if (!line.trim()) continue;

    try {
      const msg = JSON.parse(line);

      // Structured logs from server
      if (msg.timestamp && msg.level) {
        process.stdout.write(
          `[LOG ${msg.level}] ${msg.message} | tool=${msg.tool} duration=${msg.duration}ms\n`
        );
        return;
      }

      // MCP Response
      if (msg.jsonrpc === "2.0" && "id" in msg) {
        responses.set(msg.id, msg);
        const pending = responsePending.get(msg.id);
        if (pending) {
          pending.resolve(msg);
          responsePending.delete(msg.id);
        }
        process.stdout.write(`[MCP RESPONSE] id=${msg.id} ${msg.result ? "OK" : "ERROR"}\n`);
        return;
      }

      // Other JSON output
      process.stdout.write(`[SERVER OUTPUT] ${line}\n`);
    } catch (e) {
      // Non-JSON lines
      process.stdout.write(`[SERVER LOG] ${line}\n`);
    }
  }
}

let serverProcess: ReturnType<typeof spawn>;

async function runTests() {
  console.log("=== OrignaGTA MCP Server — Agent Purchase E2E Test ===\n");

  // Start MCP server
  console.log("1. Starting MCP server...");
  serverProcess = spawn("node", ["dist/index.js"], {
    env: {
      ...process.env,
      ORIGNABASE_URL: API_URL,
      MCP_AUTH_EMAIL: BUYER_EMAIL,
      MCP_AUTH_PASSWORD: BUYER_PASSWORD,
      NODE_ENV: "development",
    },
    stdio: ["pipe", "pipe", "pipe"],
  });

  serverProcess.stdout?.on("data", (data) => handleMCPResponse(data.toString()));
  serverProcess.stderr?.on("data", (data) =>
    process.stdout.write(`[STDERR] ${data.toString()}`)
  );

  // Give server time to start
  await new Promise((r) => setTimeout(r, 2000));

  try {
    // Step 1: Initialize
    console.log("\n2. Initialize MCP...");
    const initResp = await sendMCPRequest("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "test-agent", version: "1.0" },
    });
    if (initResp.error) {
      console.error("Initialize failed:", initResp.error);
      return;
    }
    console.log("✓ Server initialized");

    // Step 2: List tools
    console.log("\n3. List available tools...");
    const toolsResp = await sendMCPRequest("tools/list");
    if (toolsResp.error) {
      console.error("tools/list failed:", toolsResp.error);
      return;
    }
    const tools = toolsResp.result?.tools || [];
    console.log(`✓ Found ${tools.length} tools`);
    tools.forEach((t: any) => console.log(`  - ${t.name}`));

    // Step 3: Search products
    console.log("\n4. Search products (query='test')...");
    const searchResp = await sendMCPRequest("tools/call", {
      name: "search_products",
      arguments: { query: "test", limit: 3 },
    });
    if (searchResp.error) {
      console.error("search_products failed:", searchResp.error);
      return;
    }
    const searchContent = searchResp.result?.content?.[0];
    let products: any[] = [];
    if (searchContent?.text) {
      try {
        const parsed = JSON.parse(searchContent.text);
        products = parsed.items || parsed || [];
      } catch (e) {
        console.error("Failed to parse search results:", searchContent.text);
      }
    }
    if (products.length === 0) {
      console.error("No products found!");
      return;
    }
    console.log(`✓ Found ${products.length} products`);
    products.slice(0, 3).forEach((p: any, i: number) => {
      console.log(
        `  [${i + 1}] ${p.title || p.name} — $${(p.priceCents / 100).toFixed(2)} (stock: ${p.stockQuantity})`
      );
    });

    // Step 4: Get product details
    if (products.length > 0) {
      const firstProduct = products[0];
      const productId = firstProduct.id || `products:test_${randomUUID().slice(0, 8)}`;

      console.log(`\n5. Get product details (${productId})...`);
      const detailResp = await sendMCPRequest("tools/call", {
        name: "get_product",
        arguments: { id: productId },
      });
      if (detailResp.error) {
        console.warn("get_product failed (may not support detail fetch):", detailResp.error.message);
      } else {
        console.log("✓ Got product details");
      }

      // Step 5: Add to cart
      console.log(`\n6. Add to cart (product: ${productId}, qty: 1)...`);
      const cartResp = await sendMCPRequest("tools/call", {
        name: "add_to_cart",
        arguments: { product_id: productId, quantity: 1 },
      });
      if (cartResp.error) {
        console.warn("add_to_cart failed:", cartResp.error.message);
      } else {
        console.log("✓ Added to cart");
      }

      // Step 6: Get cart
      console.log(`\n7. Get cart...`);
      const getCartResp = await sendMCPRequest("tools/call", {
        name: "get_cart",
        arguments: {},
      });
      if (getCartResp.error) {
        console.warn("get_cart failed:", getCartResp.error.message);
      } else {
        const cartContent = getCartResp.result?.content?.[0];
        console.log("✓ Got cart:", cartContent?.text?.slice(0, 200));
      }

      // Step 7: Create checkout session
      console.log(`\n8. Create checkout session...`);
      const checkoutResp = await sendMCPRequest("tools/call", {
        name: "create_checkout",
        arguments: {
          shipping_address: {
            street: "123 Test St",
            city: "Toronto",
            province: "ON",
            postalCode: "M1A 1A1",
            country: "CA",
          },
        },
      });
      if (checkoutResp.error) {
        console.warn("create_checkout failed:", checkoutResp.error.message);
      } else {
        const checkoutContent = checkoutResp.result?.content?.[0];
        console.log("✓ Checkout session created");
        console.log(`  Response: ${checkoutContent?.text?.slice(0, 300)}`);
      }

      // Step 8: List orders
      console.log(`\n9. List orders...`);
      const ordersResp = await sendMCPRequest("tools/call", {
        name: "list_orders",
        arguments: { limit: 5 },
      });
      if (ordersResp.error) {
        console.warn("list_orders failed:", ordersResp.error.message);
      } else {
        const ordersContent = ordersResp.result?.content?.[0];
        console.log("✓ Got orders:", ordersContent?.text?.slice(0, 200));
      }

      // Step 9: Submit review (if any delivered orders exist)
      console.log(`\n10. Submit review...`);
      const reviewResp = await sendMCPRequest("tools/call", {
        name: "submit_review",
        arguments: {
          product_id: productId,
          rating: 5,
          text: "Great product! Tested via MCP agent.",
        },
      });
      if (reviewResp.error) {
        console.warn("submit_review failed:", reviewResp.error.message);
      } else {
        console.log("✓ Review submitted");
      }

      // Step 10: Get analytics
      console.log(`\n11. Get analytics...`);
      const analyticsResp = await sendMCPRequest("tools/call", {
        name: "get_analytics",
        arguments: { period: "month" },
      });
      if (analyticsResp.error) {
        console.warn("get_analytics failed:", analyticsResp.error.message);
      } else {
        const analyticsContent = analyticsResp.result?.content?.[0];
        console.log("✓ Got analytics:", analyticsContent?.text?.slice(0, 200));
      }
    }

    console.log("\n=== Test Complete ===\n");
  } catch (error) {
    console.error("Test error:", error);
  } finally {
    serverProcess.kill();
    process.exit(0);
  }
}

runTests();
