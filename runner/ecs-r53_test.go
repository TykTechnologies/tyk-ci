package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/ecs"
	"github.com/aws/aws-sdk-go-v2/service/ecs/ecsiface"
)

func TestGetENI(t *testing.T) {
	cases := []struct {
		want      string
		returnErr bool
		name      string
	}{
		{
			returnErr: true,
			name:      "NullInput",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var task ecs.Task
			_, err := getENI(task)
			returnedErr := err != nil

			if returnedErr != tc.returnErr {
				t.Fatalf("Expected returnErr: %v, got: %v", tc.returnErr, returnedErr)
			}
		})
	}
}

type mockClient struct {
	ecsiface.ClientAPI
}

func (m *mockClient) DescribeTasksRequest(input *ecs.DescribeTasksInput) ecs.DescribeTasksRequest {
	f, err := ioutil.ReadFile("testdata/ecs-describe-tasks-bad.json")
	if err != nil {
		log.Fatalf("could not load fixture")
	}
	var output ecs.DescribeTasksOutput
	err = json.Unmarshal(f, &output)
	return ecs.DescribeTasksRequest{
		Request: &aws.Request{
			Data:  output,
			Error: err,
		},
		Input: input,
	}
}

func TestGetTaskDetail(t *testing.T) {
	cases := []struct {
		want      string
		returnErr bool
		name      string
		fixture   string
	}{
		{
			returnErr: true,
			name:      "BadJSON",
			fixture:   "testdata/ecs-describe-tasks-good.json",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			svc := &mockClient{}
			_, err := getTaskDetail(svc, "internal", "task")
			returnedErr := err != nil

			if returnedErr != tc.returnErr {
				t.Fatalf("Expected returnErr: %v, got: %v", tc.returnErr, returnedErr)
			}
		})
	}
}
