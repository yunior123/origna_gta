#!/usr/bin/env bun

import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { AgentBrowser } from './agent-browser.js';

const OUT_DIR = '/Users/yuniorrodriguezosorio/Desktop/origna-design-review-2026-03-26';

const SCREEN_KEYWORDS: Record<string, string[]> = {
  'menu-my-orders': ['Commandes', 'commandes', 'order-card', 'Aucune commande'],
  'menu-favorites': ['favoris', 'Favoris', 'favorite', 'Aucun favori'],
  'menu-my-messages': ['messages', 'Messages', 'chat', 'Premium requis', 'Boîte de réception', 'Aucun message'],
  'menu-premium': ['Abonnement', 'Premium', 'subscription', 'Annuler'],
  'menu-address': ['Adresses', 'adresse', 'address', 'livraison'],
  'menu-seller-orders': ['Gérer les commandes', 'seller-order', 'commande'],
  'menu-seller-dashboard': ['Mes produits', 'produit', 'Ajouter', 'produits'],
  'menu-seller-analytics': ['Analytique', 'analytique', 'Revenue'],
  'menu-admin-panel': ['Panneau', 'admin', 'Vendeurs', 'Utilisateurs', 'Statistiques'],
  'btn-add-product': ['Nouveau produit', 'add-product', 'Nom du produit'],
  'btn-cart': ['panier', 'Panier', 'cart', 'Passer à la caisse'],
  'menu-language': ['Langue', 'language', 'Français', 'English'],
};

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function safeClickSearch(
  browser: AgentBrowser,
  pattern: RegExp,
  scrollAttempts = 4,
): Promise<boolean> {
  for (let i = 0; i < scrollAttempts; i += 1) {
    const ok = await browser.safeClick(pattern).catch(() => false);
    if (ok) {
      await sleep(2_500);
      return true;
    }
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  }
  return false;
}

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const browser = new AgentBrowser();

  const capture = async (name: string, keywords: string[], width: number, height: number) => {
    await browser.screenshotWithVerify({
      filepath: join(OUT_DIR, name),
      expectedKeywords: keywords,
      viewport: { width, height },
    });
  };

  await browser.goHomeAndLogin();

  // === MOBILE CAPTURES ===
  await browser.run(['set', 'viewport', '390', '844'] as any);
  await browser.goHomeAndLogin();
  await capture('174-home-mobile-authenticated.png', ['panier', 'btn-add-product'], 390, 844);
  
  await browser.safeClick(/btn-home-sort/i);
  await capture('175-home-sort-mobile.png', ['Trier', 'sort'], 390, 844);
  await browser.safeClick(/btn-home-price-filter/i);
  await capture('176-home-price-filter-mobile.png', ['Prix', 'price'], 390, 844);

  // Add Product Mobile
  await browser.goHomeAndLogin();
  let res = await browser.navigateAndVerify({ clickRef: 'btn-add-product', expectedKeywords: SCREEN_KEYWORDS['btn-add-product'] });
  if (res.success) {
    await sleep(4000);
    await capture('177-addproduct-top-mobile.png', SCREEN_KEYWORDS['btn-add-product'], 390, 844);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('178-addproduct-mid-mobile.png', ['livraison', 'poids', 'delivery', 'weight'], 390, 844);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('179-addproduct-bottom-mobile.png', ['fournisseur', 'supplier', 'boutique'], 390, 844);
  }

  // Edit Product Mobile
  await browser.goHomeAndLogin();
  const editClicked = await safeClickSearch(browser, /btn-edit-product-/i, 2);
  if (editClicked) {
    await capture('180-editproduct-top-mobile.png', ['Modifier', 'edit'], 390, 844);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('181-editproduct-mid-mobile.png', ['livraison', 'shipping'], 390, 844);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('182-editproduct-bottom-mobile.png', ['adresse', 'location'], 390, 844);
  }

  // Profile Mobile Menu
  await browser.goHomeAndLogin();
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3000);
  await capture('183-profile-mobile-menu.png', ['Abonnement', 'Paramètres', 'Settings'], 390, 844);

  res = await browser.navigateToProfileMenu('menu-favorites', SCREEN_KEYWORDS['menu-favorites']);
  if (res.success) await capture('184-favorites-empty-mobile.png', SCREEN_KEYWORDS['menu-favorites'], 390, 844);

  res = await browser.navigateToProfileMenu('menu-address', SCREEN_KEYWORDS['menu-address']);
  if (res.success) await capture('185-addresses-mobile.png', SCREEN_KEYWORDS['menu-address'], 390, 844);

  res = await browser.navigateToProfileMenu('menu-my-messages', SCREEN_KEYWORDS['menu-my-messages']);
  if (res.success) {
    await capture('186-chat-inbox-mobile.png', SCREEN_KEYWORDS['menu-my-messages'], 390, 844);
    const threadClicked = await safeClickSearch(browser, /chat-thread-/i, 3);
    if (threadClicked) await capture('187-chat-thread-mobile.png', ['envoyer', 'send'], 390, 844);
  }

  res = await browser.navigateToProfileMenu('menu-premium', SCREEN_KEYWORDS['menu-premium']);
  if (res.success) await capture('188-subscription-mobile.png', SCREEN_KEYWORDS['menu-premium'], 390, 844);

  res = await browser.navigateToProfileMenu('menu-seller-orders', SCREEN_KEYWORDS['menu-seller-orders']);
  if (res.success) await capture('189-seller-orders-mobile.png', SCREEN_KEYWORDS['menu-seller-orders'], 390, 844);

  res = await browser.navigateToProfileMenu('menu-seller-dashboard', SCREEN_KEYWORDS['menu-seller-dashboard']);
  if (res.success) await capture('190-seller-products-mobile.png', SCREEN_KEYWORDS['menu-seller-dashboard'], 390, 844);

  res = await browser.navigateToProfileMenu('menu-admin-panel', SCREEN_KEYWORDS['menu-admin-panel']);
  if (res.success) {
    await capture('191-admin-users-mobile.png', ['Utilisateurs', 'Users', 'admin'], 390, 844);
    await browser.safeClick(/admin-tab-orders|admin_tab_orders|Commandes/i);
    await sleep(2500);
    await capture('192-admin-orders-mobile.png', ['Commandes', 'Orders'], 390, 844);
    await browser.safeClick(/admin-tab-products|admin_tab_products|Produits/i);
    await sleep(2500);
    await capture('193-admin-products-mobile.png', ['Produits', 'Products'], 390, 844);
  }

  await browser.goHomeAndLogin();
  res = await browser.navigateAndVerify({ clickRef: 'btn-cart', expectedKeywords: SCREEN_KEYWORDS['btn-cart'] });
  if (res.success) {
    await capture('194-cart-mobile.png', SCREEN_KEYWORDS['btn-cart'], 390, 844);
    const checkoutClicked = await safeClickSearch(browser, /checkout|btn-checkout|place order|Passer/i, 2);
    if (checkoutClicked) {
      await capture('195-checkout-top-mobile.png', ['adresse', 'address'], 390, 844);
      await browser.scrollAndWait('down', 2_000).catch(() => undefined);
      await capture('196-checkout-mid-mobile.png', ['articles', 'items'], 390, 844);
      await browser.scrollAndWait('down', 2_000).catch(() => undefined);
      await capture('197-checkout-bottom-mobile.png', ['paiement', 'payment'], 390, 844);
    }
  }


  // === DESKTOP CAPTURES ===
  await browser.run(['set', 'viewport', '1440', '900'] as any);
  await browser.goHomeAndLogin();
  await capture('198-home-search-focus.png', ['panier', 'btn-add-product'], 1440, 900);
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture('199-home-scrolled-desktop.png', ['panier'], 1440, 900);

  await browser.goHomeAndLogin();
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3000);
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture('200-profile-scrolled-desktop.png', ['Abonnement', 'Paramètres', 'Settings'], 1440, 900);

  res = await browser.navigateToProfileMenu('menu-address', SCREEN_KEYWORDS['menu-address']);
  if (res.success) {
    await capture('201-addresses-top-desktop.png', SCREEN_KEYWORDS['menu-address'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('202-addresses-bottom-desktop.png', SCREEN_KEYWORDS['menu-address'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-seller-orders', SCREEN_KEYWORDS['menu-seller-orders']);
  if (res.success) {
    await capture('203-seller-orders-top-desktop.png', SCREEN_KEYWORDS['menu-seller-orders'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('204-seller-orders-middle-desktop.png', SCREEN_KEYWORDS['menu-seller-orders'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('205-seller-orders-bottom-desktop.png', SCREEN_KEYWORDS['menu-seller-orders'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-seller-dashboard', SCREEN_KEYWORDS['menu-seller-dashboard']);
  if (res.success) {
    await capture('206-seller-products-top-desktop.png', SCREEN_KEYWORDS['menu-seller-dashboard'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('207-seller-products-middle-desktop.png', SCREEN_KEYWORDS['menu-seller-dashboard'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('208-seller-products-bottom-desktop.png', SCREEN_KEYWORDS['menu-seller-dashboard'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-admin-panel', SCREEN_KEYWORDS['menu-admin-panel']);
  if (res.success) {
    await capture('209-admin-users-top-desktop.png', ['Utilisateurs', 'Users', 'admin'], 1440, 900);
    await browser.safeClick(/admin-tab-orders|admin_tab_orders|Commandes/i);
    await sleep(2500);
    await capture('210-admin-orders-top-desktop.png', ['Commandes', 'Orders'], 1440, 900);
    await browser.safeClick(/admin-tab-products|admin_tab_products|Produits/i);
    await sleep(2500);
    await capture('211-admin-products-top-desktop.png', ['Produits', 'Products'], 1440, 900);
  }

  await browser.goHomeAndLogin();
  res = await browser.navigateAndVerify({ clickRef: 'btn-cart', expectedKeywords: SCREEN_KEYWORDS['btn-cart'] });
  if (res.success) {
    await capture('212-cart-top-desktop.png', SCREEN_KEYWORDS['btn-cart'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('213-cart-bottom-desktop.png', SCREEN_KEYWORDS['btn-cart'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-my-messages', SCREEN_KEYWORDS['menu-my-messages']);
  if (res.success) {
    const threadClicked = await safeClickSearch(browser, /chat-thread-/i, 3);
    if (threadClicked) await capture('214-chat-thread-bottom-desktop.png', ['envoyer', 'send'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-premium', SCREEN_KEYWORDS['menu-premium']);
  if (res.success) await capture('215-subscription-details-desktop.png', SCREEN_KEYWORDS['menu-premium'], 1440, 900);

  res = await browser.navigateToProfileMenu('menu-language', SCREEN_KEYWORDS['menu-language']);
  if (res.success) await capture('216-language-selector-closeup.png', SCREEN_KEYWORDS['menu-language'], 1440, 900);

  res = await browser.navigateToProfileMenu('menu-favorites', SCREEN_KEYWORDS['menu-favorites']);
  if (res.success) await capture('217-favorites-empty-closeup.png', SCREEN_KEYWORDS['menu-favorites'], 1440, 900);

  await browser.goHomeAndLogin();
  await capture('218-home-product-grid-closeup.png', ['panier'], 1440, 900);

  const editClicked2 = await safeClickSearch(browser, /btn-edit-product-/i, 2);
  if (editClicked2) {
    await capture('219-editproduct-images-panel-desktop.png', ['Modifier', 'edit', 'images', 'media'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('220-editproduct-inventory-panel-desktop.png', ['stock', 'inventaire'], 1440, 900);
  }

  await browser.goHomeAndLogin();
  res = await browser.navigateAndVerify({ clickRef: 'btn-add-product', expectedKeywords: SCREEN_KEYWORDS['btn-add-product'] });
  if (res.success) {
    await capture('221-addproduct-shipping-options-desktop.png', ['livraison', 'shipping'], 1440, 900);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('222-addproduct-warehouse-selector-desktop.png', ['entrepôt', 'warehouse', 'adresse'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-admin-panel', SCREEN_KEYWORDS['menu-admin-panel']);
  if (res.success) await capture('223-admin-panel-overview-desktop.png', SCREEN_KEYWORDS['menu-admin-panel'], 1440, 900);

  await browser.goHomeAndLogin();
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3000);
  await capture('224-profile-theme-switcher-desktop.png', ['Abonnement', 'Paramètres', 'Settings'], 1440, 900);

  res = await browser.navigateToProfileMenu('menu-address', SCREEN_KEYWORDS['menu-address']);
  if (res.success) {
    const formClicked = await safeClickSearch(browser, /add|edit|address|nouvelle/i, 3);
    if (formClicked) await capture('225-address-form-fields-desktop.png', ['sauvegarder', 'save', 'ville', 'city'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-my-messages', SCREEN_KEYWORDS['menu-my-messages']);
  if (res.success) {
    await capture('226-chat-empty-state-desktop.png', SCREEN_KEYWORDS['menu-my-messages'], 1440, 900);
    const threadClicked = await safeClickSearch(browser, /chat-thread-/i, 3);
    if (threadClicked) await capture('227-chat-thread-header-desktop.png', ['envoyer', 'send'], 1440, 900);
  }

  res = await browser.navigateToProfileMenu('menu-seller-orders', SCREEN_KEYWORDS['menu-seller-orders']);
  if (res.success) await capture('228-seller-orders-dialog-area-desktop.png', SCREEN_KEYWORDS['menu-seller-orders'], 1440, 900);

  await browser.goHomeAndLogin();
  res = await browser.navigateAndVerify({ clickRef: 'btn-cart', expectedKeywords: SCREEN_KEYWORDS['btn-cart'] });
  if (res.success) {
    await capture('229-cart-summary-sticky-desktop.png', SCREEN_KEYWORDS['btn-cart'], 1440, 900);
    const checkoutClicked = await safeClickSearch(browser, /checkout|btn-checkout|place order|Passer/i, 2);
    if (checkoutClicked) {
      await sleep(3_000);
      await capture('230-checkout-summary-bottom-desktop.png', ['paiement', 'payment'], 1440, 900);
    }
  }

  await browser.goHomeAndLogin();
  await capture('231-home-category-chips-desktop.png', ['panier', 'btn-add-product'], 1440, 900);

  await browser.goHomeAndLogin();
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3000);
  await capture('232-profile-actions-desktop.png', ['Abonnement', 'Paramètres'], 1440, 900);

  res = await browser.navigateToProfileMenu('menu-admin-panel', SCREEN_KEYWORDS['menu-admin-panel']);
  if (res.success) await capture('233-admin-tabstrip-desktop.png', SCREEN_KEYWORDS['menu-admin-panel'], 1440, 900);
}

main().catch(console.error);
