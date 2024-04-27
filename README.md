# NOS_Assignment

## Important

**Do not** edit then content of the following unless instructed too: 
- `setup/`
- _Directory/  (Once it has been created, see Instructions)

## Instructions

The first thing you need to do is create the content needed for the assignment that deals with running checks on file storage. 

Run the command below to build the directory investigation part of the assignment :

```sh
$ bash setup/buildAssignment 
```

If by some mistake you delete, move or replace any of the content in `_Directory` you can run the bash script as follows:

```sh
$ bash setup/buildAssignment 
```

### _Directory

The `_Directory` folder will not be tacked by default. 

This is where you need to point your solution to analyse the contents as part of your assessment.

## Your Tasks

**Summary** 

1. ~~Develop as bash ultilty script in current directory that:~~
  - ~~Can generate two different versions of UUID{1,2,3,4,5} without the use of built-in UUID generators:~~
    - ~~Should be able to save to file AND print to terminal.~~
    - ~~Check if previous UUID exists and see if collision~~
    - ~~Check when last UUID was generated~~
  - ~~Categorise content in `_Directory`:~~
    - ~~For each child directory report how many of each file type there are and collective size of each file type~~
    - ~~For each child directory specify total space used, in human readable format~~
    - ~~For each child directory report find shortest and largest length of file name~~
    - ~~Output results to file AND option to return to terminal~~
  - ~~For all functionality~~
    - ~~there should be an argument~~ 
    - ~~can run functionality per argument(s)~~
    - ~~Must be able to record who has logged into system and when, and which script commands have been supplied appended to a log file.~~
2. ~~Build a simple `man` page for your script~~
  -  ~~ensure you have compressed the document and named it with the correct `man` identifier.~~
3. ~~Throughout ensure you have reference to the PID of your script and PID of any sub commands run!##
4. ~~You are encouraged to develop your solutions in a branch off of `main` and make merges where appropriate. **No** penalisation for developing in `main`.~~

# Additional Commands & Tools

## Bash Shell

- Add executable permission to a bash script: 
```sh
$ chmod +x [script_name].sh
```
- Add write permission to a bash script
```sh
$ chmod +w [script_name].sh
```
- Execute bash script: 
```sh
$ ./[script_name].sh [command] [args]
```

## MAN Page

- Copy MAN script into correct file:
```sh
$ sudo cp utilities.1.gz /usr/share/man/man1/
```
- Remove an old MAN page
```sh
$ sudo rm /usr/share/man/man1/utilities.1.gz
```
- Update MAN page index:
```sh
$ sudo mandb
```
- Compress MAN page with GZIP
```sh
$ gzip < utilities.1 > utilities.1.gz
```
- Open / Test MAN Page
```sh
$ man -l utilities.1.gz
```

## SSH Connection to GitHub

- Install Git:
```sh
$ sudo apt update
$ sudo apt install git
```
- Configure Git Credentials:
```sh
$ git config --global user.name "Your GitHub Username"
$ git config --global user.email "your_email@example.com"
```
- Check for Existing SSH Keys
```sh
$ ls -al ~/.ssh
```
- Generate New SSH Key Pair
```sh
$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```
- Add SSH Key Pair to SSH Agent
```sh
$ eval "$(ssh-agent -s)"
$ ssh-add ~/.ssh/id_rsa
```
- Copy SSH Public Key
```sh
$ cat ~/.ssh/id_rsa.pub | clip
```
