"""Product management — list, approve, reject, delete."""
import click
from cli.utils.output import header, success, error, console, make_table, confirm_prod
from cli.utils.firebase_client import get_firestore


@click.group()
def products():
    """Manage marketplace products."""
    pass


@products.command(name="list")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--pending-approval", is_flag=True, default=False)
@click.option("--seller", default=None, help="Filter by seller UID")
@click.option("--limit", default=20)
def list_products(env: str, pending_approval: bool, seller: str | None, limit: int):
    """List products with optional filters."""
    header("Products", env)
    db = get_firestore(env)
    query = db.collection("products").limit(limit)
    if pending_approval:
        query = query.where("approvalStatus", "==", "pending")
    if seller:
        query = query.where("sellerId", "==", seller)
    docs = list(query.stream())
    t = make_table(f"Products ({env}) — {len(docs)}", ["ID", "Title", "Seller", "Price", "Stock", "Approval"])
    for doc in docs:
        d = doc.to_dict()
        price = d.get("priceCents", 0)
        t.add_row(
            doc.id[:16],
            str(d.get("title", "—"))[:30],
            d.get("sellerId", "—")[:16],
            f"${price/100:.2f}",
            str(d.get("stockQuantity", 0)),
            d.get("approvalStatus", "approved"),
        )
    console.print(t)


@products.command()
@click.argument("product_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def approve(product_id: str, env: str):
    """Approve a product for listing."""
    header(f"Approve {product_id[:12]}...", env)
    db = get_firestore(env)
    db.collection("products").document(product_id).update({"approvalStatus": "approved"})
    success(f"Product {product_id} approved")


@products.command()
@click.argument("product_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--reason", required=True)
def reject(product_id: str, env: str, reason: str):
    """Reject a product with a reason."""
    header(f"Reject {product_id[:12]}...", env)
    db = get_firestore(env)
    db.collection("products").document(product_id).update({
        "approvalStatus": "rejected",
        "rejectionReason": reason,
    })
    success(f"Product {product_id} rejected: {reason}")


@products.command()
@click.argument("product_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.confirmation_option(prompt="Permanently delete this product?")
def delete(product_id: str, env: str):
    """Permanently delete a product."""
    header(f"Delete {product_id[:12]}...", env)
    if env == "prod" and not confirm_prod(f"delete product {product_id}"):
        return
    db = get_firestore(env)
    db.collection("products").document(product_id).delete()
    success(f"Product {product_id} deleted")
