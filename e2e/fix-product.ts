import { writeDoc, readDoc, parseDoc } from "./lib/api-client";
import { TEST_USERS } from "./lib/config";
import { getAuthClient } from "./lib/auth-cache";

async function run() {
  console.log("Reading product...");
  const rawDoc = await readDoc("products/e2e_product_test_seller");
  const doc = parseDoc(rawDoc);
  if (doc) {
    console.log("Current status:", doc.lifecycleStatus);
    const admin = await getAuthClient("admin");
    doc.lifecycleStatus = "ACTIVE";
    await writeDoc("products/e2e_product_test_seller", doc, admin.idToken, true);
    console.log("Updated status to ACTIVE!");
    const rawDoc2 = await readDoc("products/e2e_product_test_seller");
    console.log("New status:", parseDoc(rawDoc2).lifecycleStatus);
  } else {
    console.log("Product not found");
  }
}
run().catch(console.error);
