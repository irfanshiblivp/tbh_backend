import os

laravel_storage = 'c:/Users/Dell/Documents/App/website/baronclub/storage/app/public'
print("Laravel storage exists:", os.path.exists(laravel_storage))
if os.path.exists(laravel_storage):
    print("\nFiles & directories under Laravel storage:")
    for root, dirs, files in os.walk(laravel_storage):
        level = root.replace(laravel_storage, '').count(os.sep)
        indent = ' ' * 4 * (level)
        print(f"{indent}{os.path.basename(root)}/")
        subindent = ' ' * 4 * (level + 1)
        for f in files[:5]: # print first 5 files
            print(f"{subindent}{f}")
