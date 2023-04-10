# Recursively merges dictionaries from the source into the destination
def deepmerge(destination: dict, source: dict) -> dict:
    for key, value in source.items():
        if isinstance(value, dict):
            node = destination.setdefault(key, {})
            deepmerge(node, value)
        else:
            destination[key] = value

    return destination

# Slices specific keys from the given dictionary, if present
def slice_only(dictionary: dict, keys: set) -> dict:
    return {key: dictionary[key] for key in keys if key in dictionary}
