from __future__ import annotations

import argparse
import io
from pathlib import Path
from typing import Iterable, List

import qrcode
from PIL import Image
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas
from reportlab.platypus import Table, TableStyle

BASE_URL = "https://orignaventures.ca"
DEMO_URL = "https://dev.orignagta.ca"
CONTRACT_URL = f"{BASE_URL}/contract"
PAYMENT_URL = f"{BASE_URL}/pay"
DECK_URL = f"{BASE_URL}/deck"
DONATE_URL = f"{BASE_URL}/donate"
SUPPORT_EMAIL = "support@orignaventures.ca"
SUPPORT_PHONE = "4167865517"
COMPANY = "1001475263 ONTARIO CORPORATION"
BN = "708286364TZ0001"
ONTARIO_CORP_NUMBER = "1001475263"
INCORPORATION_DATE_FR = "23 janvier 2026"
RED = colors.HexColor("#C60000")
GREEN = colors.HexColor("#0C8A43")
DARK = colors.HexColor("#111111")
MUTED = colors.HexColor("#5F6368")
LIGHT = colors.HexColor("#F7F7F7")
BORDER = colors.HexColor("#E0E0E0")
BROWN = colors.HexColor("#6B4326")
DKRED = colors.HexColor("#8B0000")
OFFWHITE = colors.HexColor("#FAF6F6")
LGRAY = colors.HexColor("#EDE0E0")
BLACK = colors.HexColor("#1A1A1A")
GOLD_C = colors.HexColor("#C8983A")
GRBLUE = colors.HexColor("#1A5276")
CHURCH_C = colors.HexColor("#4A235A")
GREEN_C = colors.HexColor("#1E6B2E")


COMPARISON_ROWS = [
    (
        "Shopify",
        "468–1,788+ CAD / year + apps + transaction fees",
        "No",
        "Web storefront first",
        "Fast to start, recurring dependency",
    ),
    (
        "Replit",
        "300+ CAD / year + build/ops time",
        "Yes, but DIY",
        "Limited / not native",
        "Good for prototypes, not polished commerce ownership",
    ),
    (
        "Lovable",
        "600+ CAD / year + backend costs",
        "Limited export",
        "Web-first",
        "AI scaffolding, but product ownership is still constrained",
    ),
    (
        "OrignaGTA",
        "500 CAD code, 1,000 CAD launch, or 1,000+ CAD/month team",
        "Yes",
        "Web + iOS + Android + desktop",
        "Custom ecommerce ownership with source-code delivery",
    ),
]


def draw_shamrock(c: canvas.Canvas, x: float, y: float, scale: float = 1.0) -> None:
    c.saveState()
    c.setFillColor(GREEN)
    r = 10 * scale
    for dx, dy in ((0, 0), (r * 0.75, r * 0.55), (r * 1.5, 0)):
        c.circle(x + dx, y + dy, r, stroke=0, fill=1)
    c.setStrokeColor(GREEN)
    c.setLineWidth(1.5 * scale)
    c.line(x + r, y - r * 0.2, x + r * 1.6, y - r * 1.7)
    c.restoreState()


def lt(
    c: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    font: str,
    size: float,
    color: colors.Color = BLACK,
) -> None:
    c.setFont(font, size)
    c.setFillColor(color)
    c.drawString(x, y, text)


def ct(
    c: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    font: str,
    size: float,
    color: colors.Color = BLACK,
) -> None:
    c.setFont(font, size)
    c.setFillColor(color)
    c.drawCentredString(x, y, text)


def rt(
    c: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    font: str,
    size: float,
    color: colors.Color = BLACK,
) -> None:
    c.setFont(font, size)
    c.setFillColor(color)
    c.drawRightString(x, y, text)


def rrect(
    c: canvas.Canvas,
    x: float,
    y: float,
    w: float,
    h: float,
    r: float = 4,
    fill: colors.Color | None = None,
    stroke: colors.Color | None = None,
    lw: float = 0.7,
) -> None:
    if fill is not None:
        c.setFillColor(fill)
    if stroke is not None:
        c.setStrokeColor(stroke)
        c.setLineWidth(lw)
    p = c.beginPath()
    p.moveTo(x + r, y)
    p.lineTo(x + w - r, y)
    p.arcTo(x + w - r, y, x + w, y + r, -90, 90)
    p.lineTo(x + w, y + h - r)
    p.arcTo(x + w - r, y + h - r, x + w, y + h, 0, 90)
    p.lineTo(x + r, y + h)
    p.arcTo(x, y + h - r, x + r, y + h, 90, 90)
    p.lineTo(x, y + r)
    p.arcTo(x, y, x + r, y + r, 180, 90)
    p.close()
    c.drawPath(
        p, fill=1 if fill is not None else 0, stroke=1 if stroke is not None else 0
    )


def sec(
    c: canvas.Canvas, x: float, y: float, w: float, label: str, fill: colors.Color = RED
) -> float:
    rrect(c, x, y - 13, w, 13, r=3, fill=fill)
    lt(c, label, x + 5, y - 10, "Helvetica-Bold", 6.8, colors.white)
    return y - 17


def draw_maple_leaf(
    c: canvas.Canvas, cx: float, cy: float, size: float, leaf_color: colors.Color = RED
) -> None:
    pts = [
        (0.00, 1.00),
        (0.10, 0.40),
        (0.40, 0.60),
        (0.30, 0.20),
        (0.65, 0.40),
        (0.50, 0.00),
        (0.80, 0.10),
        (0.55, -0.30),
        (0.20, -0.20),
        (0.20, -0.55),
        (0.07, -0.55),
        (0.07, -0.20),
        (-0.20, -0.20),
        (-0.55, -0.30),
        (-0.80, 0.10),
        (-0.50, 0.00),
        (-0.65, 0.40),
        (-0.30, 0.20),
        (-0.40, 0.60),
        (-0.10, 0.40),
    ]
    c.setFillColor(leaf_color)
    p = c.beginPath()
    for i, (px, py) in enumerate(pts):
        ax = cx + px * size
        ay = cy + py * size
        if i == 0:
            p.moveTo(ax, ay)
        else:
            p.lineTo(ax, ay)
    p.close()
    c.drawPath(p, fill=1, stroke=0)


def draw_moose_silhouette(
    c: canvas.Canvas,
    cx: float,
    cy: float,
    size: float,
    moose_color: colors.Color = DKRED,
) -> None:
    s = size
    c.setFillColor(moose_color)
    c.setStrokeColor(moose_color)
    body_pts = [
        (-0.90, -0.10),
        (-0.90, -0.40),
        (-0.30, -0.50),
        (0.20, -0.45),
        (0.40, -0.20),
        (0.50, 0.10),
        (0.20, 0.25),
        (-0.40, 0.30),
        (-0.90, 0.15),
    ]
    p = c.beginPath()
    for i, (px, py) in enumerate(body_pts):
        ax, ay = cx + px * s, cy + py * s
        if i == 0:
            p.moveTo(ax, ay)
        else:
            p.lineTo(ax, ay)
    p.close()
    c.drawPath(p, fill=1, stroke=0)
    head_pts = [
        (0.50, 0.10),
        (0.60, 0.35),
        (0.55, 0.65),
        (0.65, 0.70),
        (0.90, 0.60),
        (1.00, 0.45),
        (0.90, 0.35),
        (0.75, 0.42),
        (0.50, 0.50),
        (0.40, 0.25),
        (0.20, 0.25),
    ]
    p2 = c.beginPath()
    for i, (px, py) in enumerate(head_pts):
        ax, ay = cx + px * s, cy + py * s
        if i == 0:
            p2.moveTo(ax, ay)
        else:
            p2.lineTo(ax, ay)
    p2.close()
    c.drawPath(p2, fill=1, stroke=0)
    c.setLineWidth(1.8)
    for x1, y1, x2, y2, w in [
        (0.68, 0.72, 0.62, 1.00, 2.5),
        (0.62, 1.00, 0.40, 1.15, 2.0),
        (0.62, 1.00, 0.55, 1.20, 2.0),
        (0.62, 1.00, 0.72, 1.18, 2.0),
        (0.68, 0.90, 0.82, 1.05, 1.8),
    ]:
        c.setLineWidth(w)
        c.line(cx + x1 * s, cy + y1 * s, cx + x2 * s, cy + y2 * s)
    c.setFillColor(OFFWHITE)
    c.circle(cx + 0.78 * s, cy + 0.55 * s, 1.5, fill=1, stroke=0)
    c.setFillColor(moose_color)
    for lx in (-0.60, -0.30, 0.05, 0.30):
        c.rect(
            cx + (lx - 0.05) * s, cy - 0.90 * s, 0.10 * s, 0.45 * s, fill=1, stroke=0
        )
        c.setFillColor(BLACK)
        c.rect(
            cx + (lx - 0.07) * s, cy - 0.90 * s, 0.14 * s, 0.07 * s, fill=1, stroke=0
        )
        c.setFillColor(moose_color)


def draw_moose(c: canvas.Canvas, x: float, y: float, scale: float = 1.0) -> None:
    c.saveState()
    c.setFillColor(BROWN)
    c.ellipse(x, y, x + 34 * scale, y + 18 * scale, stroke=0, fill=1)
    c.circle(x + 31 * scale, y + 13 * scale, 6 * scale, stroke=0, fill=1)
    c.setStrokeColor(BROWN)
    c.setLineWidth(1.6 * scale)
    c.line(x + 30 * scale, y + 20 * scale, x + 36 * scale, y + 28 * scale)
    c.line(x + 36 * scale, y + 28 * scale, x + 42 * scale, y + 25 * scale)
    c.line(x + 36 * scale, y + 28 * scale, x + 40 * scale, y + 33 * scale)
    c.line(x + 24 * scale, y + 20 * scale, x + 18 * scale, y + 28 * scale)
    c.line(x + 18 * scale, y + 28 * scale, x + 12 * scale, y + 25 * scale)
    c.line(x + 18 * scale, y + 28 * scale, x + 14 * scale, y + 33 * scale)
    for leg_x in (x + 8 * scale, x + 17 * scale, x + 26 * scale):
        c.line(leg_x, y, leg_x, y - 11 * scale)
    c.restoreState()


def make_qr(url: str) -> ImageReader:
    qr = qrcode.QRCode(box_size=8, border=1)
    qr.add_data(url)
    qr.make(fit=True)
    image = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    buffer.seek(0)
    return ImageReader(buffer)


def qr_card(
    c: canvas.Canvas,
    qr_img: ImageReader,
    x: float,
    y_top: float,
    size: float,
    line1: str,
    line2: str = "",
) -> float:
    pad = 4
    label_h = 14 if line2 else 9
    card_w = size + pad * 2
    card_h = pad + size + pad + label_h
    rrect(
        c, x, y_top - card_h, card_w, card_h, r=3, fill=colors.white, stroke=RED, lw=0.6
    )
    c.drawImage(qr_img, x + pad, y_top - pad - size, width=size, height=size)
    mid_x = x + card_w / 2
    if line2:
        ct(c, line1, mid_x, y_top - card_h + 10, "Helvetica-Bold", 5.0, DKRED)
        ct(c, line2, mid_x, y_top - card_h + 3.6, "Helvetica", 4.4, MUTED)
    else:
        ct(c, line1, mid_x, y_top - card_h + 4.0, "Helvetica-Bold", 5.0, DKRED)
    return y_top - card_h


def draw_header(
    c: canvas.Canvas, width: float, height: float, title: str, subtitle: str
) -> None:
    c.setFillColor(RED)
    c.rect(0, height - 26, width, 26, stroke=0, fill=1)
    draw_shamrock(c, 28, height - 54, 0.7)
    draw_moose(c, width - 80, height - 60, 0.75)
    c.setFillColor(DARK)
    c.setFont("Helvetica-Bold", 24)
    c.drawString(26, height - 56, title)
    c.setFont("Helvetica", 10.5)
    c.setFillColor(MUTED)
    c.drawString(26, height - 72, subtitle)


def draw_card(
    c: canvas.Canvas, x: float, y: float, w: float, h: float, title: str
) -> None:
    c.setFillColor(colors.white)
    c.roundRect(x, y, w, h, 18, stroke=0, fill=1)
    c.setStrokeColor(BORDER)
    c.roundRect(x, y, w, h, 18, stroke=1, fill=0)
    c.setFillColor(DARK)
    c.setFont("Helvetica-Bold", 13)
    c.drawString(x + 14, y + h - 20, title)
    c.setFillColor(RED)
    c.roundRect(x + 14, y + h - 28, 34, 4, 999, stroke=0, fill=1)


def fit_text(
    c: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    max_width: float,
    font: str = "Helvetica",
    size: float = 8.3,
    leading: float = 10.2,
) -> float:
    c.setFont(font, size)
    words = text.split()
    line = ""
    cursor_y = y
    for word in words:
        test = word if not line else f"{line} {word}"
        if c.stringWidth(test, font, size) <= max_width:
            line = test
        else:
            c.drawString(x, cursor_y, line)
            cursor_y -= leading
            line = word
    if line:
        c.drawString(x, cursor_y, line)
        cursor_y -= leading
    return cursor_y


def create_onepager(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    width, height = A4
    margin = 13
    c = canvas.Canvas(str(path), pagesize=A4)

    c.setFillColor(OFFWHITE)
    c.rect(0, 0, width, height, fill=1, stroke=0)
    draw_maple_leaf(c, 30, height - 30, 22, RED)
    draw_maple_leaf(c, width - 30, height - 30, 22, RED)
    draw_moose_silhouette(c, 38, 30, 22, DKRED)
    draw_moose_silhouette(c, width - 38, 30, 22, DKRED)

    header_h = 70
    rrect(c, 0, height - header_h, width, header_h, r=0, fill=RED)
    c.setFillColor(DKRED)
    c.rect(0, height - header_h, width, 3, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.circle(margin + 24, height - header_h / 2, 20, fill=1, stroke=0)
    c.setFillColor(RED)
    c.setFont("Helvetica-Bold", 13)
    c.drawCentredString(margin + 24, height - header_h / 2 - 4, "OV")
    lt(
        c,
        "ORIGNA VENTURES SERVICES",
        margin + 52,
        height - 27,
        "Helvetica-Bold",
        14,
        colors.white,
    )
    lt(
        c,
        "1001475263 ONTARIO CORPORATION  ·  BN 708286364TZ0001  ·  Founded Jan 23, 2026  ·  Ontario Active",
        margin + 52,
        height - 40,
        "Helvetica",
        6,
        colors.HexColor("#FFCCCC"),
    )
    lt(
        c,
        "NAICS 41 — Wholesale Commerce  ·  Ontario, Canada  ·  support@orignaventures.ca",
        margin + 52,
        height - 51,
        "Helvetica",
        6,
        colors.HexColor("#FFCCCC"),
    )
    rt(
        c,
        "Own Your Store. Own Your Code.",
        width - margin,
        height - 28,
        "Helvetica-BoldOblique",
        9.5,
        colors.white,
    )
    rt(
        c,
        "Flutter · Rust · PostgreSQL · iOS · Android · Web · Desktop",
        width - margin,
        height - 40,
        "Helvetica",
        6.5,
        colors.HexColor("#FFE0E0"),
    )
    rt(
        c,
        "orignaventures.ca  ·  dev.orignagta.ca",
        width - margin,
        height - 51,
        "Helvetica",
        6.5,
        colors.HexColor("#FFE0E0"),
    )

    cy = height - header_h - 8
    cy = sec(
        c, margin, cy, width - 2 * margin, "PLATFORM COMPARISON — True Annual Cost"
    )

    comparison_widths = [100, 87, 82, 80, 110]
    table_x = margin + (width - 2 * margin - sum(comparison_widths)) / 2
    rows = [
        ["Feature", "Shopify Basic", "Replit Core", "Lovable Pro", "OrignaGTA"],
        [
            "Annual subscription",
            "$348 USD / yr",
            "$240 USD / yr",
            "$252 USD / yr",
            "500–1,000 CAD\nOne-time only",
        ],
        [
            "Equivalent monthly",
            "~$29 USD / mo",
            "~$20 USD / mo",
            "~$21 USD / mo",
            "$0 / mo after purchase",
        ],
        ["Transaction fees", "0.5–2% + apps", "N/A", "N/A", "No platform fee"],
        [
            "Hosting",
            "Extra cost",
            "Separate billing",
            "Extra backend/cloud",
            "Hetzner 8 GB\nYear 1 included",
        ],
        [
            "Source code",
            "Locked",
            "DIY ownership",
            "Limited export",
            "Full repo access\nGitHub / Bitbucket",
        ],
        [
            "iOS + Android apps",
            "Add-ons needed",
            "Web-focused",
            "Web-first",
            "App Store + Play Store",
        ],
        [
            "Customization",
            "Agency/dev fees",
            "DIY engineering",
            "Prompt iteration",
            "Unlimited by Origna",
        ],
        [
            "Year-1 total",
            "$600–1,800+ USD",
            "$480–2,400+ USD",
            "$500–1,200+ USD",
            "500–1,000 CAD\nfinal pricing",
        ],
    ]
    row_h = 23
    table = Table(rows, colWidths=comparison_widths, rowHeights=row_h)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), RED),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, 0), 7),
                ("ALIGN", (0, 0), (-1, 0), "CENTER"),
                ("BACKGROUND", (4, 1), (4, -1), colors.HexColor("#FFF0F0")),
                ("TEXTCOLOR", (4, 1), (4, -1), DKRED),
                ("FONTNAME", (4, 1), (4, -1), "Helvetica-Bold"),
                ("BACKGROUND", (0, 1), (0, -1), colors.HexColor("#F3EAEA")),
                ("FONTNAME", (0, 1), (0, -1), "Helvetica-Bold"),
                ("ROWBACKGROUNDS", (1, 1), (3, -1), [colors.white, LGRAY]),
                ("FONTSIZE", (0, 1), (-1, -1), 6.1),
                ("ALIGN", (1, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#DDBBBB")),
                ("TOPPADDING", (0, 0), (-1, -1), 2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]
        )
    )
    table_h = row_h * len(rows)
    table.wrapOn(c, sum(comparison_widths), table_h)
    table.drawOn(c, table_x, cy - table_h)
    cy -= table_h + 8

    cy = sec(
        c, margin, cy, width - 2 * margin, "OUR SERVICES — Starter · Popular · Team"
    )
    gap = 5
    avail = width - 2 * margin
    card_w = (avail - 2 * gap) / 3
    card_h = 155
    card_top = cy
    services = [
        (
            "STARTER",
            "OrignaCode",
            "500 CAD · One-time",
            GRBLUE,
            [
                ("What you get", "Full Flutter + Rust + PostgreSQL source code"),
                ("Repo access", "Private GitHub / Bitbucket repo"),
                ("Updates", "Lifetime source code updates"),
                ("Hosting", "Client deploys and hosts"),
                ("License", "Commercial use allowed, no software reselling"),
                ("Contract", "Electronic contract + audit trail"),
                ("Refund", "Full refund before repo access"),
                ("Payment", "Stripe Checkout in CAD"),
            ],
        ),
        (
            "POPULAR",
            "OrignaLaunch",
            "1,000 CAD · One-time",
            DKRED,
            [
                ("Includes", "Everything in OrignaCode"),
                ("Hosting", "Hetzner 8 GB VPS — Year 1 included"),
                ("Apple", "Apple Developer year 1 included"),
                ("Google Play", "Google Play registration included"),
                ("Deploy", "Web + desktop + iOS + Android launch"),
                ("Support", "4 weeks of post-launch support included"),
                ("Timeline", "Live within about 1–2 weeks"),
                ("Repo", "Auto-unlock after sign + cleared payment"),
            ],
        ),
        (
            "TEAM",
            "OrignaTeam",
            "1,000+ CAD / month",
            GREEN_C,
            [
                ("What you get", "Dedicated developer support on your project"),
                ("Tracking", "Working time can be tracked with standard tools"),
                ("Scope", "Ecommerce · vibe-coded apps · web · mobile"),
                ("Requirement", "Daily standup with assigned developer(s)"),
                ("Billing", "API, store, hosting, and testing billed as needed"),
                ("Refund", "Within 24 h before repo unlock"),
                ("Cadence", "Monthly, weekly, or day-rate arrangements"),
                ("Onboarding", "Starts within 48 h of signed contract"),
            ],
        ),
    ]
    for idx, (tag, name, price, color, bullets) in enumerate(services):
        sx = margin + idx * (card_w + gap)
        rrect(
            c,
            sx,
            card_top - card_h,
            card_w,
            card_h,
            r=5,
            fill=colors.white,
            stroke=color,
            lw=1.0,
        )
        rrect(c, sx, card_top - 14, card_w, 14, r=4, fill=color)
        ct(
            c,
            tag,
            sx + card_w / 2,
            card_top - 10.5,
            "Helvetica-Bold",
            6.2,
            colors.white,
        )
        ct(c, name, sx + card_w / 2, card_top - 24, "Helvetica-Bold", 9, color)
        rrect(
            c,
            sx + 8,
            card_top - 37,
            card_w - 16,
            11,
            r=3,
            fill=colors.HexColor("#FFF5F5") if color == DKRED else OFFWHITE,
            stroke=color,
            lw=0.5,
        )
        ct(c, price, sx + card_w / 2, card_top - 33, "Helvetica-Bold", 6.8, color)
        by = card_top - 50
        for label, val in bullets:
            lt(c, f"{label}:", sx + 6, by, "Helvetica-Bold", 5.1, color)
            fit_text(c, val, sx + 54, by, card_w - 62, size=5.1, leading=6.2)
            by -= 8.8
    cy = card_top - card_h - 8

    cy = sec(
        c,
        margin,
        cy,
        width - 2 * margin,
        "PROGRAMS — Referral · Giving · Sponsorship · Partnership",
    )
    program_w = (avail - 3 * gap) / 4
    program_h = 128
    program_top = cy
    programs = [
        (
            "REFERRAL",
            RED,
            "Earn 50 CAD",
            "per qualified sale",
            [
                ("Trigger", "Referred client pays 500 CAD or more"),
                ("Reward", "50 CAD with no referral cap"),
                ("Payout", "Within 30 days of cleared payment"),
                ("How", "Unique referral link per person"),
                ("Stack", "Stacks with partner revenue share"),
            ],
        ),
        (
            "COMMUNITY",
            CHURCH_C,
            "10% of Net Profits",
            "donated to church/community",
            [
                ("Giving", "10% net profit to church/community programs"),
                ("Values", "Faith-driven, people-first business"),
                ("Reporting", "Annual donation report published"),
                ("Scope", "Local churches and community organizations"),
                ("Proof", "Donation QR at the bottom of the page"),
            ],
        ),
        (
            "SPONSORSHIP",
            GOLD_C,
            "Brand Visibility",
            "Flat fee · no revenue share",
            [
                ("Bronze", "500/yr — logo + newsletter"),
                ("Silver", "1,500/yr — partner page + campaigns"),
                ("Gold", "5,000/yr — banner + co-marketing"),
                ("Benefit", "Certificate and meeting visibility"),
                ("Note", "No equity or profit share"),
            ],
        ),
        (
            "PARTNER",
            GREEN_C,
            "5% Revenue Share",
            "+ free OrignaLaunch",
            [
                ("Gift", "Free OrignaLaunch (POPULAR tier) for the partner"),
                ("Rev share", "5% of net revenue brought in"),
                ("Referral", "50 CAD bonus stacked on top"),
                ("Assets", "Co-branded materials + dashboard"),
                ("Tiers", "Affiliate · Reseller · Strategic"),
            ],
        ),
    ]
    for idx, (title, color, big, sub, bullets) in enumerate(programs):
        px = margin + idx * (program_w + gap)
        rrect(
            c,
            px,
            program_top - program_h,
            program_w,
            program_h,
            r=5,
            fill=colors.white,
            stroke=color,
            lw=0.9,
        )
        rrect(c, px, program_top - 14, program_w, 14, r=4, fill=color)
        ct(
            c,
            title,
            px + program_w / 2,
            program_top - 10.5,
            "Helvetica-Bold",
            6.2,
            colors.white,
        )
        ct(c, big, px + program_w / 2, program_top - 24, "Helvetica-Bold", 8.6, color)
        ct(c, sub, px + program_w / 2, program_top - 33.5, "Helvetica", 5.6, MUTED)
        c.setStrokeColor(color)
        c.setLineWidth(0.4)
        c.line(px + 6, program_top - 37, px + program_w - 6, program_top - 37)
        by = program_top - 47
        for label, val in bullets:
            lt(c, f"{label}:", px + 5, by, "Helvetica-Bold", 5.0, color)
            fit_text(c, val, px + 44, by, program_w - 50, size=4.9, leading=6.0)
            by -= 8.8
    cy = program_top - program_h - 8

    cy = sec(
        c,
        margin,
        cy,
        width - 2 * margin,
        "SCAN TO ACT — Contract · Pay · Company · App · Deck · Donate",
    )
    qr_items = [
        (CONTRACT_URL, "CONTRACT", "Electronic signing"),
        (PAYMENT_URL, "PAY NOW", "Stripe Checkout"),
        (BASE_URL, "COMPANY", "orignaventures.ca"),
        (DEMO_URL, "APP DEMO", "dev.orignagta.ca"),
        (DECK_URL, "FULL DECK", "300+ screenshots"),
        (DONATE_URL, "DONATE", "Support the mission"),
    ]
    qr_size = 50
    pad = 4
    card_w = qr_size + pad * 2
    spacing = (avail - len(qr_items) * card_w) / (len(qr_items) + 1)
    qr_top = cy
    for idx, (url, line1, line2) in enumerate(qr_items):
        qx = margin + spacing + idx * (card_w + spacing)
        qr_card(c, make_qr(url), qx, qr_top, qr_size, line1, line2)
    card_h = pad + qr_size + pad + 14
    cy = qr_top - card_h - 6

    strip_top = cy - 4
    strip_h = strip_top - 26
    rrect(
        c,
        margin,
        26,
        width - 2 * margin,
        strip_h,
        r=4,
        fill=colors.white,
        stroke=colors.HexColor("#DDBBBB"),
        lw=0.5,
    )
    col_w = (avail - 2 * gap) / 3

    ax = margin + 6
    ay = strip_top - 10
    lt(c, "ABOUT ORIGNAGTA", ax, ay, "Helvetica-Bold", 6.5, RED)
    for idx, line in enumerate(
        [
            "Custom ecommerce and mobile app platform built on Flutter, Rust, and PostgreSQL.",
            "Cross-platform from day one: web, iOS, Android, and desktop from one codebase.",
            "Clients own the source code, repo access, deployment path, and long-term roadmap.",
        ]
    ):
        lt(c, line, ax, ay - 12 - idx * 9, "Helvetica", 5.3, MUTED)

    mx = margin + col_w + gap + 6
    lt(c, "SIGNING AND PAYMENT FLOW", mx, ay, "Helvetica-Bold", 6.5, DKRED)
    for idx, line in enumerate(
        [
            "Service payments are handled by Stripe Checkout in CAD.",
            "Contract signing is electronic and tracked separately from payment.",
            "Signed contract + cleared payment are both required before repo unlock.",
            "GitHub username is collected for automatic private-repo delivery.",
        ]
    ):
        lt(c, line, mx, ay - 12 - idx * 9, "Helvetica", 5.3, MUTED)

    rx = margin + 2 * (col_w + gap) + 6
    rrect(
        c,
        rx - 6,
        30,
        col_w + 4,
        strip_h - 8,
        r=4,
        fill=colors.HexColor("#F5EEF8"),
        stroke=CHURCH_C,
        lw=0.6,
    )
    lt(c, "COMMUNITY GIVING", rx, ay, "Helvetica-Bold", 6.5, CHURCH_C)
    for idx, line in enumerate(
        [
            "Service payments go to Origna Ventures; separate donations follow a separate flow.",
            "10% of Origna Ventures net profits are reserved for church and community giving.",
            "No charitable tax receipt is promised unless a qualified recipient is explicitly identified.",
            "Donation reporting can be published annually for partners and sponsors.",
        ]
    ):
        lt(c, line, rx, ay - 12 - idx * 9, "Helvetica", 5.4, CHURCH_C)

    footer_h = 22
    rrect(c, 0, 0, width, footer_h, r=0, fill=RED)
    c.setFillColor(DKRED)
    c.rect(0, footer_h - 2, width, 2, fill=1, stroke=0)
    ct(
        c,
        f"{SUPPORT_EMAIL}   |   SMS preferred: ({SUPPORT_PHONE[:3]}) {SUPPORT_PHONE[3:6]}-{SUPPORT_PHONE[6:]}   |   orignaventures.ca   |   dev.orignagta.ca",
        width / 2,
        13,
        "Helvetica",
        6.1,
        colors.white,
    )
    ct(
        c,
        "1001475263 Ontario Corporation · NAICS 41 · Ontario, Canada · Active since January 23, 2026",
        width / 2,
        4.5,
        "Helvetica",
        5.0,
        colors.HexColor("#FFCCCC"),
    )
    c.save()


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
EXCLUDED_SCREENSHOT_SEGMENTS = {
    "build/",
    "coverage/",
    "/web/icons/",
    "/web/splash/",
    "appicon",
    "app_icon",
    "imageset",
    "mipmap-",
    "nanobanana-output",
    "assets/icons",
    "favicon",
    "launchimage",
    "launchbackground",
    "failure",
}
EXCLUDED_SCREENSHOT_NAME_PARTS = {
    "icon",
    "logo",
    "favicon",
    "splash",
    "launcher",
    "save_icon",
    "modern_button",
    "button_",
    "loading_",
    "gradient",
    "typography",
    "color_palette",
    "status_color_reference",
    "spacing_radius",
    "histogram",
    "animations",
}


def is_presentation_screenshot(path: Path) -> bool:
    normalized = path.as_posix().lower()
    if any(segment in normalized for segment in EXCLUDED_SCREENSHOT_SEGMENTS):
        return False
    stem = path.stem.lower()
    if any(part in stem for part in EXCLUDED_SCREENSHOT_NAME_PARTS):
        return False
    try:
        with Image.open(path) as image:
            width, height = image.size
    except Exception:
        return False
    if width < 700 or height < 500:
        return False
    area = width * height
    if area < 600_000:
        return False
    if width == height and width <= 1024:
        return False
    return True


def screenshot_files(paths: Iterable[Path]) -> List[Path]:
    files: List[Path] = []
    for path in paths:
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
            if is_presentation_screenshot(path):
                files.append(path)
        elif path.is_dir():
            for file in sorted(path.rglob("*")):
                if file.suffix.lower() in IMAGE_EXTENSIONS:
                    if is_presentation_screenshot(file):
                        files.append(file)
    return files


def create_full_deck(
    path: Path, screenshot_paths: Iterable[Path], max_screenshots: int
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    screenshots = screenshot_files(screenshot_paths)
    if max_screenshots > 0:
        screenshots = screenshots[:max_screenshots]
    w, h = landscape(A4)
    c = canvas.Canvas(str(path), pagesize=landscape(A4))

    draw_header(
        c,
        w,
        h,
        "Origna Ventures Services — Full Presentation",
        f"{len(screenshots)} validated full-screen screenshots · codebase proof · product overview · investor/demo follow-up deck",
    )
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor(DARK)
    c.drawString(26, h - 108, "Why this deck matters")
    c.setFont("Helvetica", 11)
    bullets = [
        "Custom ecommerce ownership instead of long-term platform rent.",
        "Source-code delivery and repo access for buyers.",
        "Cross-platform product surface: web, iOS, Android, desktop.",
        "Operational stack proof: Flutter, Rust, PostgreSQL, Stripe, Mailjet, webhooks.",
        f"Corporate identity: {COMPANY} · BN {BN} · support@orignaventures.ca · SMS {SUPPORT_PHONE}.",
        "Offer set: 500 CAD lifetime software, 1,000 CAD launch, or 1,000+ CAD/month outsourcing.",
        "Included assets: comparison, legal profile, QR navigation, and validated full-screen design proof.",
    ]
    y = h - 132
    for bullet in bullets:
        c.circle(30, y + 3, 2, stroke=0, fill=1)
        c.drawString(38, y, bullet)
        y -= 22

    qrs = [
        ("Website", BASE_URL),
        ("Demo", DEMO_URL),
        ("Contract", CONTRACT_URL),
        ("Payment", PAYMENT_URL),
        ("Donate", DONATE_URL),
    ]
    qx = 30
    for label, url in qrs:
        c.drawImage(make_qr(url), qx, 40, 66, 66, preserveAspectRatio=True, mask="auto")
        c.setFont("Helvetica-Bold", 8)
        c.drawCentredString(qx + 33, 30, label)
        qx += 95
    c.showPage()

    cols = 3
    rows = 2
    margin_x = 18
    margin_y = 18
    gap = 12
    cell_w = (w - margin_x * 2 - gap * (cols - 1)) / cols
    cell_h = (h - 96 - margin_y * 2 - gap * (rows - 1)) / rows

    for start in range(0, len(screenshots), cols * rows):
        page_files = screenshots[start : start + cols * rows]
        draw_header(
            c,
            w,
            h,
            f"OrignaGTA UI proof — screenshots {start + 1} to {start + len(page_files)}",
            "Design system, ecommerce flows, seller tools, carts, orders, chat, auth, profile, checkout, admin surfaces.",
        )
        for index, image_path in enumerate(page_files):
            col = index % cols
            row = index // cols
            x = margin_x + col * (cell_w + gap)
            y = h - 96 - (row + 1) * cell_h - row * gap
            c.setFillColor(LIGHT)
            c.roundRect(x, y, cell_w, cell_h, 14, stroke=0, fill=1)
            c.setStrokeColor(BORDER)
            c.roundRect(x, y, cell_w, cell_h, 14, stroke=1, fill=0)
            c.setFillColor(DARK)
            c.setFont("Helvetica-Bold", 8)
            c.drawString(x + 10, y + cell_h - 14, image_path.name[:58])
            try:
                img = ImageReader(str(image_path))
                iw, ih = img.getSize()
                max_w = cell_w - 20
                max_h = cell_h - 30
                scale = min(max_w / iw, max_h / ih)
                draw_w = iw * scale
                draw_h = ih * scale
                c.drawImage(
                    img,
                    x + (cell_w - draw_w) / 2,
                    y + 8,
                    draw_w,
                    draw_h,
                    preserveAspectRatio=True,
                    mask="auto",
                )
            except Exception:
                c.setFont("Helvetica", 10)
                c.drawString(x + 10, y + 18, "Unable to render screenshot")
        c.showPage()

    c.save()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--onepager", type=Path, default=Path("output/origna_ventures_onepager.pdf")
    )
    parser.add_argument(
        "--deck", type=Path, default=Path("output/origna_ventures_full_deck.pdf")
    )
    parser.add_argument("--screenshots", type=Path, nargs="*", default=[])
    parser.add_argument("--max-screenshots", type=int, default=360)
    args = parser.parse_args()
    create_onepager(args.onepager)
    if args.screenshots:
        create_full_deck(args.deck, args.screenshots, args.max_screenshots)
