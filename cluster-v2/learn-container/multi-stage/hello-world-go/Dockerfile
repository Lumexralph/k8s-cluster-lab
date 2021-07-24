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

# FROM golang:1.16 AS builder
# WORKDIR /app/
# COPY go.mod go.sum /
# COPY . .
# RUN CGO_ENABLED=0 GOOS=linux go build -o recipe-stats .

# FROM alpine:latest as certs
# RUN apk --update add ca-certificates

# #FROM alpine:latest
# #RUN apk --no-cache add ca-certificates
# #WORKDIR /app
# #COPY --from=builder /app/recipe-stats .
# #ENTRYPOINT [ "recipe-stats" ]

# FROM scratch
# COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# COPY --from=builder /app/recipe-stats /
# ENTRYPOINT [ "./recipe-stats" ]

# -v /Users/olumideogundele/Downloads/hf_test_calculation_fixtures.json:/app/hf_test_calculation_fixtures.json
# docker run \
#     -v /Users/olumideogundele/Downloads/hf_test_calculation_fixtures.json:/hf_test_calculation_fixtures.json recipe-stats:v3 \
#     calcStats --file=hf_test_calculation_fixtures.json \
#     --postcode=10117 --from=7AM --to=7PM \
#     --keywords "cheese,Pasta, Mac, Apple" 

# go run main.go calcStats \
#     --file=/Users/olumideogundele/Downloads/hf_test_calculation_fixtures.json \
#     --postcode=10117 --from=7AM --to=7PM \
#     --keywords "cheese,Pasta, Mac, Apple"
