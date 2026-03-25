# Product Specs Expert

Help sellers fill category-appropriate product specifications. Knows all 20 category templates, suggests missing required specs, and enforces Canadian regulatory compliance.

## Activation

When a seller asks for help filling product specs, choosing specs for a category, or checking compliance.

## Codebase References

- Translations: `origna_gta/assets/translations/en.json` and `fr.json` (`specs` block)
- Schema constants: `origna_gta/lib/core/schema/schema_constants.dart`
- Product models: `origna_gta/lib/models/generated/product_models.dart`
- Add product VM: `origna_gta/lib/features/products/add_product_viewmodel.dart`
- Seed data examples: `e2e/lib/seed-dev.ts` (search for `specs:`)

## Spec Structure

Each product spec entry:
```json
{ "key": "brand", "value": "Samsung", "valueType": "text", "group": "General" }
```
- `valueType`: `text`, `number`, `boolean`
- `unit` (optional): `inches`, `GB`, `hours`, `kg`, etc.
- Top-level `brand`, `color`, `material` fields for quick filtering

## Category Templates (20 categories)

1. **Electronics** (cat 1) — General: brand, model, color, warranty, certificationMark | Display: screenSize, resolution | Connectivity: connectivity | Power: batteryLife
2. **Computers** (cat 2) — Performance: processor, ram, storage, storageType, gpu, os | Display: screenSize, resolution | Power: batteryLife | Connectivity: ports
3. **Video Games** (cat 3) — Gameplay: platform, genre, players, ageRating | Hardware: controllerType
4. **Home & Kitchen** (cat 4) — General: brand, model, color, material, dimensions | Power: wattage | Physical: capacity | Care: careInstructions | Regulatory: energuideRating
5. **Fashion** (cat 5) — Fabric: fibreContent, material | Sizing: size, fit, gender | General: color, season, madeIn | Care: careInstructions
6. **Shoes** (cat 6) — General: brand, color, size | Materials: material, soleMaterial | Physical: heelHeight, width, closure
7. **Jewelry & Watches** (cat 7) — Materials: material, gemstone, carat, bandMaterial | Movement: movement, waterResistance | Certifications: hallmark
8. **Beauty** (cat 8) — Product Info: skinType, volume, activeIngredients, scent, spf | Certifications: crueltyFree, veganProduct
9. **Health** (cat 9) — Product Info: dosageForm, quantity, flavor, activeIngredients | Regulatory: npnNumber, warnings
10. **Sports & Outdoors** (cat 10) — Equipment: sport, material, dimensions, weightCapacity | General: brand, color
11. **Automotive** (cat 11) — Compatibility: yearRange, make, partType, oemNumber, fitment | General: brand, material
12. **Tools & Home Improvement** (cat 12) — Equipment: powerSource, voltage, toolWeight, includes | Compatibility: compatibility | General: brand, warranty
13. **Books** (cat 13) — Publication: author, isbn, pages, publisher, language, edition, publicationYear | Format: format
14. **Music** (cat 14) — Instrument: instrumentType, stringsOrKeys, material | General: brand, skillLevel
15. **Toys & Baby** (cat 15) — Safety: ageRange, safetyCert, batteryRequired | Play: educational | Care: washable
16. **Pet Supplies** (cat 16) — Pet Info: petType, petWeight | Product: material, dimensions | General: brand
17. **Art & Collectibles** (cat 17) — Artwork: medium, artDimensions, year, artist | Provenance: framed, certificateOfAuth
18. **Office Supplies** (cat 18) — General: brand, material, dimensions, color | Product Info: quantity
19. **Groceries** (cat 19) — Uses food/nutrition system, not specs
20. **Handmade** (cat 20) — General: material, color, madeIn, dimensions | Care: careInstructions
21. **Digital** (cat 21) — Technical: platform, fileFormat, fileSize, version | License: licenseType

## Canadian Compliance Checklist

### Textile Labelling Act (Fashion, Shoes — cats 5, 6)
- **REQUIRED**: `fibreContent` — must list all fibres with percentages totalling 100%
- **REQUIRED**: `careInstructions` — washing/drying symbols or text
- **REQUIRED**: dealer identity (covered by seller profile)
- Example: `"80% Merino Wool, 20% Nylon"`

### CSA/cUL Safety Marks (Electronics, Home & Kitchen — cats 1, 4)
- **REQUIRED for electrical products**: `certificationMark` — must specify CSA, cUL, or equivalent
- Products without certification cannot legally be sold in Canada

### EnerGuide Rating (Home & Kitchen appliances — cat 4)
- **REQUIRED for major appliances**: `energuideRating`
- Covers: refrigerators, dishwashers, clothes washers/dryers, room ACs

### NPN Number (Health products — cat 9)
- **REQUIRED**: `npnNumber` — Natural Product Number from Health Canada
- All natural health products must have NPN before sale
- `warnings` field also required

### CCPSA (Toys & Baby — cat 15)
- **REQUIRED**: `safetyCert` — must reference CCPSA compliance
- `ageRange` — mandatory age grading
- `batteryRequired` — if applicable, battery safety warnings needed

### Consumer Packaging and Labelling Act
- All products: bilingual labelling (EN + FR) — enforced by translation system
- Net quantity declaration required where applicable

## Workflow

1. Seller selects category
2. Load category template specs
3. Pre-fill with any existing data
4. Highlight required compliance fields with warnings
5. Suggest missing specs based on category best practices
6. Validate before submission (all required fields filled, fibre percentages sum to 100%, etc.)
