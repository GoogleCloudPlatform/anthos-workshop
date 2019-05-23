FROM golang as builder

LABEL maintainer="Alex Mattson <alexmattson@google.com>"

# Copy local code to the container image.
WORKDIR /app
COPY main.go go.mod ./

RUN go get -u cloud.google.com/go/vision/apiv1
RUN go get -u cloud.google.com/go/storage
RUN CGO_ENABLED=0 GOOS=linux go build -v -o main

# Use a Docker multi-stage build to create a lean production image.
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM alpine

# Copy the binary to the production image from the builder stage.
COPY --from=builder /app/main .

# Service must listen to $PORT environment variable.
# This default value facilitates local development.
ENV PORT 8080
EXPOSE 8080

RUN adduser -S -D -H -h /app appuser
RUN mkdir -p /vision_scratch
RUN chown -R appuser /vision_scratch
USER appuser
CMD ["./main"]