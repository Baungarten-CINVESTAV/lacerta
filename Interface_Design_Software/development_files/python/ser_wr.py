# Definitions #
from PIL import Image

import serial
import numpy as np
import struct
import time
from random import randint
import serial.tools.list_ports

# Get a list of available COM ports
ports = [port.device for port in serial.tools.list_ports.comports()]
print(ports)
#time.sleep(5)
try:
	ser = serial.Serial(port=ports[0],baudrate=230400,timeout=1)
	print("Succesfully connected to uart slave")
except:
	print("Could not connect to uart slave")

def write_mem(addr,data):
	COMMAND = 1
	v = struct.pack('B', COMMAND)
	ser.write(v)
	v = struct.pack('B',addr)
	ser.write(v)
	v = struct.pack('I',data)
	ser.write(v)
	print("wrote " + "{:08X}".format(data) )

def read_mem(addr):
	COMMAND = 0
	v = struct.pack('B', COMMAND)
	ser.write(v)
	v = struct.pack('B',addr)
	ser.write(v)
	v = struct.pack('I',0)
	ser.write(v)
	while(ser.in_waiting < 4):()
	val = ser.read(4)
	data_received = int.from_bytes(val, "little")
	print("read {:08X}".format(data_received))

#exit()

def read_character_by_character(filename):
    array_int = []
    with open(filename, 'r') as f:
        # Read the entire file content into a string
        content = f.read().replace('\n', '').replace('\r', '')
        for char in content:
            # Process each character
#            print(char, end='')
            array_int.append(int(char))
    return array_int

#time.sleep(2)

#default_array = read_character_by_character("../donotchange/37_66_7seg_default.txt")
default_array = read_character_by_character("../donotchange/37_66_7seg_0.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_1.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_2.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_3.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_4.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_5.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_6.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_7.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_8.txt")
default_array = default_array + read_character_by_character("../donotchange/37_66_7seg_9.txt")
print(np.size(default_array))
#for val in default_array:
#    print(val)

def refresh_digit(value = 0):
    write_mem(0x0C, 4) # Object type 7seg mask
    write_mem(0x0D, 37) # Object width
    write_mem(0x0E, 66) # Object height
    write_mem(0x0F, 640*240+500) # Object starting address
    write_mem(0x10, 640*480+value*37*66) # Object starting masking address
    time.sleep(0.1)
    write_mem(0x0B, 0) # for 7seg, value don't care for now

def refresh_graph(value = 0):
    write_mem(0x0C, 3) # Object type 7seg mask
    write_mem(0x0D, 50) # Object width
    write_mem(0x0E, 150) # Object height
    write_mem(0x0F, 640*150+200) # Object starting address
    write_mem(0x10, 0xFFFFFFFF) # Object starting masking address
    write_mem(0x0B, value) # value 

def refresh_vertical(value = 0):
    write_mem(0x0C, 2) # Object type 7seg mask
    write_mem(0x0D, 20) # Object width
    write_mem(0x0E, 100) # Object height
    write_mem(0x0F, 640*460+500) # Object starting address
    write_mem(0x10, 0xFFFFFFFF) # Object starting masking address
    write_mem(0x0B, value) # value

def refresh_horizontal(value = 0):
    write_mem(0x0C, 1) # Object type 7seg mask
    write_mem(0x0D, 100) # Object width
    write_mem(0x0E, 20) # Object height
    write_mem(0x0F, 640*50+500) # Object starting address
    write_mem(0x10, 0xFFFFFFFF) # Object starting masking address
    write_mem(0x0B, value) # value


write_mem(0x00, 0x0004B000) # set wpg starting address to 640x480
write_mem(0x01, np.size(default_array)) # set wpg burst length to 640x480
write_mem(0x02, 0x00000000) # set wpg busy to 1
for val in default_array:
    write_mem(0x06, val) # write mask to writing buffer

while True:
#for i in range(0,100):
    #refresh_digit(randint(0,9)) # lacerta is freezing when using 7seg, need to check
    #time.sleep(0.5)
    refresh_graph(randint(0,30))
    time.sleep(0.01)
    refresh_vertical(randint(0,100))
    time.sleep(0.01)
    refresh_horizontal(randint(0,100))
    time.sleep(0.01)

exit()

#exit()

#write_mem(0x10, 640*480+9*37*66) # Object starting masking address
#write_mem(0x0B, 0) # for 7seg, value don't care for now
#
#exit()

cnt = 0
for i in range(0,20):
    write_mem(0x10, 640*480+cnt*37*66) # Object starting masking address
    write_mem(0x0B, 0) # for 7seg, value don't care for now
    cnt = cnt + 1
    if(cnt == 10):
        cnt = 0
    time.sleep(1)

exit()

#while True:
for i in range(0,1):
    write_mem(0x0B, randint(0,50))
    time.sleep(0.1)
#for x in range(0,1):
#    for i in range(0,50):
#        write_mem(0x0B, i) # start drawing incremental
#        time.sleep(0.1)
#    for i in range(0,50):
#        write_mem(0x0B, 50-i) # start drawing incremental
#        time.sleep(0.1)

#image_path = 'image.jpg'
#file_path = 'image.bin'
#with Image.open(image_path) as img:
#    # Ensure the image is in RGB mode (some formats like GIF use a palette)
#    rgb_img = img.convert('RGB')
#    gray_img = img.convert('L')
#    with open(file_path, 'w') as f:
#        for y in range(0,480):
#            for x in range(0,640):
#                r, g, b = rgb_img.getpixel((x, y))
#                gray = gray_img.getpixel((x,y))
#                write_mem(0x06, gray>>3) # write gray pixel value to writing buffer
#                gray_binary = f"{gray>>3:0{5}b}"
#                f.write(gray_binary + '\n')
#                #print(f"gray values at ({x}, {y}): gray={gray_binary}")
#                print(f"RGB values at ({x}, {y}): R={r}, G={g}, B={b}")

#for i in range(0,640*480):
#    write_mem(0x06, 0xFFFFFFFF) # set wpg busy to 1

#COMMAND = 1
#v = struct.pack('B', COMMAND)
#ser.write(v)

#addr = 15
#v = struct.pack('B',addr)
#ser.write(v)

#data = 0xCB2A0953
#v = struct.pack('I',data)
#ser.write(v)


#write_mem(0xF8, 0xCB2A0921)
#read_mem(0xF8)

#for i in range(0,10): # Do 10 random data writes to address 0-9
#	write_mem(i,randint(0,100))
#for i in range(0,10): # Do 10 reads to address 0-9
#	read_mem(i)

## resize image to 640x480
#image_path = 'image2_1920x1080.jpg'
#img = Image.open(image_path)
#print(f"Original size: {img.size}") # Output: Original size: (width, height)
#new_size = (640, 480)
#resized_img = img.resize(new_size, Image.Resampling.LANCZOS) # Use a high-quality resampling filter
#print(f"Resized size: {resized_img.size}")
#resized_img.save('image2.jpg')

#image_path = 'image.jpg'
#file_path = 'image.bin'
#with Image.open(image_path) as img:
#    # Ensure the image is in RGB mode (some formats like GIF use a palette)
#    rgb_img = img.convert('RGB')
#    gray_img = img.convert('L')
#    with open(file_path, 'w') as f:
#        for y in range(0,480):
#            for x in range(0,640):
#                r, g, b = rgb_img.getpixel((x, y))
#                gray = gray_img.getpixel((x,y))
#                gray_binary = f"{gray>>3:0{5}b}"
#                f.write(gray_binary + '\n')
#                print(f"gray values at ({x}, {y}): gray={gray_binary}")
##                print(f"RGB values at ({x}, {y}): R={r}, G={g}, B={b}")
