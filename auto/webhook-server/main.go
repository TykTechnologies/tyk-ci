package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"sync"
)

const root = "root"

type WebhookRequest struct {
	Headers map[string][]string `json:"headers"`
	Body    json.RawMessage     `json:"body"`
}

var (
	receivedRequests = make(map[string][]WebhookRequest)
	mutex            sync.Mutex
	idPattern        = regexp.MustCompile(`^/webhook/(\d+)$`)
	requestPattern   = regexp.MustCompile(`^/requests/(\d+)$`)
)

func webhookHandler(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "couldn't read body", http.StatusBadRequest)
		return
	}

	matches := idPattern.FindStringSubmatch(r.URL.Path)
	id := root
	if len(matches) >= 2 {
		id = matches[1]
	}

	request := WebhookRequest{
		Headers: r.Header,
		Body:    body,
	}

	mutex.Lock()
	receivedRequests[id] = append(receivedRequests[id], request)
	mutex.Unlock()

	w.WriteHeader(http.StatusOK)
}

func requestsHandler(w http.ResponseWriter, r *http.Request) {
	matches := requestPattern.FindStringSubmatch(r.URL.Path)
	id := root
	if len(matches) >= 2 {
		id = matches[1]
	}

	log.Println("id =", id)

	mutex.Lock()
	defer mutex.Unlock()

	requests, exists := receivedRequests[id]
	if !exists {
		http.Error(w, "No requests found for the given ID", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(requests)
}

func main() {
	http.HandleFunc("/webhook/", webhookHandler)
	http.HandleFunc("/requests/", requestsHandler)

	fmt.Println("Starting server on :9003")
	if err := http.ListenAndServe(":9003", nil); err != nil {
		log.Fatalf("Could not start server: %s\n", err)
	}
}
