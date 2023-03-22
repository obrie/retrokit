# Recursively merges dictionaries from the source into the destination
def deepmerge(destination: dict, source: dict) -> dict:
    for key, value in source.items():
        if isinstance(value, dict):
            node = destination.setdefault(key, {})
            deepmerge(node, value)
        else:
            destination[key] = value

    return destination
