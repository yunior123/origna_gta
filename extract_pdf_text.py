import fitz
import sys

pdf_path = sys.argv[1]
doc = fitz.open(pdf_path)
for page_index in range(len(doc)):
    page = doc[page_index]
    text = page.get_text()
    print(f"--- PAGE {page_index+1} ---")
    print(text)
