from PIL import Image
import numpy as np

def txt_to_png(txt_file, png_file, width, height):
    with open(txt_file, 'r') as f:
        data = [int(x) for line in f for x in line.strip().split()]
    
    assert len(data) == width * height
    array = np.array(data, dtype=np.uint8).reshape((height, width))
    img = Image.fromarray(array, mode='L')  # 'L' = 8-bit grayscale
    img.save(png_file)

# Example usage:
txt_to_png('ofmap.txt', 'ofmap.png', 126, 126)
