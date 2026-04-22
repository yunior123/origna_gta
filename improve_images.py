from PIL import Image, ImageEnhance
import os
import glob

# Ensure Pillow is installed, or try:
try:
    from PIL import ImageFilter
except ImportError:
    import sys
    sys.exit(0)

folder = 'extracted_images'
for img_path in glob.glob(f"{folder}/page1_img*.jpeg"):
    try:
        with Image.open(img_path) as img:
            img = img.convert('RGB')
            # Enhance color
            enhancer = ImageEnhance.Color(img)
            img = enhancer.enhance(1.2)
            # Enhance contrast
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(1.1)
            # Enhance sharpness
            enhancer = ImageEnhance.Sharpness(img)
            img = enhancer.enhance(2.0)
            
            out_name = img_path.replace('page1_img', 'solar_quote_img_improved_')
            img.save(out_name, "JPEG", quality=95)
            print(f"Improved {img_path} -> {out_name}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")
