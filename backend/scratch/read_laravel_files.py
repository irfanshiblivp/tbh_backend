import os

def read_file(path):
    print(f"\n=== File: {path} ===")
    if os.path.exists(path):
        try:
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                print(f.read())
        except Exception as e:
            print("Error reading:", e)
    else:
        print("Path does not exist")

read_file('c:/Users/Dell/Documents/App/website/baronclub/app/Models/MerchantProfile.php')
read_file('c:/Users/Dell/Documents/App/website/baronclub/app/Http/Controllers/Admin/MerchantController.php')
