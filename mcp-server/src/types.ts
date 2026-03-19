/**
 * OrignaGTA MCP Server — Type Definitions
 * Core interfaces for the MCP server and OrignaBase API responses
 */

// ============================================================================
// API Responses & Models
// ============================================================================

export interface Product {
  id: string; // SurrealDB ID: "products:abc123"
  title: string;
  description: string;
  priceCents: number; // Integer cents
  imageUrls: string[];
  categoryId?: string;
  subcategory?: string;
  stockQuantity: number;
  isDigital?: boolean;
  isPerishable?: boolean;
  sellerId: string;
  lifecycleStatus: "draft" | "active" | "inactive" | "deleted";
  dateCreated: number; // Unix timestamp
  keywords?: string[];
}

export interface ProductDetail extends Product {
  sellerName: string;
  sellerRating?: number;
  reviews?: Review[];
  shippingWeight?: number;
  sku?: string;
}

export interface Review {
  id: string;
  productId: string;
  userId: string;
  rating: number; // 1-5
  text: string;
  createdAt: number;
  helpful?: number;
}

export interface Order {
  id: string; // "orders:abc123"
  buyerId: string;
  sellerId: string;
  status: "pending" | "confirmed" | "shipped" | "delivered" | "cancelled";
  items: OrderItem[];
  subtotalCents: number;
  taxAmountCents: number;
  shippingCostCents: number;
  totalAmountCents: number;
  platformFeeTotalCents?: number;
  shippingAddress: Address;
  createdAt: number;
  updatedAt?: number;
  deliveredAt?: number;
  trackingNumber?: string;
}

export interface OrderItem {
  productId: string;
  name: string;
  quantity: number;
  unitPriceCents: number;
  imageUrl?: string;
}

export interface Cart {
  items: CartItem[];
  subtotalCents: number;
  taxAmountCents: number;
  shippingEstimateCents: number;
  discountCents?: number;
  appliedCoupon?: string;
}

export interface CartItem {
  productId: string;
  quantity: number;
  priceCents: number;
  title: string;
  imageUrl?: string;
}

export interface Address {
  street: string;
  city: string;
  province: string;
  postalCode: string;
  country: string; // ISO 2-letter code
  phone: string; // E.164 format
}

export interface StripeCheckoutResponse {
  sessionId: string;
  sessionUrl: string;
  clientSecret?: string;
  publishableKey?: string;
}

export interface PaymentLink {
  url: string;
  id: string;
  expiresAt?: number;
}

export interface Analytics {
  period: "day" | "week" | "month" | "year";
  totalRevenueCents: number;
  totalOrders: number;
  averageOrderValueCents: number;
  topProducts: {
    productId: string;
    title: string;
    unitsSold: number;
    revenueCents: number;
  }[];
  ordersByStatus: {
    status: string;
    count: number;
  }[];
}

export interface ReturnRequest {
  id: string;
  orderId: string;
  buyerId: string;
  sellerId: string;
  items: {
    productId: string;
    quantity: number;
  }[];
  reason: string;
  status: "pending" | "approved" | "rejected";
  createdAt: number;
  refundAmountCents?: number;
}

// ============================================================================
// Tool Parameters
// ============================================================================

export interface SearchProductsParams {
  query: string;
  category?: string;
  min_price?: number; // cents
  max_price?: number; // cents
  sort?: "price_asc" | "price_desc" | "newest" | "popular";
  limit?: number;
  offset?: number;
}

export interface GetProductParams {
  id: string;
}

export interface CheckInventoryParams {
  product_id: string;
}

export interface AddToCartParams {
  product_id: string;
  quantity: number;
}

export interface RemoveFromCartParams {
  product_id: string;
}

export interface ApplyCouponParams {
  code: string;
}

export interface CreateCheckoutParams {
  shipping_address: Address;
  coupon?: string;
  idempotency_key?: string;
}

export interface ListOrdersParams {
  status?: string;
  seller_id?: string;
  limit?: number;
  offset?: number;
}

export interface GetOrderParams {
  id: string;
}

export interface RequestReturnParams {
  order_id: string;
  items: {
    product_id: string;
    quantity: number;
  }[];
  reason: string;
}

export interface SubmitReviewParams {
  product_id: string;
  rating: number; // 1-5
  text: string;
}

export interface GetAnalyticsParams {
  period: "day" | "week" | "month" | "year";
}

export interface CreatePaymentLinkParams {
  product_id: string;
  quantity: number;
  one_time?: boolean;
}

// ============================================================================
// Error Types
// ============================================================================

export interface ApiErrorResponse {
  error: string;
  code: string;
  details?: Record<string, any>;
  statusCode: number;
}

// ============================================================================
// Tool Definitions for MCP
// ============================================================================

export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: {
    type: string;
    properties: Record<string, any>;
    required?: string[];
  };
}

export interface ToolResult {
  content: {
    type: "text" | "json";
    text?: string;
    data?: any;
  }[];
  isError?: boolean;
}
