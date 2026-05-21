import os

src_path = 'c:/Users/Dell/Documents/App/website/baronclub/storage/app/public/merchant-cards/c54bd3e6-6717-43f8-ac89-dca179d7fca4.jpg'
dest_path = 'c:/Users/Dell/Documents/App/website/baronclub/public/storage/merchant-cards/c54bd3e6-6717-43f8-ac89-dca179d7fca4.jpg'

print("Source path exists:", os.path.exists(src_path))
print("Destination path exists:", os.path.exists(dest_path))

link_path = 'c:/Users/Dell/Documents/App/website/baronclub/public/storage'
print("Is link_path a symlink/junction:", os.path.islink(link_path))
if os.path.exists(link_path):
    print("Files under public/storage/merchant-cards:")
    cards_path = os.path.join(link_path, 'merchant-cards')
    if os.path.exists(cards_path):
        print(os.listdir(cards_path))
    else:
        print("public/storage/merchant-cards folder does not exist!")
else:
    print("public/storage link_path itself does not exist!")
