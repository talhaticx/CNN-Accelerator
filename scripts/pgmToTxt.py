from PIL import Image
import numpy as np

# Load PGM image
img = Image.open("img.pgm")  # Remove extra `/` from the path
arr = np.array(img).astype(np.uint8)  # Convert to signed 8-bit

# Save 128x128 data to text file
with open("ifmap.txt", "w") as f:
    for row in arr:
        f.write(" ".join(str(v) for v in row) + "\n")
