FROM golang:alpine3.15 as builder
COPY ./go/main.go .
RUN go build -o myProgram main.go && chmod +x ./myProgram


FROM scratch
COPY --from=builder /go/myProgram myProgram
CMD [ "./myProgram" ]

