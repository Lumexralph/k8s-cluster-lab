# syntax=docker/dockerfile:1
FROM golang:1.16 AS builder
WORKDIR /app/
COPY go.mod .
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hello .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/hello .
CMD [ "./hello" ]
