package main

import (
	"fmt"
	"log"
	"net/http"
)

func handleBasicRequest(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello!")
}

func main() {
	http.HandleFunc("/", handleBasicRequest)

	fmt.Printf("Starting server at port 8080\n")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
