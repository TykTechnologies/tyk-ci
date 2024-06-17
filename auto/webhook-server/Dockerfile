# Use the official Golang image as the build stage
FROM golang:alpine as builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the source code into the container
COPY . .

# Build the Go app
RUN go build -o webhook .

# Expose port 9003 to the outside world
EXPOSE 9003

# Command to run the executable
CMD ["./webhook"]
