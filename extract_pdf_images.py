import fitz
import sys
import os

pdf_path = sys.argv[1]
out_dir = sys.argv[2]
os.makedirs(out_dir, exist_ok=True)

doc = fitz.open(pdf_path)
for page_index in range(len(doc)):
    page = doc[page_index]
    image_list = page.get_images(full=True)
    for image_index, img in enumerate(image_list, start=1):
        xref = img[0]
        base_image = doc.extract_image(xref)
        image_bytes = base_image["image"]
        image_ext = base_image["ext"]
        image_name = f"page{page_index+1}_img{image_index}.{image_ext}"
        image_path = os.path.join(out_dir, image_name)
        with open(image_path, "wb") as f:
            f.write(image_bytes)
        print(f"Extracted {image_path}")
