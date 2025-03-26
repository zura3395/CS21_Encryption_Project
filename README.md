# X64 File Encryption/Decryption Tool

A command-line tool written in x86-64 assembly that provides simple XOR encryption and decryption for files. This project was completed as part of Bill Komanetsky's Spring 2023 CS21 Computer Organization and Assembly Language Programming at Las Positas College.

## Overview

This program copies the contents of a source file to a destination file while applying XOR encryption/decryption with a user-specified key. The encryption is symmetric, meaning the same process can be used to both encrypt and decrypt files.

## Features

- File-to-file encryption/decryption using XOR cipher
- User-defined encryption key
- Dynamic memory allocation for handling large files
- Error handling for common issues (missing arguments, file access problems)
- Command-line interface

## Requirements

- Linux x86-64 system
- NASM (Netwide Assembler)
- GNU linker (ld)

## Usage

The repo includes a pre-compiled binary as part of the project submission and can be used after adding execute permissions to the binary.

```bash
chmod +x ./main
./main inputfile outputfile
```

Where:

- `inputfile` is the source file to be encrypted/decrypted
- `outputfile` is the destination for the encrypted/decrypted content
After launching, the program will prompt you to enter an encryption key.

## Building from Source

Clone the repository and use the included makefile to build the executable:

```bash
git clone https://github.com/zura3395/CS21_Encryption_Project.git
cd CS21_Encryption_Project_X64
sudo apt update
sudo apt install nasm
make
```

To clean up build files:

```bash
make clean
```

## How It Works

The program:

1. Opens the source file in read-only mode
2. Creates or opens the destination file in write mode
3. Prompts for an encryption key
4. Allocates a memory buffer
5. Reads data from the source file in chunks
6. Applies XOR encryption using the provided key
7. Writes the encrypted/decrypted data to the destination file
8. Repeats until the entire file is processed

## XOR Encryption

The implementation uses a simple XOR cipher where each byte of the input is XORed with a byte from the encryption key. When the end of the key is reached, it loops back to the beginning.

## Error Handling

The program detects and reports various error conditions:

- Missing command-line arguments
- Too many command-line arguments
- Failure to open input or output files
- Memory allocation failures
- Empty encryption key
