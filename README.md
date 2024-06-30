# Simon_Encryption_Algorithm_Xilinx_AMD_competion

Team number: AOHW-116

Project name: Hardware Implementation of the Simon Encryption Algorithm

Link to YouTube Video(s): 

Link to project repository: https://github.com/LeorBrennerWork/Simon_Encryption_Algorithm_Xilinx_AMD_competion

 

University name: JCT - Jerusalem College of Technology

Participant(s): Leor Brenner

Email: leor@g.jct.ac.il

<copy above if necessary for each participant>

Supervisor name: Mr. Uri Stroh

Supervisor e-mail: stroh@jct.ac.il

 

Board used: Basys 3 by Digilent Inc.

Software Version: Vivado 2023.2

Brief description of project: Implementation of the Simon Encryption Algorithm in VHDL on Artix-7 FPGA on the Basys3 board

 

Description of archive (explain directory structure, documents and source files):

All files are placed into corresponding folders:
Constraints folder contains the xdc file
Encryption Algorithm folder contains all files pertaining to the encryption algorithm itself
Python Code folder contains all python code used in the project
Reports and links folder contains the short project report and a link to the video
UART folder contains all files used for communication between the computer and the Basys3 board

Instructions to build and test project

Implementation to the Basys3:
1. Open a new Vivado project.
2. Add all files in the Encryption Algorithm and UART folders
3. Add xdc file from the Constraints folder
4. Run synthesis, implementation and generate bitstream
5. Connect the Basys3 to the computer using the micro usb port
6. Program the device

Computer:
1. Install the pySerial library on your computer using pip install pyserial
2. Run the python code (simon_cipher.py) in the Python Code folder
3. Enter key and plaintext in the application
4. Click "Encrypt"
5. Use the center button to reset the board

...
