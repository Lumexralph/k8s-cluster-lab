# create a subdirectory called data, where your registry will store its images:

mkdir data

# ensure docker demon is running before running this command
docker version

# start the local registry
docker-compose up

# Tag the image as localhost:5000/my-ubuntu. This creates an additional tag for the existing image. When the first part of the tag is a hostname and port, Docker interprets this as the location of a registry, when pushing.
localhost:5000/<image-name>

