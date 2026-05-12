import cv2
import numpy as np

def process_image(input_path, output_txt):
    # 1. Load the image in grayscale
    # If the image is 256x256, 'img' becomes a 2D numpy array
    img = cv2.imread(input_path, cv2.IMREAD_GRAYSCALE)
    
    if img is None:
        print("Error: Could not find or open the image.")
        return
    padded_img = np.pad(img, pad_width=1, mode='constant', constant_values=0)
    np.savetxt(output_txt, padded_img.flatten(), fmt='%d')
    
    print(f"Success! New dimensions: {padded_img.shape}")
    print(f"Pixel values saved to {output_txt}")

# Run the function
process_image(r"C:\Users\91951\Downloads\Icon_Einstein_256x256.png", 'pixels.txt')
