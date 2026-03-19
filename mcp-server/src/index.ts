#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  CallToolRequestSchema,
  CallToolRequest,
  TextContent,
} from "@modelcontextprotocol/sdk/types.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import axios, { AxiosInstance } from "axios";

const API_BASE_URL = process.env.ORIGNABASE_URL || "https://api.dev.orignagta.ca";
const API_KEY = process.env.ORIGNABASE_API_KEY;
const JWT_TOKEN = process.env.ORIGNABASE_JWT_TOKEN;

interface OrignaBaseClient {
  http: AxiosInstance;
  apiUrl: string;
}

const client: OrignaBaseClient = {
  http: axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
    headers: {
      "Content-Type": "application/json",
      ...(JWT_TOKEN && { Authorization: `Bearer ${JWT_TOKEN}` }),
      ...(API_KEY && { "X-API-Key": API_KEY }),
    },
  }),
  apiUrl: API_BASE_URL,
};

interface SearchProductsParams {
  query: string;
  category?: string;
  min_price?: number;
  max_price?: number;
  limit?: number;
  offset?: number;
}

interface ProductDetails {
  id: string;
  title: string;
  description: string;
  priceCents: number;
  categoryId: string;
  stockQuantity: number;
  imageUrl?: string;
  sellerId: string;
  createdAt: number;
  lifecycleStatus: string;
}

interface OrderDetails {
  id: string;
  buyerId: string;
  sellerId: string;
  status: string;
  totalAmountCents: number;
  createdAt: number;
  items: Array<{
    productId: string;
    name: string;
    quantity: number;
    unitPriceCents: number;
  }>;
}

interface UserProfile {
  id: string;
  email: string;
  displayName?: string;
  role: string;
  createdAt: number;
}

async function searchProducts(params: SearchProductsParams): Promise<ProductDetails[]> {
  try {
    const queryParams = new URLSearchParams({
      q: params.query,
      ...(params.category && { category: params.category }),
      ...(params.min_price !== undefined && { minPrice: String(params.min_price) }),
      ...(params.max_price !== undefined && { maxPrice: String(params.max_price) }),
      limit: String(params.limit || 20),
      offset: String(params.offset || 0),
    });

    const response = await client.http.get(`/search/products?${queryParams}`);
    return response.data.hits || [];
  } catch (error) {
    throw new Error(`Failed to search products: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function getProduct(id: string): Promise<ProductDetails> {
  try {
    const response = await client.http.get(`/products/${id}`);
    return response.data;
  } catch (error) {
    throw new Error(`Failed to fetch product: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function getOrder(id: string): Promise<OrderDetails> {
  try {
    const response = await client.http.get(`/orders/${id}`);
    return response.data;
  } catch (error) {
    throw new Error(`Failed to fetch order: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function listOrders(
  userId: string,
  status?: string,
  limit: number = 20,
  offset: number = 0
): Promise<OrderDetails[]> {
  try {
    const queryParams = new URLSearchParams({
      userId,
      limit: String(limit),
      offset: String(offset),
      ...(status && { status }),
    });

    const response = await client.http.get(`/orders?${queryParams}`);
    return response.data.items || [];
  } catch (error) {
    throw new Error(`Failed to list orders: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function getUser(id: string): Promise<UserProfile> {
  try {
    const response = await client.http.get(`/users/${id}`);
    return response.data;
  } catch (error) {
    throw new Error(`Failed to fetch user: ${error instanceof Error ? error.message : String(error)}`);
  }
}

interface Analytics {
  period: string;
  totalRevenueCents: number;
  totalOrders: number;
  averageOrderValueCents: number;
  topProducts: Array<{ id: string; title: string; sold: number }>;
}

async function getAnalytics(period: string = "week"): Promise<Analytics> {
  try {
    const response = await client.http.get(`/analytics?period=${period}`);
    return response.data;
  } catch (error) {
    throw new Error(`Failed to fetch analytics: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function checkInventory(productId: string): Promise<{ productId: string; stockQuantity: number; available: boolean }> {
  try {
    const response = await client.http.get(`/products/${productId}/inventory`);
    return {
      productId,
      stockQuantity: response.data.stockQuantity,
      available: response.data.stockQuantity > 0,
    };
  } catch (error) {
    throw new Error(`Failed to check inventory: ${error instanceof Error ? error.message : String(error)}`);
  }
}

const server = new Server({
  name: "orignagta-mcp",
  version: "1.0.0",
});

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "search_products",
      description: "Search products in OrignaGTA by query, category, or price range",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Search query (e.g., 'laptop', 'electronics')",
          },
          category: {
            type: "string",
            description: "Category filter (optional)",
          },
          min_price: {
            type: "number",
            description: "Minimum price in cents (optional)",
          },
          max_price: {
            type: "number",
            description: "Maximum price in cents (optional)",
          },
          limit: {
            type: "number",
            description: "Number of results (default: 20, max: 100)",
          },
          offset: {
            type: "number",
            description: "Pagination offset (default: 0)",
          },
        },
        required: ["query"],
      },
    },
    {
      name: "get_product",
      description: "Get detailed information about a specific product",
      inputSchema: {
        type: "object",
        properties: {
          id: {
            type: "string",
            description: "Product ID",
          },
        },
        required: ["id"],
      },
    },
    {
      name: "get_order",
      description: "Get details about a specific order",
      inputSchema: {
        type: "object",
        properties: {
          id: {
            type: "string",
            description: "Order ID",
          },
        },
        required: ["id"],
      },
    },
    {
      name: "list_orders",
      description: "List orders for a user with optional filtering by status",
      inputSchema: {
        type: "object",
        properties: {
          user_id: {
            type: "string",
            description: "User ID",
          },
          status: {
            type: "string",
            description: "Order status filter (pending, confirmed, shipped, delivered, cancelled)",
          },
          limit: {
            type: "number",
            description: "Number of results (default: 20)",
          },
          offset: {
            type: "number",
            description: "Pagination offset (default: 0)",
          },
        },
        required: ["user_id"],
      },
    },
    {
      name: "get_user",
      description: "Get user profile information",
      inputSchema: {
        type: "object",
        properties: {
          id: {
            type: "string",
            description: "User ID",
          },
        },
        required: ["id"],
      },
    },
    {
      name: "get_analytics",
      description: "Get platform analytics data for a time period",
      inputSchema: {
        type: "object",
        properties: {
          period: {
            type: "string",
            description: "Period: day, week, month, year",
          },
        },
      },
    },
    {
      name: "check_inventory",
      description: "Check stock levels for a specific product",
      inputSchema: {
        type: "object",
        properties: {
          product_id: {
            type: "string",
            description: "Product ID",
          },
        },
        required: ["product_id"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request: CallToolRequest) => {
  try {
    const { name, arguments: args } = request;
    const params = args as Record<string, unknown>;

    let result: unknown;

    switch (name) {
      case "search_products": {
        result = await searchProducts({
          query: String(params.query),
          category: params.category ? String(params.category) : undefined,
          min_price: params.min_price ? Number(params.min_price) : undefined,
          max_price: params.max_price ? Number(params.max_price) : undefined,
          limit: params.limit ? Number(params.limit) : 20,
          offset: params.offset ? Number(params.offset) : 0,
        });
        break;
      }

      case "get_product": {
        result = await getProduct(String(params.id));
        break;
      }

      case "get_order": {
        result = await getOrder(String(params.id));
        break;
      }

      case "list_orders": {
        result = await listOrders(
          String(params.user_id),
          params.status ? String(params.status) : undefined,
          params.limit ? Number(params.limit) : 20,
          params.offset ? Number(params.offset) : 0
        );
        break;
      }

      case "get_user": {
        result = await getUser(String(params.id));
        break;
      }

      case "get_analytics": {
        result = await getAnalytics(params.period ? String(params.period) : "week");
        break;
      }

      case "check_inventory": {
        result = await checkInventory(String(params.product_id));
        break;
      }

      default:
        return {
          content: [
            {
              type: "text",
              text: `Unknown tool: ${name}`,
            },
          ],
          isError: true,
        };
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        } as TextContent,
      ],
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error instanceof Error ? error.message : String(error)}`,
        } as TextContent,
      ],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("OrignaGTA MCP Server running on stdio");
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
