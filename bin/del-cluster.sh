#!/bin/sh

for s in $(aws ecs list-services --cluster $1 | jq -r ".serviceArns[]")
do
    aws ecs update-service --cluster $1 --service $s --desired-count 0 > ${1}.log
    aws ecs delete-service --cluster $1 --service $s >> ${1}.log
done
echo Waiting for services to become inactive for $1 ...
aws ecs wait services-inactive --cluster $1 --services tyk tyk-analytics tyk-pump redis
aws ecs delete-cluster --cluster $1 >> ${1}.log || cat $1.log
rm ${1}.log
