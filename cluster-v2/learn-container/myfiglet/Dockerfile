# FROM indicates the base image for our build.
FROM ubuntu

## COPY
# the build context is the directory containing the Dockerfile.
# use COPY to place the source file into the container
# Docker can cache steps involving COPY.
# Those steps will not be executed again if the files haven't been changed.
# If we really wanted to compile C code in a container, we would:
# place it in a different directory, with the WORKDIR instruction
COPY hello.c /

# Each RUN line will be executed by Docker during the build.
# Our RUN commands must be non-interactive.
# (No input can be provided to Docker during the build.)
# In many cases, we will add the -y flag to apt-get.
# Dockerfile commands that execute something can have two forms:

# plain string, or shell syntax:
# RUN apt-get install figlet

# JSON list, or exec syntax:
# RUN ["apt-get", "install", "figlet"]
# shell syntax:
# is easier to write
# interpolates environment variables and other shell expressions
# creates an extra process (/bin/sh -c ...) to parse the string
# requires /bin/sh to exist in the container

# exec syntax:
# is harder to write (and read!)
# passes all arguments without extra processing
# doesn't create an extra process
# doesn't require /bin/sh to exist in the container
RUN apt-get update -y
RUN apt-get install figlet -y
# CMD /hello (could be used to run the application)
RUN make hello

# CMD and ENTRYPOINT.
# These commands allow us to set the default command to run in a container.
# When people run our container, we want to greet them with a nice hello message, and using a custom font.
# For that, we will execute:
# figlet -f script hello

# -f script tells figlet to use a fancy font.
# hello is the message that we want it to display.
# CMD defines a default command to run when none is given.

# It can appear at any point in the file.
# Each CMD will replace and override the previous one.
# As a result, while you can have multiple CMD lines, it is useless.
CMD figlet -f script hello

# If we want to get a shell into our container (instead of running figlet), we just have to specify a different program to run:
# $ docker run -it figlet bash
# root@7ac86a641116:/#
# We specified bash.
# It replaced the value of CMD.

# Using ENTRYPOINT
# We want to be able to specify a different message on the command line, while retaining figlet and some default parameters.
# We will use the ENTRYPOINT verb, In other words, we would like to be able to do this:
# docker run figlet salut

# When CMD or ENTRYPOINT use string syntax, they get wrapped in sh -c.
# To avoid this wrapping, we can use JSON syntax.
# What if we used ENTRYPOINT with string syntax?
# $ docker run figlet salut
# This would run the command in the figlet image:
# sh -c "figlet -f script" salut

# CMD and ENTRYPOINT together
# ENTRYPOINT defines a base command (and its parameters) for the container.
# If we don't specify extra command-line arguments when starting the container, the value of CMD is appended.
# Otherwise, our extra command-line arguments are used instead of CMD.
# They both have to use JSON syntax.
# ENTRYPOINT ["figlet", "-f", "script"]
# CMD ["hello world"]

## Overriding ENTRYPOINT
# What if we want to run a shell in our container?
# We cannot just do docker run myfiglet bash because that would just tell figlet to display the word "bash."
# We use the --entrypoint parameter:
# $ docker run -it --entrypoint bash myfiglet

ENTRYPOINT [ "figlet", "-f", "script" ]
