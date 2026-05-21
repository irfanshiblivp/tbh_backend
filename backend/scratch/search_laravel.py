import os

laravel_root = 'c:/Users/Dell/Documents/App/website/baronclub'
print("Laravel root exists:", os.path.exists(laravel_root))

matches = []
if os.path.exists(laravel_root):
    for root, dirs, files in os.walk(laravel_root):
        for f in files:
            if f.endswith('.blade.php') or f.endswith('.php'):
                path = os.path.join(root, f)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as file:
                        content = file.read()
                        if 'card_image' in content or 'logo' in content:
                            matches.append((path, f))
                except Exception:
                    pass

print(f"\nFound {len(matches)} files mentioning card_image or logo:")
for path, name in matches[:15]:
    print(f"  {name} in {os.path.dirname(path).replace(laravel_root, '')}")
    # Print some snippet if relevant
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as file:
            lines = file.readlines()
            for i, line in enumerate(lines):
                if 'card_image' in line or 'logo' in line:
                    print(f"    Line {i+1}: {line.strip()[:100]}")
    except Exception:
        pass
