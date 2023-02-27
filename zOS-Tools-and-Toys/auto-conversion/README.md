# Enable auto-conversion from within the application in z/OS UNIX

To run an ASCII application in z/OS UNIX, one has to enable auto-conversion in the shell environment in order to see readable output from the application. If you need to run ASCII application in a shell environment in which auto-conversion is disabled, the output will be garbled unless the application translates the output to EBCDIC.

This repository provides an example of how to build an ASCII application with auto-conversion enabled from within the application so it can produce readable output even if it is run in a shell environment with auto-conversion disabled.

Enabling auto-conversion from within an ASCII application can be done using `#pragma runopts` or using a Language Environment (LE) exit that allows setting LE environment from within the application.

Using an LE exist is a more generic approach as it works with C/C++ compilers that do not support `#pragma runopts`.

The repository contains two examples of building a simple ASCII application that enables auto-conversion from within the application using an LE exit approach. One example is for 32-bit and one for 64-bit applications. Both examples use the same C++ source but different assembler sources for 32-bit and 64-bit case.

The two examples produce output to the terminal which is always readable even if they are run in a shell environment in which auto-conversion is disabled. However, if the output is redirected into a file the file must be tagged with a desired code page. Assuming you want to redirect output to a file called `out`, you can do the following to prepare the file:

```shell
> touch out
> chtag -tc 819       # for ASCII encoding
> chtag -tc 1047      # for EBCDIC encoding
```

## Installation

This example is designed to be built and run in z/OS UNIX. The repository can be cloned directly to a z/OS system if you have access to GitHub from that system. This approach assumes that you have `git` and `bash` from Rocket Software installed and that auto-conversion is enabled in the shell environment. In this case all files are tagged with `ISO8859-1` code page so running `build.sh` provided in the repository requires that auto-conversion is enabled.

The alternative is to clone the repository to a workstation and transfer all files to the z/OS UNIX using `scp`. This approach does not require enabling auto-conversion as all files will be in EBCDIC after they are copied to z/OS UNIX.

To run these examples invoke `build.sh` from a build directory of your choice. Assuming you are in directory `repo` which contains a clone of this repository, you can do the following to build and run both examples.

```shell
> mkdir ../build
> cd ../build
> ../repo/build.sh
```

By default `build.sh` builds and runs both exmples, but if you pass argument `clean` it will remove all build output files from the build directory.
