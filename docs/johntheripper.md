# JohnTheRipper

This is a bunch of scripts to crack a bunch of different passwords offline

## Installation

```sh
git clone https://github.com/magnumripper/JohnTheRipper.git
cd JohnTheRipper/src
./configure && make
```

## Usage

### For pdfs

1. Create a hash of the pdf you want to open

	```sh
	cd JohnTheRipper/run
	./pdf2john.pl <pdf file> > <output file>
	```
	The output file will be a hash file of the meta info of the pdf.
	Will be refered to by hash-file from now on.

2. Crack the hash

	```sh
	cd JohnTheRipper/run
	./john <hash file>
	```
3. Retrieve the password

	```sh
	cd JohnTheRipper/run
	./john --show <hash file>
	```
	The password will be dispalyed the format of `<path-to-pdf>:password`
	```sh
	/root/user/secred.pdf:54321
	```
