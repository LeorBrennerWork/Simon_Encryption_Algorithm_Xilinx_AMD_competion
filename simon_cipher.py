import serial
import binascii
import math
import tkinter as tk
from tkinter import *
from tkinter import messagebox
import tkinter.font as font

def get_cphrtxt():
    global cphrtxt
    cphrtxt.set(encrypt(key_encrypt.get(),plaintext.get()))
    return 

def get_plntxt():
    global plntxt
    plntxt.set(decrypt(key_decrypt.get(),ciphertext.get()))
    return 












def encrypt(key,internal_plntxt):
    # Open serial connection to Basys3
    ser = serial.Serial(port='COM4', baudrate=9600, parity=serial.PARITY_NONE, timeout=1)

    # Receive key and convert into bytes
    padded_key = key.zfill(8)
    if len(padded_key) != 8:
        messagebox.showerror("Error", "Key cannot be more than 8 characters. Please input a new key.")
        return ''
    encoded_padded_key = padded_key.encode('utf-8')

    # Receive plaintext, divide it into byte sized strings, convert into bytes
    internal_plntxt_list = []
    z_fill_to =  math.ceil(len(internal_plntxt)/4)*4 # left fill plaintext with zeros so plaintext is divisible by 4
    internal_plntxt = internal_plntxt.zfill(z_fill_to)
    for i in range(0,len(internal_plntxt),4):
        internal_plntxt_list.append(internal_plntxt[i:i+4])

    if internal_plntxt_list == []:
        messagebox.showinfo("Information", "Please enter Plaintext to encrypt.")
        return ''
    #internal_plntxt_list[-1] = internal_plntxt_list[-1].zfill(4)
    encoded_bytes_list = []
    for single_internal_plntxt in internal_plntxt_list:
        encoded_bytes_list.append(single_internal_plntxt.encode('utf-8'))


    # Input all parts of the plaintext with the same key
    i = 0
    for i in range(len(encoded_bytes_list)):
        ser.write(b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00")
        ser.write(b'\x30') #encryption mode
        ser.write(encoded_padded_key)
        ser.write(encoded_bytes_list[i])

    # Capture final internal_cphrtxt by appending the individual internal_cphrtxts that have been received
    final_internal_cphrtxt = b""
    i=0
    while i<len(internal_plntxt_list)*2:
        unencoded_internal_cphrtxt = ser.read(4)
        if i%2:
            final_internal_cphrtxt += unencoded_internal_cphrtxt
        i+=1

    # Convert internal_cphrtxt to utf-8 characters
    final_internal_cphrtxt = binascii.b2a_hex(final_internal_cphrtxt)
    final_internal_cphrtxt = final_internal_cphrtxt.decode('utf-8')
    print(final_internal_cphrtxt)
    return final_internal_cphrtxt







    
def decrypt(key,internal_cphrtxt):
    # Open serial connection to Basys3
    ser = serial.Serial(port='COM4', baudrate=9600, parity=serial.PARITY_NONE, timeout=1)

    # Receive key and convert into bytes
    padded_key = key.zfill(8)
    if len(padded_key) != 8:
        messagebox.showerror("Error", "Key cannot be more than 8 characters. Please input a new key.")
        return ''
    encoded_padded_key = padded_key.encode('utf-8')

    # Receive plaintext, divide it into byte sized strings, convert into bytes
    internal_cphrtxt_list = []
    for i in range(0,len(internal_cphrtxt),8): #jumping by 8 because every 2 characters will turn into 1 hex byte
        internal_cphrtxt_list.append(internal_cphrtxt[i:i+8])

    if internal_cphrtxt_list == []:
        messagebox.showinfo("Information", "Please enter Ciphertext to decrypt.")
        return ''
    internal_cphrtxt_list[-1] = internal_cphrtxt_list[-1].zfill(8)
    encoded_bytes_list = []
    for single_internal_cphrtxt in internal_cphrtxt_list:
        encoded_bytes_list.append(binascii.unhexlify(single_internal_cphrtxt))

    final_internal_plntxt = b""
    # Input all parts of the plaintext with the same key
    i = 0
    for i in range(len(encoded_bytes_list)):
        ser.write(b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00")
        unencoded_internal_plntxt = ser.read(4)
        print(unencoded_internal_plntxt)
        print(i)
        ser.write(b"\x31") #decryption mode
        ser.write(encoded_padded_key)
        ser.write(encoded_bytes_list[i])
        unencoded_internal_plntxt = ser.read(4)
        print(unencoded_internal_plntxt)
        print(i)
        final_internal_plntxt += unencoded_internal_plntxt


    # Capture final internal_plntxt by appending the individual internal_plntxts that have been received
    
    # i=0
    # for i in range(len(internal_cphrtxt_list)*2):
    #     unencoded_internal_plntxt = ser.read(4)
    #     print(unencoded_internal_plntxt)
    #     print(i)
    #     if i%2:
            
    #         final_internal_plntxt += unencoded_internal_plntxt
            

    # Convert internal_plntxt to utf-8 characters
    print(final_internal_plntxt)
    return final_internal_plntxt










# Encryption window
def get_cphrtxt_window():
    global cphrtxt
    encrypt_window = Toplevel(ed_screen)
    cphrtxt = StringVar()
    encrypt_window.title("Simon 32/64 Encryption")

    w = 700
    h = 130
    ws = encrypt_window.winfo_screenwidth() # width of the screen
    hs = encrypt_window.winfo_screenheight() # height of the screen
    x = (ws/2) - (w)
    y = (hs/2) - (h/2)
    # set the dimensions of the screen 
    # and where it is placed
    encrypt_window.geometry('%dx%d+%d+%d' % (w, h, x, y))

    Label(encrypt_window, text='Enter Key',font=('Arial',18)).grid(row=0,padx=50)
    Label(encrypt_window, text='Enter Plaintext',font=('Arial',18)).grid(row=1)
    Label(encrypt_window, text='Ciphertext',font=('Arial',18)).grid(row=2)
    global key_encrypt
    global plaintext
    key_encrypt = Entry(encrypt_window, font=('Arial',24))
    plaintext = Entry(encrypt_window, font=('Arial',24))
    key_encrypt.grid(row=0, column=1)
    plaintext.grid(row=1, column=1, padx=30)
    submit_plaintext = Button(encrypt_window, text = "Encrypt", fg = "Black", command = get_cphrtxt)
    submit_plaintext.place(x=625,y=27)
    e3 = Label(encrypt_window, textvariable=str(cphrtxt), font=('Arial',24)).grid(row=2,column=1,padx=29,sticky='w')

    return







# Decryption window
def get_plntxt_window():
    global plntxt
    decrypt_window = Toplevel(ed_screen)
    plntxt = StringVar()
    decrypt_window.title("Simon 32/64 Decryption")

    w = 700
    h = 130
    ws = decrypt_window.winfo_screenwidth() # width of the screen
    hs = decrypt_window.winfo_screenheight() # height of the screen
    x = (ws/2) 
    y = (hs/2) - (h/2)
    # set the dimensions of the screen 
    # and where it is placed
    decrypt_window.geometry('%dx%d+%d+%d' % (w, h, x, y))

    Label(decrypt_window, text='Enter Key',font=('Arial',18)).grid(row=0,padx=50)
    Label(decrypt_window, text='Enter Ciphertext',font=('Arial',18)).grid(row=1)
    Label(decrypt_window, text='Plaintext',font=('Arial',18)).grid(row=2)
    global key_decrypt
    global ciphertext
    key_decrypt = Entry(decrypt_window,font=('Arial',24))
    ciphertext = Entry(decrypt_window,font=('Arial',24))
    key_decrypt.grid(row=0, column=1)
    ciphertext.grid(row=1, column=1, padx=30)
    submit_plaintext = Button(decrypt_window, text = "Decrypt", fg = "Black", command = get_plntxt)
    submit_plaintext.place(x=625,y=27)
    e6 = Label(decrypt_window, textvariable=str(plntxt), font=('Arial',24)).grid(row=2,column=1,padx=29,sticky='w')
    return







if __name__ == "__main__":
#at end change w into interface
    ed_screen = tk.Tk()
    ed_screen.title("Simon 32/64. Please choose encryption or decryption")
    w = 1000
    h = 500
    ws = ed_screen.winfo_screenwidth() # width of the screen
    hs = ed_screen.winfo_screenheight() # height of the screen
    x = (ws/2) - (w/2)
    y = (hs/2) - (h/2)
    # set the dimensions of the screen 
    # and where it is placed
    ed_screen.geometry('%dx%d+%d+%d' % (w, h, x, y))
    myFont = font.Font(size=15)
    encrypt_button = Button(ed_screen, text = "Encrypt", fg = "Black", background="green", command = get_cphrtxt_window,height=10,width=25)
    decrypt_button = Button(ed_screen, text = "Decrypt", fg = "Black", background="red", command = get_plntxt_window,height=10,width=25)
    encrypt_button['font'] = myFont
    decrypt_button['font'] = myFont
    encrypt_button.place(x=150,y=h/4)
    decrypt_button.place(x=550,y=h/4)

    ed_screen.mainloop()
    