#!/usr/bin/env python3

import argparse
import sys
import os
import struct
import numpy as np


def parse_args():
    parser = argparse.ArgumentParser(
        description="Prepare RTL simulation input/reference files from an image."
    )
    parser.add_argument(
        "--input", "-i", required=True,
        help="Path to the input image file (PNG, BMP, JPEG, etc.)."
    )
    parser.add_argument(
        "--out-dir", "-o", default=".",
        help="Directory to write output .bin files (default: current directory)."
    )
    parser.add_argument(
        "--size", "-s", type=int, default=256,
        help="Output convolution size (default: 256). Input will be padded to size+2."
    )
    parser.add_argument(
        "--no-reference", action="store_true",
        help="Skip scipy reference generation (only write the raw input pixel file)."
    )
    return parser.parse_args()


def load_grayscale(path):
    try:
        from PIL import Image
    except ImportError:
        sys.exit("ERROR: Pillow is required.  Install with:  pip install Pillow")
    img = Image.open(path).convert("L")
    return np.array(img, dtype=np.uint8)


def zero_pad(gray, padded_size):
    h, w = gray.shape
    padded = np.zeros((padded_size, padded_size), dtype=np.uint8)
    copy_h = min(h, padded_size)
    copy_w = min(w, padded_size)
    padded[:copy_h, :copy_w] = gray[:copy_h, :copy_w]
    return padded


def write_bin(path, array):
    with open(path, "wb") as f:
        f.write(array.astype(np.uint8).tobytes())
    print(f"  Written: {path}  ({array.size} bytes)")


def generate_reference_gauss(padded, out_size):
    try:
        from scipy.ndimage import convolve
    except ImportError:
        sys.exit("ERROR: scipy is required.  Install with:  pip install scipy")

    kernel = np.array([[1, 2, 1],
                        [2, 4, 2],
                        [1, 2, 1]], dtype=np.float64)

    result = convolve(padded.astype(np.float64), kernel, mode="constant", cval=0.0)
    result = np.right_shift(result.astype(np.int32), 4)
    result = np.clip(result, 0, 255).astype(np.uint8)
    return result[1:out_size+1, 1:out_size+1]


def generate_reference_sobel(padded, out_size):
    try:
        from scipy.ndimage import convolve
    except ImportError:
        sys.exit("ERROR: scipy is required.  Install with:  pip install scipy")

    kernel = np.array([[-1, 0, 1],
                        [-2, 0, 2],
                        [-1, 0, 1]], dtype=np.float64)

    result = convolve(padded.astype(np.float64), kernel, mode="constant", cval=0.0)
    result = np.abs(result.astype(np.int32))
    result = np.clip(result, 0, 255).astype(np.uint8)
    return result[1:out_size+1, 1:out_size+1]


def main():
    args = parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    padded_size = args.size + 2

    print(f"Loading image: {args.input}")
    gray = load_grayscale(args.input)
    print(f"  Original size: {gray.shape[1]}x{gray.shape[0]}")

    padded = zero_pad(gray, padded_size)
    print(f"  Padded to: {padded_size}x{padded_size}")

    input_bin = os.path.join(args.out_dir, f"input_{padded_size}x{padded_size}.bin")
    write_bin(input_bin, padded)

    if not args.no_reference:
        print("Generating Gaussian blur reference...")
        gauss_ref = generate_reference_gauss(padded, args.size)
        write_bin(os.path.join(args.out_dir, "ref_output_gauss.bin"), gauss_ref)

        print("Generating Sobel-X reference...")
        sobel_ref = generate_reference_sobel(padded, args.size)
        write_bin(os.path.join(args.out_dir, "ref_output_sobel.bin"), sobel_ref)

    print("Done.")


if __name__ == "__main__":
    main()
