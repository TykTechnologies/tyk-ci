{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"GetAuthorizationToken",
         "Effect":"Allow",
         "Action":[
             "ecr:GetAuthorizationToken"
         ],
         "Resource":"*"
      },
       {
         "Sid":"AllowPull",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
         ],
         "Resource": ${jsonencode([ for r in ecrs: "${r}" ])}
       },
       {
         "Sid":"AllowPush",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
         ],
         "Resource": ${jsonencode([ for r in ecrs: "${r}" ])}
       }
   ]
}
