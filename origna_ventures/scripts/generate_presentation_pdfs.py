from __future__ import annotations

import argparse
import io
import re
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
PRICING_URL = BASE_URL
DECK_URL = f"{BASE_URL}/docs/origna_ventures_full_presentation.pdf"
ONEPAGER_URL = f"{BASE_URL}/docs/origna_ventures_onepager.pdf"
CONTACT_URL = f"{BASE_URL}/#contact"
SUPPORT_EMAIL = "support@orignaventures.ca"
SUPPORT_PHONE = "4167865517"
COMPANY = "Origna Ventures Services"
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


def display_phone(number: str) -> str:
    return f"({number[:3]}) {number[3:6]}-{number[6:]}"


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
        "500 CAD code, 3,000 CAD launch, or 1,000 CAD/month team",
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
    url: str,
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
    c.linkURL(url, (x, y_top - card_h, x + card_w, y_top), relative=0)
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
        "Fast checkout for software delivery, launches, and monthly build support.",
        margin + 52,
        height - 40,
        "Helvetica",
        6.6,
        colors.HexColor("#FFCCCC"),
    )
    lt(
        c,
        "Ontario, Canada  ·  support@orignaventures.ca  ·  Stripe checkout in CAD",
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
        "orignaventures.ca  ·  docs + pricing + demo",
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
            "500–3,000 CAD\nOne-time options",
        ],
        [
            "Equivalent monthly",
            "~$29 USD / mo",
            "~$20 USD / mo",
            "~$21 USD / mo",
            "Code or Launch:\nNo monthly sub",
        ],
        ["Transaction fees", "0.5–2% + apps", "N/A", "N/A", "No platform fee"],
        [
            "Hosting",
            "Extra cost",
            "Separate billing",
            "Extra backend/cloud",
            "Hetzner 8 GB RAM + 80 GB disk\nYear 1 included",
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
            "500–3,000 CAD\ncode or launch",
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
            ("Refund", "Full refund before repo access"),
            ("Payment", "Stripe Checkout in CAD"),
        ],
        PRICING_URL,
    ),
    (
        "POPULAR",
        "OrignaLaunch",
            "3,000 CAD · One-time",
        DKRED,
        [
            ("Includes", "Everything in OrignaCode"),
            ("Hosting", "Hetzner VPS (8 GB RAM + 80 GB disk) — Year 1 included"),
            ("QA Testing", "20 human testers (20h QA) included"),
            ("Apple", "Apple Developer year 1 included"),
            ("Google Play", "Google Play registration included"),
            ("Deploy", "Web + desktop + iOS + Android launch"),
            ("Support", "4 weeks of post-launch support included"),
            ("Timeline", "Live within about 1–2 weeks"),
        ],
        PRICING_URL,
    ),
    (
        "TEAM",
        "OrignaTeam",
            "1,000 CAD / month",
        GREEN_C,
        [
            ("What you get", "Dedicated developer support on your project"),
            ("Tracking", "Working time can be tracked with standard tools"),
            ("Scope", "Ecommerce · vibe-coded apps · web · mobile"),
            ("Requirement", "Daily standup with assigned developer(s)"),
            ("Billing", "API, store, hosting, and testing billed as needed"),
            ("Refund", "Within 24 h of payment, before work begins"),
            ("Cadence", "Monthly, weekly, or day-rate arrangements"),
            ("Onboarding", "Starts within 48 h of payment"),
        ],
        PRICING_URL,
    ),
    ]
    for idx, (tag, name, price, color, bullets, pay_url) in enumerate(services):
        sx = margin + idx * (card_w + gap)
        card_bottom = card_top - card_h
        rrect(
            c,
            sx,
            card_bottom,
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
        qr_sz = 22
        qr_x = sx + card_w - qr_sz - 6
        qr_y = card_bottom + 4
        c.drawImage(make_qr(pay_url), qr_x, qr_y, qr_sz, qr_sz, preserveAspectRatio=True, mask="auto")
        lt(c, "Scan for pricing ->", sx + 6, qr_y + 7, "Helvetica", 4.4, MUTED)
        c.linkURL(pay_url, (sx, card_bottom, sx + card_w, card_top), relative=0)
    cy = card_top - card_h - 8

    cy = sec(
        c,
        margin,
        cy,
        width - 2 * margin,
        "DELIVERY MODEL — Ownership · Launch · Team · Support",
    )
    program_w = (avail - 3 * gap) / 4
    program_h = 128
    program_top = cy
    programs = [
        (
            "OWNERSHIP",
            RED,
            "Source-code ownership",
            "You keep the repo and roadmap",
            [
                ("Codebase", "Flutter frontend + Rust services + PostgreSQL stack"),
                ("Access", "Private GitHub or Bitbucket delivery"),
                ("Control", "No platform lock-in or theme rent"),
                ("Use case", "Best for technical founders and in-house teams"),
                ("Refund", "Available before repo unlock"),
            ],
        ),
        (
            "LAUNCH",
            CHURCH_C,
            "Go live fast",
            "Hosting + stores + QA included",
            [
                ("Hosting", "Hetzner VPS year 1 included"),
                ("Stores", "Apple + Google submission help included"),
                ("QA", "20 human testers included"),
                ("Deploy", "Web, desktop, iOS, and Android"),
                ("Timeline", "Typical launch in 1 to 2 weeks"),
            ],
        ),
        (
            "TEAM",
            GOLD_C,
            "Dedicated developer",
            "1,000 CAD/month",
            [
                ("Cadence", "Monthly engagement with direct execution"),
                ("Coverage", "Ecommerce, web, mobile, desktop"),
                ("QA", "100+ hours QA coverage per month"),
                ("Ops", "API, hosting, and external costs billed separately"),
                ("Start", "Usually within 48 hours"),
            ],
        ),
        (
            "SUPPORT",
            GREEN_C,
            "Direct access",
            "Builder, not agency layers",
            [
                ("Checkout", "Stripe-hosted checkout in CAD"),
                ("Contact", "Support form and email on the main site"),
                ("Policies", "Public policy + payment terms, no contract maze"),
                ("Follow-up", "Launch support and onboarding are explicit"),
                ("Demo", "Live app demo available before purchase"),
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
        "SCAN TO ACT — Pricing · Demo · Deck · Contact",
    )
    qr_items = [
        (PRICING_URL, "PRICING", "orignaventures.ca"),
        (DEMO_URL, "APP DEMO", "dev.orignagta.ca"),
        (DECK_URL, "FULL DECK", "presentation PDF"),
        (CONTACT_URL, "CONTACT", "support + form"),
    ]
    qr_size = 50
    pad = 4
    card_w = qr_size + pad * 2
    spacing = (avail - len(qr_items) * card_w) / (len(qr_items) + 1)
    qr_top = cy
    for idx, (url, line1, line2) in enumerate(qr_items):
        qx = margin + spacing + idx * (card_w + spacing)
        qr_card(c, url, make_qr(url), qx, qr_top, qr_size, line1, line2)
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
    lt(c, "BUYER FLOW", mx, ay, "Helvetica-Bold", 6.5, DKRED)
    for idx, line in enumerate(
        [
            "Homepage tier cards lead directly to Stripe Checkout in CAD.",
            "No contract-signing detour in the public site flow.",
            "Repo delivery and onboarding happen after verified payment.",
            "Support contact stays visible before and after checkout.",
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
    lt(c, "WHY CLIENTS BUY", rx, ay, "Helvetica-Bold", 6.5, CHURCH_C)
    for idx, line in enumerate(
        [
            "Faster than agency procurement for early-stage launches.",
            "More ownership than Shopify-style platform dependence.",
            "Clear tiering: code, launch, or embedded team support.",
            "Cross-platform delivery without rebuying the product per channel.",
        ]
    ):
        lt(c, line, rx, ay - 12 - idx * 9, "Helvetica", 5.4, CHURCH_C)

    footer_h = 22
    rrect(c, 0, 0, width, footer_h, r=0, fill=RED)
    c.setFillColor(DKRED)
    c.rect(0, footer_h - 2, width, 2, fill=1, stroke=0)
    ct(
        c,
        f"{SUPPORT_EMAIL}   |   SMS preferred: {display_phone(SUPPORT_PHONE)}   |   orignaventures.ca   |   dev.orignagta.ca",
        width / 2,
        13,
        "Helvetica",
        6.1,
        colors.white,
    )
    ct(
        c,
        "Pricing-first software services · code ownership, launch delivery, and monthly build support",
        width / 2,
        4.5,
        "Helvetica",
        5.0,
        colors.HexColor("#FFCCCC"),
    )
    c.save()


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
LIVE_SCREENSHOT_RE = re.compile(
    r"^\d{3}-(?:live|mockup)-(gta|ventures)-.+-desktop-(1280|1440|1600|1728)-y\d{5}\.png$"
)
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
    if not LIVE_SCREENSHOT_RE.match(path.name):
        return False
    normalized = path.as_posix().lower()
    if any(segment in normalized for segment in EXCLUDED_SCREENSHOT_SEGMENTS):
        return False
    stem = path.stem.lower()
    if any(part in stem for part in EXCLUDED_SCREENSHOT_NAME_PARTS):
        return False
    try:
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            width, height = image.size
    except Exception:
        return False
    if width < 400 or height < 300:
        return False
    area = width * height
    if area < 200_000:
        return False
    if width == height and width <= 512:
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
    path: Path,
    screenshot_paths: Iterable[Path],
    max_screenshots: int,
    min_screenshots: int,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    screenshots = screenshot_files(screenshot_paths)
    if max_screenshots > 0:
        screenshots = screenshots[:max_screenshots]
    if len(screenshots) < min_screenshots:
        raise ValueError(
            f"Full deck requires at least {min_screenshots} valid screenshots; "
            f"found {len(screenshots)}."
        )
    screenshot_note = (
        f"{len(screenshots)} validated screenshots attached"
        if screenshots
        else "Live screenshot appendix unavailable in this sandbox"
    )
    w, h = landscape(A4)
    c = canvas.Canvas(str(path), pagesize=landscape(A4))

    def metric_card(x: float, y: float, width: float, height: float, value: str, label: str, color: colors.Color) -> None:
        rrect(c, x, y, width, height, r=5, fill=colors.white, stroke=color, lw=0.9)
        c.setFillColor(color)
        c.setFont("Helvetica-Bold", 20)
        c.drawCentredString(x + width / 2, y + height - 26, value)
        c.setFillColor(MUTED)
        c.setFont("Helvetica", 8.5)
        c.drawCentredString(x + width / 2, y + 16, label)

    draw_header(
        c,
        w,
        h,
        "Origna Ventures Services — Full Presentation",
        f"Investor/demo deck · ownership-first software services · {screenshot_note}",
    )
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor(DARK)
    c.drawString(26, h - 108, "Investor Summary")
    c.setFont("Helvetica", 11)
    bullets = [
        "Pricing-first service landing page with direct Stripe checkout from tier cards.",
        "Source-code delivery and repo ownership for buyers who choose OrignaCode or OrignaLaunch.",
        "Cross-platform product surface: web, iOS, Android, and desktop from one stack.",
        "Operational stack proof: Flutter, Rust, PostgreSQL, Stripe, Postal, and webhook handling.",
        f"Public contact path: {SUPPORT_EMAIL} · SMS {display_phone(SUPPORT_PHONE)}.",
        "Offer set: 500 CAD code, 3,000 CAD launch, or 1,000 CAD/month dedicated team.",
        "Included assets: live demo, pricing proof, PDF deck, and validated UI screenshots.",
    ]
    y = h - 132
    for bullet in bullets:
        c.circle(30, y + 3, 2, stroke=0, fill=1)
        c.drawString(38, y, bullet)
        y -= 22

    metric_card(42, 132, 150, 76, "500 CAD", "Code ownership tier", GRBLUE)
    metric_card(222, 132, 150, 76, "3,000 CAD", "Launch delivery tier", DKRED)
    metric_card(402, 132, 150, 76, "1,000 CAD", "Monthly team tier", GREEN_C)
    rrect(c, 590, 132, 210, 76, r=5, fill=colors.HexColor("#FFF5F5"), stroke=RED, lw=0.8)
    lt(c, "Positioning", 606, 184, "Helvetica-Bold", 12, RED)
    fit_text(
        c,
        "A productized services company selling owned commerce infrastructure, launch execution, and recurring build capacity.",
        606,
        166,
        178,
        size=8.5,
        leading=10.5,
    )

    qrs = [
        ("Pricing", PRICING_URL),
        ("Demo", DEMO_URL),
        ("One-pager", ONEPAGER_URL),
        ("Deck", DECK_URL),
        ("Contact", CONTACT_URL),
    ]
    qx = 30
    for label, url in qrs:
        c.drawImage(make_qr(url), qx, 40, 66, 66, preserveAspectRatio=True, mask="auto")
        c.setFont("Helvetica-Bold", 8)
        c.drawCentredString(qx + 33, 30, label)
        c.linkURL(url, (qx, 30, qx + 66, 106), relative=0)
        qx += 95
    c.showPage()

    def footer(page_label: str) -> None:
        c.setFillColor(MUTED)
        c.setFont("Helvetica", 6.5)
        c.drawString(18, 10, f"{COMPANY} · {SUPPORT_EMAIL}")
        c.drawRightString(w - 18, 10, f"{page_label} · orignaventures.ca")

    def bullet_block(items: list[str], x: float, y: float, width: float, color: colors.Color = DARK) -> float:
        cursor = y
        c.setFillColor(color)
        for item in items:
            c.circle(x + 4, cursor + 3, 2, stroke=0, fill=1)
            c.setFillColor(DARK)
            cursor = fit_text(c, item, x + 16, cursor, width - 16, size=11.0, leading=14.0)
            cursor -= 8
            c.setFillColor(color)
        return cursor

    structured_slides = [
        (
            "Problem",
            "Small businesses can launch online stores quickly, but they rarely own the technical foundation.",
            [
                "Template storefronts keep founders dependent on subscriptions, app marketplaces, and transaction layers.",
                "AI builders can produce prototypes, but production commerce still needs payments, auth, deployment, QA, support, and mobile packaging.",
                "Agency quotes are slow and expensive for founders who need a working commerce system now.",
            ],
            [
                ("Platform rent", "Recurring fees continue even when the product stops improving."),
                ("Limited ownership", "Source export, backend control, and mobile apps are often constrained."),
                ("Execution gap", "Checkout, support, hosting, store release, and testing still need operators."),
            ],
        ),
        (
            "Solution",
            "Origna Ventures sells execution packages around OrignaGTA: code ownership, launch delivery, and monthly builder capacity.",
            [
                "OrignaCode gives buyers the source repo for a fixed 500 CAD one-time payment.",
                "OrignaLaunch turns the same product into a live web, desktop, iOS, and Android launch for 3,000 CAD.",
                "OrignaTeam gives clients ongoing dedicated development for 1,000 CAD/month.",
            ],
            [
                ("Code", "Full Flutter + Rust + PostgreSQL stack delivery."),
                ("Launch", "Hosting, QA, Apple, Google Play, and deployment included."),
                ("Team", "Monthly implementation capacity for ecommerce and product work."),
            ],
        ),
        (
            "Product",
            "The product is a working commerce stack, not a static brochure.",
            [
                "Buyer flows: browse, product detail, cart, checkout, profile, addresses, favorites, notifications, support, chat.",
                "Seller flows: products, orders, analytics, warehouses, integrations, bulk upload, product creation.",
                "Admin flows: users, products, orders, moderation, operational visibility.",
            ],
            [
                ("Frontend", "Flutter web, iOS, Android, desktop from one codebase."),
                ("Backend", "OrignaBase Rust VPS, PostgreSQL, Meilisearch, structured error events."),
                ("Payments", "Stripe checkout and webhook-oriented operational flows."),
            ],
        ),
        (
            "Business Model",
            "Simple pricing makes the offer easy to buy and easy to explain.",
            [
                "500 CAD one-time for code ownership and repo delivery.",
                "3,000 CAD one-time for launch delivery with first-year infrastructure components included.",
                "1,000 CAD/month for dedicated implementation support and continuous iteration.",
            ],
            [
                ("No hidden platform fee", "Clients pay for execution, not marketplace lock-in."),
                ("Upsell path", "Code buyers can become launch clients; launch clients can become team clients."),
                ("Services-first cash flow", "Revenue starts before a large software-sales motion is required."),
            ],
        ),
        (
            "Go To Market",
            "Sell to founders who want ownership but cannot absorb a traditional agency cycle.",
            [
                "Primary audience: local retailers, services businesses, marketplace founders, and operators replacing fragile MVPs.",
                "Acquisition: demo site, QR deck, direct outreach, live proof captures, and payment-first landing page.",
                "Conversion: Stripe checkout from tier cards, visible support contact, clear refund boundaries, and fast onboarding.",
            ],
            [
                ("Message", "Own your store. Own your code."),
                ("Proof", "Working app, deck, one-pager, screenshots, and public pricing."),
                ("Close", "Direct checkout in CAD with immediate follow-up path."),
            ],
        ),
        (
            "Differentiation",
            "Origna Ventures competes on ownership and finished delivery, not only page generation.",
            [
                "Versus Shopify: more ownership and no platform tax dependency.",
                "Versus AI builders: stronger production path, mobile packaging, backend, QA, support, and deployment.",
                "Versus agencies: fixed packages, direct builder relationship, and faster launch motion.",
            ],
            [
                ("Ownership", "Client keeps repo access and roadmap control."),
                ("Cross-platform", "Web, mobile, and desktop share the same core product."),
                ("Operator-led", "The same team that sells the product can deploy and support it."),
            ],
        ),
        (
            "Execution Plan",
            "Keep the operation focused on a repeatable package before expanding custom scope.",
            [
                "Standardize the checkout-to-onboarding process for the three service tiers.",
                "Keep demo, one-pager, and investor deck current with each product proof update.",
                "Use OrignaGTA and OrignaBase improvements as reusable assets across future client work.",
            ],
            [
                ("Week 1", "Qualify buyer, collect payment, confirm scope, open onboarding."),
                ("Weeks 1-2", "Launch package: configure, test, deploy, submit stores where applicable."),
                ("Month 1+", "Team package: ship improvements with visible weekly progress."),
            ],
        ),
        (
            "Investor Use",
            "The current need is distribution and operating leverage, not a new prototype.",
            [
                "Use funding or strategic support to acquire clients, harden packaging, and expand support capacity.",
                "Prioritize repeatable ecommerce launches before broad custom agency work.",
                "Build a portfolio of owner-controlled commerce deployments that can become proof, referrals, and recurring support revenue.",
            ],
            [
                ("Capital use", "Marketing, QA capacity, deployment operations, and customer success."),
                ("Milestone", "Repeatable paid launches with documented delivery time and support burden."),
                ("Long-term", "Productized software services backed by reusable owned infrastructure."),
            ],
        ),
    ]

    for index, (title, subtitle, bullets, cards) in enumerate(structured_slides, start=2):
        draw_header(c, w, h, f"Origna Ventures — {title}", subtitle)
        card_gap = 14
        card_w = (w - 52 - card_gap * 2) / 3
        card_y = h - 232
        palette = [RED, CHURCH_C, GREEN_C]
        for i, (card_title, card_text) in enumerate(cards):
            x = 26 + i * (card_w + card_gap)
            rrect(c, x, card_y, card_w, 126, r=5, fill=colors.white, stroke=palette[i % len(palette)], lw=0.9)
            lt(c, card_title, x + 12, card_y + 94, "Helvetica-Bold", 13, palette[i % len(palette)])
            fit_text(c, card_text, x + 12, card_y + 72, card_w - 24, size=10.0, leading=12.5)
        bullet_block(bullets, 42, h - 276, w - 84, RED)
        if title == "Business Model":
            metric_card(72, 54, 160, 78, "500 CAD", "OrignaCode one-time", GRBLUE)
            metric_card(340, 54, 160, 78, "3,000 CAD", "OrignaLaunch one-time", DKRED)
            metric_card(608, 54, 160, 78, "1,000 CAD", "OrignaTeam monthly", GREEN_C)
        else:
            rrect(c, 52, 54, w - 104, 78, r=5, fill=colors.HexColor("#FFF5F5"), stroke=RED, lw=0.7)
            lt(c, "Investor takeaway", 70, 104, "Helvetica-Bold", 12, RED)
            fit_text(
                c,
                f"{title}: {subtitle}",
                70,
                84,
                w - 140,
                size=10.5,
                leading=13.0,
            )
        footer(f"Slide {index}")
        c.showPage()

    cols = 3
    rows = 2
    margin_x = 18
    margin_y = 18
    gap = 12
    header_h = 96
    footer_h = 18
    cell_w = (w - margin_x * 2 - gap * (cols - 1)) / cols
    cell_h = (h - header_h - footer_h - margin_y * 2 - gap * (rows - 1)) / rows

    image_render_failures: list[str] = []
    total_pages = (len(screenshots) + cols * rows - 1) // (cols * rows)
    for start in range(0, len(screenshots), cols * rows):
        page_num = start // (cols * rows) + len(structured_slides) + 2
        page_files = screenshots[start : start + cols * rows]
        draw_header(
            c,
            w,
            h,
            f"Product proof — screenshots {start + 1}\u2013{start + len(page_files)} of {len(screenshots)}",
            "Validated UI captures showing real product breadth, states, flows, and execution quality.",
        )
        for index, image_path in enumerate(page_files):
            col = index % cols
            row = index // cols
            x = margin_x + col * (cell_w + gap)
            y = h - header_h - margin_y - row * (cell_h + gap) - cell_h
            c.setFillColor(LIGHT)
            c.roundRect(x, y, cell_w, cell_h, 10, stroke=0, fill=1)
            c.setStrokeColor(BORDER)
            c.roundRect(x, y, cell_w, cell_h, 10, stroke=1, fill=0)
            c.setFillColor(DARK)
            c.setFont("Helvetica-Bold", 5.2)
            c.drawString(x + 8, y + cell_h - 12, image_path.name)
            try:
                img = ImageReader(str(image_path))
                iw, ih = img.getSize()
                if iw < 1 or ih < 1:
                    raise ValueError(f"Invalid image dimensions {iw}x{ih}")
                max_w = cell_w - 16
                max_h = cell_h - 26
                scale = min(max_w / iw, max_h / ih)
                draw_w = iw * scale
                draw_h = ih * scale
                c.drawImage(
                    img,
                    x + (cell_w - draw_w) / 2,
                    y + 6,
                    draw_w,
                    draw_h,
                    preserveAspectRatio=True,
                    mask="auto",
                )
            except Exception as exc:
                image_render_failures.append(f"{image_path}: {exc}")
        c.setFillColor(MUTED)
        c.setFont("Helvetica", 6.5)
        c.drawString(margin_x, footer_h / 2 - 2, f"{COMPANY} · {SUPPORT_EMAIL}")
        c.drawRightString(
            w - margin_x,
            footer_h / 2 - 2,
            f"Page {page_num} of {total_pages + len(structured_slides) + 1} · orignaventures.ca",
        )
        c.showPage()

    if image_render_failures:
        c.save()
        raise ValueError(
            "Failed to render screenshot images into deck:\n"
            + "\n".join(image_render_failures[:20])
        )

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
    parser.add_argument("--skip-deck", action="store_true")
    parser.add_argument("--max-screenshots", type=int, default=360)
    parser.add_argument("--min-screenshots", type=int, default=300)
    args = parser.parse_args()
    create_onepager(args.onepager)
    if args.skip_deck:
        raise SystemExit(0)
    if not args.screenshots:
        raise SystemExit("Full deck generation requires --screenshots, or pass --skip-deck.")
    create_full_deck(
        args.deck,
        args.screenshots,
        args.max_screenshots,
        args.min_screenshots,
    )
