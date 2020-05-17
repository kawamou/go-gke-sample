FROM golang:1.12-alpine

RUN apk add --update --no-cache ca-certificates git

RUN mkdir /go-app
WORKDIR /go-app
COPY go.mod .
COPY go.sum .
COPY main.go .

RUN go mod download

RUN go build -o /app ./main.go

CMD ["/app"]