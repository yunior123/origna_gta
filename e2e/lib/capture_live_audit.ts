#!/usr/bin/env bun

import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { AgentBrowser, type CapturePersona } from './agent-browser.js';

const OUT_DIR = process.env.SCREENSHOT_OUT_DIR || '/tmp/origna-design-review';

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
  for (let i = 0; i < scrollAttempts; i += 1) {
    await browser.scrollAndWait('up', 2_000).catch(() => undefined);
  }
  return false;
}

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const browser = new AgentBrowser();

  const goHome = async (persona: CapturePersona) => {
    await browser.goHomeAndLogin(persona);
  };

  const capture = async (
    name: string,
    keywords: string[],
    width: number = 1440,
    height: number = 900,
    requiredKeywordCount = 1,
  ) => {
    await browser.screenshotWithVerify({
      filepath: join(OUT_DIR, name),
      expectedKeywords: keywords,
      viewport: { width, height },
      requiredKeywordCount,
    });
  };

  // HOME PAGE STUFF (1440x900)
  await browser.run(['set', 'viewport', '1440', '900'] as any);
  await browser.open('https://dev.orignagta.ca', 60_000);
  await sleep(4000);
  await browser.safeClick(/btn-home-sort/i);
  await capture('165-home-sort-active.png', ['Trier', 'sort']);
  await browser.safeClick(/btn-home-price-filter/i);
  await capture('166-home-price-filter-active.png', ['Prix', 'price']);
  await capture('143-modern-product-card.png', ['btn-add-to-cart', 'panier']);
  await capture('153-promo-banner.png', ['origna', 'promo', 'btn-home-settings', 'panier']);

  // ADD PRODUCT
  await goHome('seller');
  let res = await browser.navigateAndVerify({ clickRef: 'btn-add-product', expectedKeywords: SCREEN_KEYWORDS['btn-add-product'] });
  if (res.success) {
    await sleep(2000);
    await capture('138-addproduct-food-info.png', SCREEN_KEYWORDS['btn-add-product']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('139-addproduct-delivery.png', ['livraison', 'delivery']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('140-addproduct-package.png', ['poids', 'weight']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('141-addproduct-specs.png', ['spécifications']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('142-addproduct-supplier.png', ['fournisseur', 'supplier', 'boutique']);
  }

  // EDIT PRODUCT
  await goHome('seller');
  const editClicked = await safeClickSearch(browser, /btn-edit-product-/i, 2);
  if (editClicked) {
    await capture('105-edit-product-top.png', ['Modifier', 'edit']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('106-edit-product-media.png', ['images', 'media']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('107-edit-product-shipping.png', ['livraison', 'shipping']);
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
    await capture('108-edit-product-location.png', ['adresse', 'location']);
  }

  // PROFILE HEADER
  await goHome('buyer');
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3000);
  await capture('167-profile-header-card.png', ['Abonnement', 'Paramètres', 'Settings']);

  // FAVORITES
  res = await browser.navigateToProfileMenu('menu-favorites', SCREEN_KEYWORDS['menu-favorites'], 'buyer');
  if (res.success) await capture('159-favorites-screen.png', SCREEN_KEYWORDS['menu-favorites']);

  // ADDRESS
  res = await browser.navigateToProfileMenu('menu-address', SCREEN_KEYWORDS['menu-address'], 'buyer');
  if (res.success) {
    await capture('112-buyer-addresses-list.png', SCREEN_KEYWORDS['menu-address']);
    const formClicked = await safeClickSearch(browser, /add|edit|address|nouvelle/i, 3);
    if (formClicked) await capture('128-address-edit-form.png', ['sauvegarder', 'save', 'ville', 'city']);
  }

  // MESSAGES
  res = await browser.navigateToProfileMenu('menu-my-messages', SCREEN_KEYWORDS['menu-my-messages'], 'buyer');
  if (res.success) {
    await capture('164-chat-premium-gate-or-inbox.png', SCREEN_KEYWORDS['menu-my-messages']);
    const threadClicked = await safeClickSearch(browser, /chat-thread-/i, 3);
    if (threadClicked) await capture('127-chat-conversation.png', ['envoyer', 'send', 'message']);
  }

  // PREMIUM
  res = await browser.navigateToProfileMenu('menu-premium', SCREEN_KEYWORDS['menu-premium'], 'buyer');
  if (res.success) {
    await capture('129-subscription-cancel-flow.png', SCREEN_KEYWORDS['menu-premium']);
    const cancelClicked = await safeClickSearch(browser, /cancel-subscription|btn-cancel-subscription|annuler/i, 2);
    if (cancelClicked) await capture('130-subscription-success.png', ['succès', 'success', 'annulé']);
  }

  // SELLER ORDERS
  res = await browser.navigateToProfileMenu('menu-seller-orders', SCREEN_KEYWORDS['menu-seller-orders'], 'seller');
  if (res.success) {
    await capture('162-seller-orders-populated.png', SCREEN_KEYWORDS['menu-seller-orders']);
    const orderClicked = await safeClickSearch(browser, /order-card-|btn-update-shipping/i, 2);
    if (orderClicked) await capture('156-mark-shipped-dialog.png', ['expédition', 'shipped']);
  }

  // SELLER DASHBOARD
  res = await browser.navigateToProfileMenu('menu-seller-dashboard', SCREEN_KEYWORDS['menu-seller-dashboard'], 'seller');
  if (res.success) await capture('163-seller-products-populated.png', SCREEN_KEYWORDS['menu-seller-dashboard']);

  // ADMIN PANEL
  res = await browser.navigateToProfileMenu('menu-admin-panel', SCREEN_KEYWORDS['menu-admin-panel'], 'admin');
  if (res.success) {
    await capture('168-admin-users-tab.png', ['Utilisateurs', 'Users', 'admin']);
    await browser.safeClick(/admin-tab-orders|admin_tab_orders|Commandes/i);
    await sleep(2500);
    await capture('169-admin-orders-tab.png', ['Commandes', 'Orders']);
    await browser.safeClick(/admin-tab-products|admin_tab_products|Produits/i);
    await sleep(2500);
    await capture('170-admin-products-tab.png', ['Produits', 'Products']);
  }

  // CART & CHECKOUT
  await goHome('buyer');
  res = await browser.navigateAndVerify({ clickRef: 'btn-cart', expectedKeywords: SCREEN_KEYWORDS['btn-cart'] });
  if (res.success) {
    await capture('144-cart-total-breakdown.png', SCREEN_KEYWORDS['btn-cart']);
    await capture('145-free-shipping-progress.png', ['livraison', 'shipping', 'gratuit']);
    const checkoutClicked = await safeClickSearch(browser, /checkout|place order|btn-checkout|Passer/i, 2);
    if (checkoutClicked) {
      await capture('095-checkout-address-section.png', ['adresse', 'address']);
      await browser.scrollAndWait('down', 2_000).catch(() => undefined);
      await capture('096-checkout-items-section.png', ['articles', 'items']);
      await browser.scrollAndWait('down', 2_000).catch(() => undefined);
      await capture('097-checkout-payment-section.png', ['paiement', 'payment']);
    }
  }

  // MORE DESKTOP
  await goHome('buyer');
  await capture('171-home-default-desktop.png', ['panier', 'btn-home-settings']);
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3000);
  await capture('172-profile-menu-desktop.png', ['Abonnement', 'Paramètres']);
  await goHome('buyer');
  await capture('173-home-categories-desktop.png', ['catégorie', 'panier']);
  
  res = await browser.navigateToProfileMenu('menu-language', SCREEN_KEYWORDS['menu-language'], 'buyer');
  if (res.success) await capture('152-language-selector.png', SCREEN_KEYWORDS['menu-language']);
}

main().catch(console.error);
