# x86-File-Allocation-System

## Description

This project implements a simplified file allocation system, inspired by how operating systems manage storage on disk devices (HDD/SSD).

The system models a block-based storage device and simulates file allocation using contiguous memory blocks. Each file is identified by a unique descriptor and occupies a sequence of consecutive blocks, mimicking low-level storage behavior.

The following core operations are supported:

- **ADD** – allocates space for one or more files by finding the first suitable contiguous region of free blocks  
- **GET** – retrieves the interval of blocks associated with a given file descriptor  
- **DELETE** – frees the blocks occupied by a file, making them available for future allocations  
- **DEFRAGMENTATION** – reorganizes the storage by compacting files towards the beginning, eliminating fragmentation and improving space utilization  

The implementation focuses on:

- contiguous allocation strategies  
- efficient reuse of freed space  
- handling fragmentation and memory compaction  

The system operates on a simplified representation of storage, where each block holds a single file identifier, allowing easy visualization of allocation and fragmentation behavior.

The project is written entirely in **x86 assembly**, emphasizing low-level programming concepts such as:

- manual memory management  
- data representation at byte level  
- control over execution flow and performance  


## Project Structure
```text
.
├── src/
├── tests/
├── checker.py
├── task1
├── task2
```

## Build and Run

Compile the sources:
```bash
gcc -m32 src/task1.s -o task1 -no-pie
gcc -m32 src/task2.s -o task2 -no-pie
```
Make executables runnable:
```bash
chmod +x task1 task2
```
### Run all tests:

```bash
python3 checker.py
```

### Run only task1 tests:

```bash
python3 checker.py task1
```

### Run only task2 tests:

```bash
python3 checker.py task2
```

## Notes

- `task1` implements the unidimensional memory model
- `task2` implements the bidimensional memory model
