import re
import json

gaps_file = "/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/translation_gaps.txt"
en_json_file = "/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/assets/translations/en.json"

with open(gaps_file, "r") as f:
    gaps_content = f.read()

# Extract keys inside .tr() like 'some.key'.tr()
# Pattern handles both single and double quotes
keys = re.findall(r"['\"]([a-zA-Z0-9_\.]+)['\"]\s*\.tr\(\)", gaps_content)
# some are inside ${'...' .tr()}
keys += re.findall(r"\$\{\s*['\"]([a-zA-Z0-9_\.]+)['\"]\s*\.tr\(\)\s*\}", gaps_content)

keys = set(keys)

with open(en_json_file, "r") as f:
    en_json = json.load(f)

def get_nested(d, key_path):
    parts = key_path.split('.')
    current = d
    for part in parts:
        if isinstance(current, dict) and part in current:
            current = current[part]
        else:
            return None
    return current if isinstance(current, str) else None

missing_dict = {}
for k in keys:
    val = get_nested(en_json, k)
    if val:
        missing_dict[k] = val
    else:
        missing_dict[k] = ""

with open("/tmp/missing_es.json", "w") as f:
    json.dump(missing_dict, f, indent=2)

print(f"Extracted {len(missing_dict)} missing keys to /tmp/missing_es.json")
