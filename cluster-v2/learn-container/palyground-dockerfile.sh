## Type this into our Dockerfile...
# FROM indicates the base image for our build.
FROM ubuntu

# Each RUN line will be executed by Docker during the build.
# Our RUN commands must be non-interactive.
# (No input can be provided to Docker during the build.)
# In many cases, we will add the -y flag to apt-get.
RUN apt-get update
RUN apt-get install figlet

# Build it!
# Save our file, then execute:
# -t indicates the tag to apply to the image.
# . indicates the location of the build context.
docker build -t <tagName> .

# Using image and viewing history
# The history command lists all the layers composing an image.
# For each layer, it shows its creation time, size, and creation command.
# When an image was built with a Dockerfile, each layer corresponds to a line of the Dockerfile.
$ docker history <tagName>

# Why sh -c?
# On UNIX, to start a new program, we need two system calls:
fork() #, to create a new child process;
execve() #, to replace the new child process with the program to run.

# Conceptually, execve() works like this:
execve(program, [list, of, arguments])

# When we run a command, e.g. ls -l /tmp, something needs to parse the command.
# (i.e. split the program and its arguments into a list.)
# The shell is usually doing that.
/bin/sh -c #(nop)  CMD ["/bin/bash"]
bin/sh -c mkdir -p /run/systemd && echo 'do…
/bin/sh -c [ -z "$(apt-get indextargets)" ]
/bin/sh -c set -xe   && echo '#!/bin/sh' > /
/bin/sh -c #(nop) ADD file:5c44a80f547b7d68b…


# But we can also do the parsing jobs ourselves.
# This means passing RUN a list of arguments.
