from PIL import Image
import glob
import os

def make_transparent(image_path, output_path):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    # Tolerance for "white"
    threshold = 240
    for item in datas:
        # Check if pixel is close to white
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            new_data.append((255, 255, 255, 0)) # transparent
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

files = glob.glob("assets/sprites/cand_*.jpg")
for file in files:
    out_path = file.replace(".jpg", ".png")
    print(f"Converting {file} to {out_path}...")
    make_transparent(file, out_path)
print("Done!")
