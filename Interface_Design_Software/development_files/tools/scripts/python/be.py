#!/usr/bin/env python3

import sys

if len(sys.argv) != 3:
    print("Usage: python convert_to_big_endian.py input.mem output.mem")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# Read bytes
with open(input_file, "r") as f:
    bytes_list = [line.strip() for line in f if line.strip()]

# Validate byte format
for b in bytes_list:
    if len(b) != 2:
        raise ValueError(f"Invalid byte format: {b}")

# Ensure multiple of 4 bytes
if len(bytes_list) % 4 != 0:
    raise ValueError("Input length is not multiple of 4 bytes")

# Convert to big endian per 32-bit word
big_endian_bytes = []

for i in range(0, len(bytes_list), 4):
    word = bytes_list[i:i+4]
    big_endian_bytes.extend(reversed(word))

# Write output
with open(output_file, "w") as f:
    for b in big_endian_bytes:
        f.write(b.upper() + "\n")

print(f"Converted {len(bytes_list)//4} words to big-endian format.")
