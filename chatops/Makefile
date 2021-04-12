CFN     = aws cloudformation

chatops: chatbot.yaml
	$(CFN) validate-template --template-body file://./chatbot.yaml
	$(CFN) create-stack --stack-name IntegrationChatOps --template-body file://./chatbot.yaml

