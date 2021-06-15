# At any point in our Dockerfile, we can add a new FROM line.
# This line starts a new stage of our build.
# Each stage can access the files of the previous stages with COPY --from=....
# When a build is tagged (with docker build -t ...), the last stage is tagged.
# Previous stages are not discarded: they will be used for caching, and can be referenced.

# Each stage is numbered, starting at 0
# We can copy a file from a previous stage by indicating its number, e.g.:
# COPY --from=0 /file/from/first/stage /location/in/current/stage
# We can also name stages, and reference these names:

# FROM golang AS builder
# RUN ...
#
# FROM alpine
# COPY --from=builder /go/bin/mylittlebinary /usr/local/bin/

# give a nickname to the first stage: compiler
FROM ubuntu AS compiler
RUN apt-get update
RUN apt-get install -y build-essential
COPY hello.c /
RUN make hello

# add a second stage using the same ubuntu base image
# We can achieve even smaller images if we use smaller base images.
FROM ubuntu

# add the hello binary to the second stage
COPY --from=compiler /hello /hello

# make sure that CMD is in the second stage
CMD /hello

# We can also tag an intermediary stage with the following command:
# docker build --target STAGE --tag NAME

