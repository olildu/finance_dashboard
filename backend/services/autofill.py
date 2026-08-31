from collections import Counter
from rapidfuzz import process, fuzz

def get_top_suggestions(choices, limit=3, threshold=50):
    counts = Counter(choices)
    grouped = {}
    mapping = {}

    for item, freq in counts.items():
        match = process.extractOne(item, list(mapping.keys()), scorer=fuzz.ratio) if mapping else None
        
        if match and match[1] >= threshold:
            existing_key = match[0]
            canonical_key = mapping[existing_key]
            
            if len(item) < len(canonical_key):
                for k in list(mapping.keys()):
                    if mapping[k] == canonical_key:
                        mapping[k] = item
                mapping[item] = item
            else:
                mapping[item] = canonical_key
        else:
            mapping[item] = item

    for item, freq in counts.items():
        canonical_key = mapping[item]
        grouped[canonical_key] = grouped.get(canonical_key, 0) + freq 
    
    top_suggestions = sorted(grouped, key=grouped.get, reverse=True)[:limit]
    
    return top_suggestions
