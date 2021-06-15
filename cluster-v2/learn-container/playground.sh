# Start an Ubuntu container in interactive mode:

docker run -it ubuntu

# Run the command apt-get update to refresh the list of packages available to install.
# Then run the command apt-get install figlet to install the program we are interested in.
apt-get update && apt-get install figlet

# Type exit at the container prompt to leave the interactive session.
exit

# Now let's run docker diff to see the difference between the base image and our container.
docker diff <Your ContainerID>

## Commit our changes to a new image
# The docker commit command will create a new layer with those changes, and a new image using this new layer.

docker commit <yourContainerId> # output: <newImageId>

# The output of the docker commit command will be the ID for your newly created image.
# We can use it as an argument to docker run.
docker run <newImageId>

## Testing our new image
# Let's run this image:
docker run -it <newImageId>

### Tagging images
# Referring to an image by its ID is not convenient. Let's tag it instead.
# We can use the tag command:
docker tag <newImageId> <tagName>

# But we can also specify the tag as an extra argument to commit:
docker commit <containerId> <tagName>

# And then run it using its tag:
docker run -it <tagName>