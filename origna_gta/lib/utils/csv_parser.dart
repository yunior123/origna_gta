/// CSV parsing utility for bulk product uploads.
library csv_parser;

/// Represents a single CSV row parsed into a map.
typedef CsvRow = Map<String, dynamic>;

/// Parses CSV content from a string.
/// 
/// Handles:
/// - Quoted fields with embedded commas and newlines
/// - Unquoted fields
/// - Empty fields
/// - Headers are mandatory and become keys
/// 
/// Returns a list of rows (each row is a map of header -> value).
/// Throws [FormatException] if CSV is malformed.
List<CsvRow> parseCsv(String csvContent) {
  final lines = csvContent.split('\n').map((s) => s.trimRight()).toList();
  
  if (lines.isEmpty) {
    return [];
  }

  // Parse header
  final headerLine = lines[0];
  final headers = _parseRow(headerLine);
  
  if (headers.isEmpty) {
    throw FormatException('CSV must have at least one header column');
  }

  // Parse data rows
  final rows = <CsvRow>[];
  var i = 1;
  
  while (i < lines.length) {
    final line = lines[i];
    
    // Skip empty lines
    if (line.trim().isEmpty) {
      i++;
      continue;
    }

    // Handle quoted fields that may span multiple lines
    var fullLine = line;
    var quoteCount = _countUnescapedQuotes(fullLine);
    
    while (quoteCount % 2 != 0 && i + 1 < lines.length) {
      i++;
      fullLine += '\n${lines[i]}';
      quoteCount = _countUnescapedQuotes(fullLine);
    }

    final values = _parseRow(fullLine);
    
    // Pad with empty strings if fewer columns than headers
    while (values.length < headers.length) {
      values.add('');
    }

    // Trim to header length if more columns
    if (values.length > headers.length) {
      values.removeRange(headers.length, values.length);
    }

    final row = <String, dynamic>{};
    for (var j = 0; j < headers.length; j++) {
      row[headers[j]] = values[j].trim();
    }

    rows.add(row);
    i++;
  }

  return rows;
}

/// Parse a single CSV row into a list of unquoted values.
List<String> _parseRow(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;
  var i = 0;

  while (i < line.length) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote ("") → add single quote
        current.write('"');
        i += 2;
      } else {
        // Toggle quote state
        inQuotes = !inQuotes;
        i++;
      }
    } else if (char == ',' && !inQuotes) {
      // Field separator
      fields.add(current.toString());
      current.clear();
      i++;
    } else {
      current.write(char);
      i++;
    }
  }

  // Add final field
  fields.add(current.toString());

  return fields;
}

/// Count unescaped quote characters in a line.
int _countUnescapedQuotes(String line) {
  var count = 0;
  var i = 0;
  
  while (i < line.length) {
    if (line[i] == '"') {
      if (i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote, skip both
        i += 2;
      } else {
        count++;
        i++;
      }
    } else {
      i++;
    }
  }
  
  return count;
}

/// Map CSV row to product fields.
/// 
/// Expected headers (case-insensitive):
/// - title, description, price/priceCents, stock/stockQuantity, category/categoryId,
///   subcategory, weight, perishable/isPerishable, digital/isDigital
/// 
/// Returns a map with standardized field names:
/// - title, description, priceCents (converted from dollars if needed),
///   stockQuantity, categoryId, subcategory, weight, isPerishable, isDigital
/// 
/// Throws [FormatException] if required fields are missing.
Map<String, dynamic> mapCsvToBulkProduct(CsvRow csvRow) {
  // Normalize headers to lowercase
  final normalized = <String, String>{};
  csvRow.forEach((key, value) {
    normalized[key.toString().toLowerCase()] = value.toString().trim();
  });

  // Helper to get value by possible column names
  String? getValue(List<String> possibleNames) {
    for (final name in possibleNames) {
      if (normalized.containsKey(name)) {
        return normalized[name];
      }
    }
    return null;
  }

  // Extract fields
  final title = getValue(['title', 'product name', 'name'])?.trim();
  final description = getValue(['description', 'desc'])?.trim() ?? '';
  final priceStr = getValue(['price', 'pricecents', 'price_cents']) ?? '0';
  final stockStr = getValue(['stock', 'stockquantity', 'stock_quantity', 'quantity']) ?? '0';
  final categoryId = getValue(['category', 'categoryid', 'category_id'])?.trim();
  final subcategory = getValue(['subcategory', 'sub_category'])?.trim() ?? '';
  final weightStr = getValue(['weight']) ?? '0';
  final isPerishableStr = getValue(['perishable', 'isperishable', 'is_perishable'])?.toLowerCase() ?? 'false';
  final isDigitalStr = getValue(['digital', 'isdigital', 'is_digital'])?.toLowerCase() ?? 'false';

  // Validate required fields
  if (title == null || title.isEmpty) {
    throw FormatException('Missing required field: title');
  }
  if (categoryId == null || categoryId.isEmpty) {
    throw FormatException('Missing required field: categoryId (category)');
  }

  // Parse numeric fields
  final priceCents = _parseCentsPrice(priceStr);
  final stockQuantity = _parseInt(stockStr, fieldName: 'stock');
  final weight = _parseDouble(weightStr, fieldName: 'weight', optional: true);

  // Parse boolean fields
  final isPerishable = _parseBoolean(isPerishableStr);
  final isDigital = _parseBoolean(isDigitalStr);

  return <String, dynamic>{
    'title': title,
    'description': description,
    'priceCents': priceCents,
    'stockQuantity': stockQuantity,
    'categoryId': categoryId,
    'subcategory': subcategory,
    if (weight != null) 'weight': weight,
    'isPerishable': isPerishable,
    'isDigital': isDigital,
  };
}

/// Parse price field: accepts dollars (1.99) or cents (199).
/// Converts to integer cents.
/// Assumes if value > 1000, it's already in cents; otherwise multiply by 100.
int _parseCentsPrice(String priceStr) {
  try {
    final trimmed = priceStr.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Price cannot be empty');
    }

    // Check if it looks like cents (no decimal point, large number)
    if (!trimmed.contains('.')) {
      final cents = int.parse(trimmed);
      // If value is > 1000, assume it's already cents
      return cents > 1000 ? cents : cents * 100;
    }

    // Has decimal point → assume dollars
    final dollars = double.parse(trimmed);
    return (dollars * 100).round();
  } catch (_) {
    throw FormatException('Invalid price: "$priceStr"');
  }
}

/// Parse integer field, optional.
int _parseInt(String str, {required String fieldName}) {
  try {
    final trimmed = str.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    return int.parse(trimmed);
  } catch (_) {
    throw FormatException('Invalid $fieldName: "$str" (expected integer)');
  }
}

/// Parse double field, optional.
double? _parseDouble(String str, {required String fieldName, required bool optional}) {
  try {
    final trimmed = str.trim();
    if (trimmed.isEmpty) {
      return optional ? null : 0.0;
    }
    return double.parse(trimmed);
  } catch (_) {
    if (optional) {
      return null;
    }
    throw FormatException('Invalid $fieldName: "$str" (expected decimal)');
  }
}

/// Parse boolean from various string formats.
bool _parseBoolean(String str) {
  final trimmed = str.toLowerCase().trim();
  return trimmed == 'true' ||
      trimmed == '1' ||
      trimmed == 'yes' ||
      trimmed == 'y';
}

/// Generate a CSV template with headers and 2 example rows.
String generateCsvTemplate() {
  const headers = [
    'title',
    'description',
    'price',
    'stock',
    'category',
    'subcategory',
    'weight',
    'perishable',
    'digital'
  ];

  const examples = [
    [
      'Wireless Headphones',
      'High-quality audio with noise cancellation',
      '99.99',
      '50',
      'Electronics',
      'Audio',
      '0.25',
      'false',
      'false'
    ],
    [
      'Organic Coffee Beans',
      'Premium arabica beans from Ethiopia',
      '15.99',
      '100',
      'Food & Beverages',
      'Coffee',
      '1.0',
      'true',
      'false'
    ],
  ];

  final lines = <String>[
    // Header
    headers.map(_escapeCsvField).join(','),
    // Examples
    for (final row in examples) row.map(_escapeCsvField).join(','),
  ];

  return lines.join('\n');
}

/// Escape CSV field: wrap in quotes if contains comma, quote, or newline.
String _escapeCsvField(String field) {
  if (field.contains(',') || field.contains('"') || field.contains('\n')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}
