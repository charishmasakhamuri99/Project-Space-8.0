from PIL import Image

def txt_to_grayscale_image(input_path, output_path, width, height):
    try:
        with open(input_path, 'r') as f:
            
            pixels = [int(line.strip()) for line in f]
        if len(pixels) != width * height:
            print(f"Error: Pixel count ({len(pixels)}) does not match dimensions ({width}x{height}={width*height})")
            return

        img = Image.new('L', (width, height))
        img.putdata(pixels)
        img.save(output_path)
        print(f"Success! Image reconstructed and saved as {output_path}")

    except Exception as e:
        print(f"An error occurred: {e}")

txt_to_grayscale_image('pixels.txt', 'reconstructed_image.jpg', 256, 256)