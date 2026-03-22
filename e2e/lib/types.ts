/**
 * OrignaGTA — Shared Types for E2E Tests
 */

export interface AuthData {
  idToken: string;
  refreshToken: string;
  localId: string;
  email: string;
  [key: string]: any;
}

export interface DiscoveredProduct {
  id: string;
  name: string;
  price: number;
  sellerId: string;
  stockQuantity: number;
  lifecycleStatus: string;
  rating?: number;
  reviewCount?: number;
  isTrending?: boolean;
  isLocalDeliveryOnly?: boolean;
}

export interface SeedProduct {
  id: string;
  sellerId: string;
  categoryId: number;
  categoryName: string;
  title: string;
  description: string;
  priceCents: number;
  lifecycleStatus: string;
  stockQuantity: number;
  isDigital: boolean;
  isPerishable: boolean;
  freeShipping: boolean;
  hasVariants: boolean;
  subcategory: string;
  shipFromCountry: string;
  isTrending: boolean;
  reviewCount: number;
  rating: number;
  isLocalDeliveryOnly: boolean;
}

export type PublicAuthProviders = {
  google?: {
    enabled?: boolean;
    client_id_configured?: boolean;
    client_secret_configured?: boolean;
  };
  apple?: {
    enabled?: boolean;
    client_id_configured?: boolean;
    client_secret_configured?: boolean;
  };
  oidc?: {
    enabled?: boolean;
    client_id_configured?: boolean;
    client_secret_configured?: boolean;
  };
};

export interface SnapshotRef {
  ref: string;
  role: string;
  name: string;
  text?: string;
}

export interface Snapshot {
  raw: string;
  refs: SnapshotRef[];
}
