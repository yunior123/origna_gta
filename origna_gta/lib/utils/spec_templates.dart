import 'package:origna_gta/core/schema/schema_constants.dart';

/// A single spec template defining what specs a category expects.
class SpecTemplate {
  final String key;
  final String labelEn;
  final String labelFr;
  final String valueType;
  final String? unit;
  final String group;
  final bool isRequired;
  final List<String>? options;

  const SpecTemplate({
    required this.key,
    required this.labelEn,
    required this.labelFr,
    this.valueType = 'text',
    this.unit,
    required this.group,
    this.isRequired = false,
    this.options,
  });
}

/// Spec configuration for a category.
class CategorySpecConfig {
  final int categoryId;
  final String categoryName;
  final List<SpecTemplate> templates;
  final List<String> groups;

  const CategorySpecConfig({
    required this.categoryId,
    required this.categoryName,
    required this.templates,
    required this.groups,
  });
}

/// Get spec templates for a category. Returns null for Groceries (uses nutrition).
CategorySpecConfig? getSpecsForCategory(int categoryId) {
  return specTemplateRegistry[categoryId];
}

/// Registry of spec templates for all 20 non-food categories.
final Map<int, CategorySpecConfig> specTemplateRegistry = {
  // Category 1: Electronics
  CategoryIds.electronics: CategorySpecConfig(
    categoryId: CategoryIds.electronics,
    categoryName: 'Electronics',
    groups: ['General', 'Display', 'Power', 'Connectivity'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.brand,
        labelEn: 'Brand',
        labelFr: 'Marque',
        group: 'General',
      ),
      SpecTemplate(
        key: SpecKeyValues.model,
        labelEn: 'Model',
        labelFr: 'Modèle',
        group: 'General',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'General',
      ),
      SpecTemplate(
        key: SpecKeyValues.screenSize,
        labelEn: 'Screen Size',
        labelFr: 'Taille d\'écran',
        group: 'Display',
        unit: 'inches',
      ),
      SpecTemplate(
        key: SpecKeyValues.resolution,
        labelEn: 'Resolution',
        labelFr: 'Résolution',
        group: 'Display',
      ),
      SpecTemplate(
        key: SpecKeyValues.batteryLife,
        labelEn: 'Battery Life',
        labelFr: 'Autonomie',
        group: 'Power',
        unit: 'hours',
      ),
      SpecTemplate(
        key: SpecKeyValues.connectivity,
        labelEn: 'Connectivity',
        labelFr: 'Connectivité',
        group: 'Connectivity',
      ),
      SpecTemplate(
        key: SpecKeyValues.warranty,
        labelEn: 'Warranty',
        labelFr: 'Garantie',
        group: 'General',
      ),
      SpecTemplate(
        key: SpecKeyValues.certificationMark,
        labelEn: 'Certification (CSA/cUL)',
        labelFr: 'Certification (CSA/cUL)',
        group: 'General',
      ),
    ],
  ),

  // Category 2: Computers
  CategoryIds.computers: CategorySpecConfig(
    categoryId: CategoryIds.computers,
    categoryName: 'Computers',
    groups: ['General', 'Performance', 'Display', 'Connectivity'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.brand,
        labelEn: 'Brand',
        labelFr: 'Marque',
        group: 'General',
      ),
      SpecTemplate(
        key: SpecKeyValues.model,
        labelEn: 'Model',
        labelFr: 'Modèle',
        group: 'General',
      ),
      SpecTemplate(
        key: SpecKeyValues.processor,
        labelEn: 'Processor',
        labelFr: 'Processeur',
        group: 'Performance',
      ),
      SpecTemplate(
        key: SpecKeyValues.ram,
        labelEn: 'RAM',
        labelFr: 'Mémoire vive',
        group: 'Performance',
        unit: 'GB',
      ),
      SpecTemplate(
        key: SpecKeyValues.storage,
        labelEn: 'Storage',
        labelFr: 'Stockage',
        group: 'Performance',
        unit: 'GB',
      ),
      SpecTemplate(
        key: SpecKeyValues.storageType,
        labelEn: 'Storage Type',
        labelFr: 'Type de stockage',
        group: 'Performance',
        options: ['SSD', 'HDD', 'NVMe'],
      ),
      SpecTemplate(
        key: SpecKeyValues.gpu,
        labelEn: 'Graphics Card',
        labelFr: 'Carte graphique',
        group: 'Performance',
      ),
      SpecTemplate(
        key: SpecKeyValues.os,
        labelEn: 'Operating System',
        labelFr: 'Système d\'exploitation',
        group: 'Performance',
      ),
      SpecTemplate(
        key: SpecKeyValues.screenSize,
        labelEn: 'Screen Size',
        labelFr: 'Taille d\'écran',
        group: 'Display',
        unit: 'inches',
      ),
      SpecTemplate(
        key: SpecKeyValues.batteryLife,
        labelEn: 'Battery Life',
        labelFr: 'Autonomie',
        group: 'Power',
        unit: 'hours',
      ),
      SpecTemplate(
        key: SpecKeyValues.ports,
        labelEn: 'Ports',
        labelFr: 'Ports',
        group: 'Connectivity',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'General',
      ),
    ],
  ),

  // Category 3: Gaming
  CategoryIds.gaming: CategorySpecConfig(
    categoryId: CategoryIds.gaming,
    categoryName: 'Gaming',
    groups: ['Gameplay', 'Hardware'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.platform,
        labelEn: 'Platform',
        labelFr: 'Plateforme',
        group: 'Gameplay',
      ),
      SpecTemplate(
        key: SpecKeyValues.genre,
        labelEn: 'Genre',
        labelFr: 'Genre',
        group: 'Gameplay',
      ),
      SpecTemplate(
        key: SpecKeyValues.players,
        labelEn: 'Number of Players',
        labelFr: 'Nombre de joueurs',
        group: 'Gameplay',
      ),
      SpecTemplate(
        key: SpecKeyValues.controllerType,
        labelEn: 'Controller Type',
        labelFr: 'Type de manette',
        group: 'Hardware',
      ),
      SpecTemplate(
        key: SpecKeyValues.connectivity,
        labelEn: 'Connectivity',
        labelFr: 'Connectivité',
        group: 'Hardware',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Hardware',
      ),
      SpecTemplate(
        key: SpecKeyValues.ageRating,
        labelEn: 'Age Rating',
        labelFr: 'Classification d\'âge',
        group: 'Gameplay',
      ),
    ],
  ),

  // Category 4: Home & Kitchen
  CategoryIds.homeKitchen: CategorySpecConfig(
    categoryId: CategoryIds.homeKitchen,
    categoryName: 'Home & Kitchen',
    groups: ['Physical', 'Power', 'Care'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.dimensions,
        labelEn: 'Dimensions',
        labelFr: 'Dimensions',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.wattage,
        labelEn: 'Wattage',
        labelFr: 'Puissance',
        group: 'Power',
        unit: 'W',
      ),
      SpecTemplate(
        key: SpecKeyValues.capacity,
        labelEn: 'Capacity',
        labelFr: 'Capacité',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.careInstructions,
        labelEn: 'Care Instructions',
        labelFr: 'Instructions d\'entretien',
        group: 'Care',
      ),
      SpecTemplate(
        key: SpecKeyValues.energuideRating,
        labelEn: 'EnerGuide Rating',
        labelFr: 'Cote ÉnerGuide',
        group: 'Power',
      ),
    ],
  ),

  // Category 5: Fashion
  CategoryIds.fashion: CategorySpecConfig(
    categoryId: CategoryIds.fashion,
    categoryName: 'Fashion',
    groups: ['Fabric', 'Sizing', 'Care'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Fabric',
      ),
      SpecTemplate(
        key: SpecKeyValues.fibreContent,
        labelEn: 'Fibre Content',
        labelFr: 'Contenu en fibres',
        group: 'Fabric',
        isRequired: true,
      ),
      SpecTemplate(
        key: SpecKeyValues.size,
        labelEn: 'Size',
        labelFr: 'Taille',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.fit,
        labelEn: 'Fit',
        labelFr: 'Coupe',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.careInstructions,
        labelEn: 'Care Instructions',
        labelFr: 'Instructions d\'entretien',
        group: 'Care',
      ),
      SpecTemplate(
        key: SpecKeyValues.season,
        labelEn: 'Season',
        labelFr: 'Saison',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.gender,
        labelEn: 'Gender',
        labelFr: 'Genre',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.madeIn,
        labelEn: 'Made In',
        labelFr: 'Fabriqué en',
        group: 'Fabric',
      ),
    ],
  ),

  // Category 6: Shoes & Accessories
  CategoryIds.shoesAccessories: CategorySpecConfig(
    categoryId: CategoryIds.shoesAccessories,
    categoryName: 'Shoes & Accessories',
    groups: ['Sizing', 'Materials'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.size,
        labelEn: 'Size',
        labelFr: 'Taille',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Materials',
      ),
      SpecTemplate(
        key: SpecKeyValues.soleMaterial,
        labelEn: 'Sole Material',
        labelFr: 'Matériau de la semelle',
        group: 'Materials',
      ),
      SpecTemplate(
        key: SpecKeyValues.heelHeight,
        labelEn: 'Heel Height',
        labelFr: 'Hauteur du talon',
        group: 'Sizing',
        unit: 'cm',
      ),
      SpecTemplate(
        key: SpecKeyValues.width,
        labelEn: 'Width',
        labelFr: 'Largeur',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.closure,
        labelEn: 'Closure',
        labelFr: 'Fermeture',
        group: 'Materials',
      ),
    ],
  ),

  // Category 7: Jewelry & Watches
  CategoryIds.jewelryWatches: CategorySpecConfig(
    categoryId: CategoryIds.jewelryWatches,
    categoryName: 'Jewelry & Watches',
    groups: ['Materials', 'Movement'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Materials',
      ),
      SpecTemplate(
        key: SpecKeyValues.gemstone,
        labelEn: 'Gemstone',
        labelFr: 'Pierre précieuse',
        group: 'Materials',
      ),
      SpecTemplate(
        key: SpecKeyValues.carat,
        labelEn: 'Carat',
        labelFr: 'Carat',
        group: 'Materials',
      ),
      SpecTemplate(
        key: SpecKeyValues.bandMaterial,
        labelEn: 'Band Material',
        labelFr: 'Matériau du bracelet',
        group: 'Materials',
      ),
      SpecTemplate(
        key: SpecKeyValues.waterResistance,
        labelEn: 'Water Resistance',
        labelFr: 'Résistance à l\'eau',
        group: 'Movement',
      ),
      SpecTemplate(
        key: SpecKeyValues.movement,
        labelEn: 'Movement',
        labelFr: 'Mouvement',
        group: 'Movement',
      ),
      SpecTemplate(
        key: SpecKeyValues.hallmark,
        labelEn: 'Hallmark',
        labelFr: 'Poinçon',
        group: 'Materials',
      ),
    ],
  ),

  // Category 8: Beauty & Personal Care
  CategoryIds.beautyPersonalCare: CategorySpecConfig(
    categoryId: CategoryIds.beautyPersonalCare,
    categoryName: 'Beauty & Personal Care',
    groups: ['Product Info', 'Certifications'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.skinType,
        labelEn: 'Skin Type',
        labelFr: 'Type de peau',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.volume,
        labelEn: 'Volume',
        labelFr: 'Volume',
        group: 'Product Info',
        unit: 'mL',
      ),
      SpecTemplate(
        key: SpecKeyValues.activeIngredients,
        labelEn: 'Active Ingredients',
        labelFr: 'Ingrédients actifs',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.scent,
        labelEn: 'Scent',
        labelFr: 'Parfum',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.spf,
        labelEn: 'SPF',
        labelFr: 'FPS',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.crueltyFree,
        labelEn: 'Cruelty Free',
        labelFr: 'Sans cruauté',
        group: 'Certifications',
        valueType: 'boolean',
      ),
      SpecTemplate(
        key: SpecKeyValues.veganProduct,
        labelEn: 'Vegan',
        labelFr: 'Végane',
        group: 'Certifications',
        valueType: 'boolean',
      ),
    ],
  ),

  // Category 9: Health & Wellness
  CategoryIds.healthWellness: CategorySpecConfig(
    categoryId: CategoryIds.healthWellness,
    categoryName: 'Health & Wellness',
    groups: ['Product Info', 'Regulatory'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.dosageForm,
        labelEn: 'Dosage Form',
        labelFr: 'Forme posologique',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.quantity,
        labelEn: 'Quantity',
        labelFr: 'Quantité',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.flavor,
        labelEn: 'Flavor',
        labelFr: 'Saveur',
        group: 'Product Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.npnNumber,
        labelEn: 'NPN Number',
        labelFr: 'Numéro NPN',
        group: 'Regulatory',
      ),
      SpecTemplate(
        key: SpecKeyValues.warnings,
        labelEn: 'Warnings',
        labelFr: 'Avertissements',
        group: 'Regulatory',
      ),
    ],
  ),

  // Category 10: Sports & Fitness
  CategoryIds.sportsFitness: CategorySpecConfig(
    categoryId: CategoryIds.sportsFitness,
    categoryName: 'Sports & Fitness',
    groups: ['Equipment', 'Sizing'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.sport,
        labelEn: 'Sport',
        labelFr: 'Sport',
        group: 'Equipment',
      ),
      SpecTemplate(
        key: SpecKeyValues.size,
        labelEn: 'Size',
        labelFr: 'Taille',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Equipment',
      ),
      SpecTemplate(
        key: SpecKeyValues.weightCapacity,
        labelEn: 'Weight Capacity',
        labelFr: 'Capacité de charge',
        group: 'Equipment',
        unit: 'kg',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.gender,
        labelEn: 'Gender',
        labelFr: 'Genre',
        group: 'Sizing',
      ),
    ],
  ),

  // Category 11: Automotive
  CategoryIds.automotive: CategorySpecConfig(
    categoryId: CategoryIds.automotive,
    categoryName: 'Automotive',
    groups: ['Compatibility', 'Physical'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.yearRange,
        labelEn: 'Year Range',
        labelFr: 'Années compatibles',
        group: 'Compatibility',
      ),
      SpecTemplate(
        key: SpecKeyValues.make,
        labelEn: 'Make',
        labelFr: 'Marque du véhicule',
        group: 'Compatibility',
      ),
      SpecTemplate(
        key: SpecKeyValues.model,
        labelEn: 'Model',
        labelFr: 'Modèle',
        group: 'Compatibility',
      ),
      SpecTemplate(
        key: SpecKeyValues.partType,
        labelEn: 'Part Type',
        labelFr: 'Type de pièce',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.oemNumber,
        labelEn: 'OEM Number',
        labelFr: 'Numéro OEM',
        group: 'Compatibility',
      ),
      SpecTemplate(
        key: SpecKeyValues.fitment,
        labelEn: 'Fitment',
        labelFr: 'Compatibilité',
        group: 'Compatibility',
      ),
    ],
  ),

  // Category 12: Tools & Hardware
  CategoryIds.toolsHardware: CategorySpecConfig(
    categoryId: CategoryIds.toolsHardware,
    categoryName: 'Tools & Hardware',
    groups: ['Power', 'Physical'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.powerSource,
        labelEn: 'Power Source',
        labelFr: 'Source d\'alimentation',
        group: 'Power',
      ),
      SpecTemplate(
        key: SpecKeyValues.voltage,
        labelEn: 'Voltage',
        labelFr: 'Tension',
        group: 'Power',
        unit: 'V',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.toolWeight,
        labelEn: 'Weight',
        labelFr: 'Poids',
        group: 'Physical',
        unit: 'kg',
      ),
      SpecTemplate(
        key: SpecKeyValues.warranty,
        labelEn: 'Warranty',
        labelFr: 'Garantie',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.includes,
        labelEn: 'Includes',
        labelFr: 'Inclus',
        group: 'Physical',
      ),
    ],
  ),

  // Category 13: Office Supplies
  CategoryIds.officeSupplies: CategorySpecConfig(
    categoryId: CategoryIds.officeSupplies,
    categoryName: 'Office Supplies',
    groups: ['Physical', 'Compatibility'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.size,
        labelEn: 'Size',
        labelFr: 'Taille',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.quantity,
        labelEn: 'Quantity',
        labelFr: 'Quantité',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.compatibility,
        labelEn: 'Compatibility',
        labelFr: 'Compatibilité',
        group: 'Compatibility',
      ),
    ],
  ),

  // Category 14: Books
  CategoryIds.books: CategorySpecConfig(
    categoryId: CategoryIds.books,
    categoryName: 'Books',
    groups: ['Publication', 'Format'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.author,
        labelEn: 'Author',
        labelFr: 'Auteur',
        group: 'Publication',
      ),
      SpecTemplate(
        key: SpecKeyValues.isbn,
        labelEn: 'ISBN',
        labelFr: 'ISBN',
        group: 'Publication',
      ),
      SpecTemplate(
        key: SpecKeyValues.pages,
        labelEn: 'Pages',
        labelFr: 'Pages',
        group: 'Format',
        valueType: 'number',
      ),
      SpecTemplate(
        key: SpecKeyValues.publisher,
        labelEn: 'Publisher',
        labelFr: 'Éditeur',
        group: 'Publication',
      ),
      SpecTemplate(
        key: SpecKeyValues.language,
        labelEn: 'Language',
        labelFr: 'Langue',
        group: 'Publication',
      ),
      SpecTemplate(
        key: SpecKeyValues.format,
        labelEn: 'Format',
        labelFr: 'Format',
        group: 'Format',
        options: ['Hardcover', 'Paperback', 'eBook', 'Audiobook'],
      ),
      SpecTemplate(
        key: SpecKeyValues.edition,
        labelEn: 'Edition',
        labelFr: 'Édition',
        group: 'Publication',
      ),
      SpecTemplate(
        key: SpecKeyValues.publicationYear,
        labelEn: 'Publication Year',
        labelFr: 'Année de publication',
        group: 'Publication',
        valueType: 'number',
      ),
    ],
  ),

  // Category 15: Music & Instruments
  CategoryIds.musicInstruments: CategorySpecConfig(
    categoryId: CategoryIds.musicInstruments,
    categoryName: 'Music & Instruments',
    groups: ['Instrument', 'Physical'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.instrumentType,
        labelEn: 'Instrument Type',
        labelFr: 'Type d\'instrument',
        group: 'Instrument',
      ),
      SpecTemplate(
        key: SpecKeyValues.brand,
        labelEn: 'Brand',
        labelFr: 'Marque',
        group: 'Instrument',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.stringsOrKeys,
        labelEn: 'Strings/Keys',
        labelFr: 'Cordes/Touches',
        group: 'Instrument',
      ),
      SpecTemplate(
        key: SpecKeyValues.color,
        labelEn: 'Color',
        labelFr: 'Couleur',
        group: 'Physical',
      ),
      SpecTemplate(
        key: SpecKeyValues.skillLevel,
        labelEn: 'Skill Level',
        labelFr: 'Niveau de compétence',
        group: 'Instrument',
        options: ['Beginner', 'Intermediate', 'Advanced', 'Professional'],
      ),
    ],
  ),

  // Category 16: Toys & Games
  CategoryIds.toysGames: CategorySpecConfig(
    categoryId: CategoryIds.toysGames,
    categoryName: 'Toys & Games',
    groups: ['Play', 'Safety'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.ageRange,
        labelEn: 'Age Range',
        labelFr: 'Tranche d\'âge',
        group: 'Play',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Safety',
      ),
      SpecTemplate(
        key: SpecKeyValues.batteryRequired,
        labelEn: 'Battery Required',
        labelFr: 'Piles requises',
        group: 'Play',
        valueType: 'boolean',
      ),
      SpecTemplate(
        key: SpecKeyValues.players,
        labelEn: 'Number of Players',
        labelFr: 'Nombre de joueurs',
        group: 'Play',
      ),
      SpecTemplate(
        key: SpecKeyValues.educational,
        labelEn: 'Educational',
        labelFr: 'Éducatif',
        group: 'Play',
        valueType: 'boolean',
      ),
      SpecTemplate(
        key: SpecKeyValues.safetyCert,
        labelEn: 'Safety Certification',
        labelFr: 'Certification de sécurité',
        group: 'Safety',
      ),
    ],
  ),

  // Category 17: Baby & Kids
  CategoryIds.babyKids: CategorySpecConfig(
    categoryId: CategoryIds.babyKids,
    categoryName: 'Baby & Kids',
    groups: ['Sizing', 'Safety'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.ageRange,
        labelEn: 'Age Range',
        labelFr: 'Tranche d\'âge',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Safety',
      ),
      SpecTemplate(
        key: SpecKeyValues.size,
        labelEn: 'Size',
        labelFr: 'Taille',
        group: 'Sizing',
      ),
      SpecTemplate(
        key: SpecKeyValues.safetyCert,
        labelEn: 'Safety Certification',
        labelFr: 'Certification de sécurité',
        group: 'Safety',
      ),
      SpecTemplate(
        key: SpecKeyValues.washable,
        labelEn: 'Washable',
        labelFr: 'Lavable',
        group: 'Safety',
        valueType: 'boolean',
      ),
      SpecTemplate(
        key: SpecKeyValues.gender,
        labelEn: 'Gender',
        labelFr: 'Genre',
        group: 'Sizing',
      ),
    ],
  ),

  // Category 18: Pet Supplies
  CategoryIds.petSupplies: CategorySpecConfig(
    categoryId: CategoryIds.petSupplies,
    categoryName: 'Pet Supplies',
    groups: ['Pet Info', 'Product'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.petType,
        labelEn: 'Pet Type',
        labelFr: 'Type d\'animal',
        group: 'Pet Info',
      ),
      SpecTemplate(
        key: SpecKeyValues.size,
        labelEn: 'Size',
        labelFr: 'Taille',
        group: 'Product',
      ),
      SpecTemplate(
        key: SpecKeyValues.material,
        labelEn: 'Material',
        labelFr: 'Matériau',
        group: 'Product',
      ),
      SpecTemplate(
        key: SpecKeyValues.flavor,
        labelEn: 'Flavor',
        labelFr: 'Saveur',
        group: 'Product',
      ),
      SpecTemplate(
        key: SpecKeyValues.petWeight,
        labelEn: 'Pet Weight Range',
        labelFr: 'Poids de l\'animal',
        group: 'Pet Info',
        unit: 'kg',
      ),
      SpecTemplate(
        key: SpecKeyValues.ageRange,
        labelEn: 'Age Range',
        labelFr: 'Tranche d\'âge',
        group: 'Pet Info',
      ),
    ],
  ),

  // Category 19: Groceries — EXCLUDED (uses NutritionFacts)

  // Category 20: Art & Collectibles
  CategoryIds.artCollectibles: CategorySpecConfig(
    categoryId: CategoryIds.artCollectibles,
    categoryName: 'Art & Collectibles',
    groups: ['Artwork', 'Provenance'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.medium,
        labelEn: 'Medium',
        labelFr: 'Médium',
        group: 'Artwork',
      ),
      SpecTemplate(
        key: SpecKeyValues.artDimensions,
        labelEn: 'Dimensions',
        labelFr: 'Dimensions',
        group: 'Artwork',
      ),
      SpecTemplate(
        key: SpecKeyValues.year,
        labelEn: 'Year',
        labelFr: 'Année',
        group: 'Provenance',
        valueType: 'number',
      ),
      SpecTemplate(
        key: SpecKeyValues.artist,
        labelEn: 'Artist',
        labelFr: 'Artiste',
        group: 'Provenance',
      ),
      SpecTemplate(
        key: SpecKeyValues.edition,
        labelEn: 'Edition',
        labelFr: 'Édition',
        group: 'Provenance',
      ),
      SpecTemplate(
        key: SpecKeyValues.framed,
        labelEn: 'Framed',
        labelFr: 'Encadré',
        group: 'Artwork',
        valueType: 'boolean',
      ),
      SpecTemplate(
        key: SpecKeyValues.certificateOfAuth,
        labelEn: 'Certificate of Authenticity',
        labelFr: 'Certificat d\'authenticité',
        group: 'Provenance',
        valueType: 'boolean',
      ),
    ],
  ),

  // Category 21: Digital Products
  CategoryIds.digitalProducts: CategorySpecConfig(
    categoryId: CategoryIds.digitalProducts,
    categoryName: 'Digital Products',
    groups: ['Technical', 'License'],
    templates: [
      SpecTemplate(
        key: SpecKeyValues.platform,
        labelEn: 'Platform',
        labelFr: 'Plateforme',
        group: 'Technical',
      ),
      SpecTemplate(
        key: SpecKeyValues.fileFormat,
        labelEn: 'File Format',
        labelFr: 'Format de fichier',
        group: 'Technical',
      ),
      SpecTemplate(
        key: SpecKeyValues.fileSize,
        labelEn: 'File Size',
        labelFr: 'Taille du fichier',
        group: 'Technical',
      ),
      SpecTemplate(
        key: SpecKeyValues.licenseType,
        labelEn: 'License Type',
        labelFr: 'Type de licence',
        group: 'License',
      ),
      SpecTemplate(
        key: SpecKeyValues.language,
        labelEn: 'Language',
        labelFr: 'Langue',
        group: 'Technical',
      ),
      SpecTemplate(
        key: SpecKeyValues.version,
        labelEn: 'Version',
        labelFr: 'Version',
        group: 'Technical',
      ),
    ],
  ),
};
