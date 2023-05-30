%: %.pkr.hcl
	packer validate $^
	packer build $^

launch:
	@echo Launching t2.micro from AMI $(AMI) with sgs ssh and egress-all
	$(eval iid := $(shell aws ec2 run-instances --image-id $(AMI) --count 1 --instance-type t2.micro \
	--key-name ci --security-group-ids sg-0c984b6da37990ec3 sg-07b23555cc74458e7 --subnet-id subnet-02b27863f3c34175b \
	--output text --query 'Instances[*].InstanceId'))
	aws ec2 create-tags --resources $(iid) --tags Key=ou,Value=syse Key=purpose,Value=local-testing Key=managedby,Value=manual
	aws ec2 wait instance-running --instance-ids $(iid)
	$(eval ip := $(shell aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=$(iid)" \
	--query 'Reservations[*].Instances[*].[PublicIpAddress]' \
	--output text))
	@echo ssh -i ~/.ssh/ci.pem -l admin $(ip)

list:
	aws ec2 describe-images --owners 754489498669 --query "Images[*].[ImageId,Name,CreationDate]" --output text
