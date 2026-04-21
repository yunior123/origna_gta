import json
import os

en_path = "/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/assets/translations/en.json"
es_path = "/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/assets/translations/es.json"

with open(en_path, "r") as f:
    en_data = json.load(f)

with open(es_path, "r") as f:
    es_data = json.load(f)

def deep_merge(source, target):
    for key, value in source.items():
        if isinstance(value, dict):
            node = target.setdefault(key, {})
            deep_merge(value, node)
        else:
            if key not in target:
                target[key] = value

deep_merge(en_data, es_data)

with open(es_path, "w") as f:
    json.dump(es_data, f, indent=2, ensure_ascii=False)

print("Successfully merged missing keys from en.json into es.json")
