from PIL import Image

def image_to_grayscale_txt(input_path, output_path):
    try:
        img = Image.open(input_path).convert('L')
        pixels = list(img.getdata())
        with open(output_path, 'w') as f:
            for pixel in pixels:
                f.write(f"{pixel}\n")
        print(f"Success! Grayscale values saved to {output_path}")
        print(f"Total pixels processed: {len(pixels)}")

    except Exception as e:
        print(f"An error occurred: {e}")

image_to_grayscale_txt(r"C:\Users\91951\Desktop\Project_systolic\Icon_Einstein_256x256.png", 'pixels.txt')