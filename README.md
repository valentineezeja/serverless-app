
# London weather web application 
### A simple serverless weather app deployed to AWS using Terraform 

## Tools versions/access prerequisites:
- AWS CLI: aws-cli/2.6.4 Python/3.9.11
- Terraform: Terraform v1.3.5
   - Module/provider versions:
        -   provider registry.terraform.io/hashicorp/archive v2.2.0
        - provider registry.terraform.io/hashicorp/aws v4.40.0
- Visual Studio Code: v1.73.1
- Git:  v2.37.2.windows.2

- Access: 
    - AWS admin user and security credentials
    - [An Openweather account & API key](https://openweathermap.org/api)


## Overview:
Something about the whys...
In the course of implementing this projct, I had several AWS services to choose from, based on the following requirements for the application:
- 	The deployment should be scalable and cost optimised
- 	The deployment should be able to withstand the loss of a single application component
- 	The deployment method should be capable of bringing up and tearing down the entire infrastructure, repeatedly

After reviewing a couple of services and deployment models, I chose the combination of Lambda + API Gateway over other services for the following reasons:

+ Cost: With AWS Lambda, you pay for execution duration rather than server unit. When using Lambda functions, you only pay for requests served and the compute time required to run your code.
+ High availability: AWS Lambda maintains compute capacity across multiple Availability Zones (AZs) in each AWS Region to help protect your code against individual machine or data center facility failures. Both AWS Lambda and the functions running on the service deliver predictable and reliable operational performance. AWS Lambda is designed to provide high availability for both the service itself and the functions it operates. There are no maintenance windows or scheduled downtimes.
+ Scalability: AWS Lambda invokes your code only when needed, and automatically scales to support the rate of incoming requests without any manual configuration. There is no limit to the number of requests your code can handle. AWS Lambda typically starts running your code within milliseconds of an event. Since Lambda scales automatically, the performance remains consistently high as the event frequency increases. Since your code is stateless, Lambda can start as many instances as needed without lengthy deployment and configuration delays.

### Limitations: 
The only temporary limitation to this solution is that AWS Lambda has size limit of 50 MB when you upload the code directly to the Lambda service. However, with the container feature for functions, the web app can be scaled by [running the functions as container images (up to 10GB)](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-images.html). This awesome feature further lends credence to the scalability of this solution, so this isn't a limitation any longer.

## Table of contents

-  Create the web app using html/css/js

- Initialise Terraform and upload the files to an S3 bucket in zipped format using Terraform

- Deploy a Lambda function using the S3 bucket as source

- Deploy and configure an API gateway to make calls to the 

- Push the repository to Github

- Extra: Configure a custom domain for the API to make the URL look beautiful 🤳🏾

# Create the web app using html/css/js
The code for the app can be found [here](https://github.com/valentineezeja/Project-1.0/tree/main/web-files). I have added as much comment as I could to make it understandable to anyone who comes across it. In a nutshell, what the JavaScript code does is use OpenWeatherMap API to get the current local weather (London, with  City ID of 2643741) and display it on the browser.

# Initialise Terraform and upload the files to an S3 bucket in zipped format using Terraform
After creating the the front end files, perform the following actions:

- Open the root directory in VS Code and create three files namely: called variable.tf and main.tf and provider.tf
- Create a profile using the AWS CLI to add security credentials to it. Then declare the profile in the variable.tf file
- Modify the provider.tf file to add the terraform AWS provoder (this references the profile added in step 1 above)
- Using the terminal, navigate to the root folder of this project and "terraform init" to initialise the directory
- Modify the main.tf file to add the first block of code which creates an S3 bucket, creates an archive of the "web-files" directory and upload the web-files.zip file to the bucket
NB: The "source_code_hash = "${base64sha256(data.archive_file.source.output_path)}" command ensures that the files are updated appropriately on the bucket whenever changes are made to them.

- After making the changes, save it (use save all) and run "terraform plan", confirm that you are happy with the changes about to be deployed. then run "terraform apply" to deploy the changes to the infrastructure. 

# Deploy a Lambda function using the S3 bucket as source
The next block of code does the following (within the main.tf file):
- Creates a Lambda function called "WeatherApp" using the zipped file (web-files.zip) from the S3 bucket as source. The runtime and handler of the function were also provided - "nodejs12.x" and "index.handler" respectively.
- After the lambda function creation, an IAM role (Lambda Execution role) is also needs to be created to grant the function permission to access AWS services and resources.
-  After making the changes, save it and run "terraform plan", confirm that you are happy with the changes about to be deployed. then run "terraform apply" to deploy the changes to the infrastructure. 

# Deploy and configure an API gateway to make calls to the Lambda function
An API gateway is required to access the function from the public internet via a URL. Steps required (withi the main.tf file):
- Create an API (Rest API) with name "api-gateway" and regional endpoint configuration
- Create a reource and a http method on the API with value "ANY" and authorisation as "NONE"
- Create a gateway integration with type "AWS_proxy" (this is equivalent to the Lambda type seen in the console/UI). The reference the arn of the Lambda function created earlier as the URI for this integration.
- Create an IAM role called "apigw_lambda" which allows the API gateway to invoke the function created earlier.

- After making the changes, save it and run "terraform plan", confirm that you are happy with the changes about to be deployed. then run "terraform apply" to deploy the changes to the infrastructure. 

- Once deployment of the API gateway is completed, log into the AWS console, navigate to the API (api-gateway), click on resources > actions > deploy. In the "Development stage" box, Select New stage, enter "web" in the Stage name and click Deploy.  

- Copy the Invoke URL displayed after deployment and paste it into a browser, this should load the application hosted on Lambda.

## [Mine can be accessed here](https://mxa6w7azhe.execute-api.us-east-1.amazonaws.com/web)

# Push the repository to Github
The last step involves pushing the codebase to Github using Git CLI. assuming you have Git CLI already configured

- Open Git Bash and change to the Projects-1.0 root directory , then run "git init -b main"
- Stage the files for initial commit using "git add ." command

### Important:
Run the following command to prevent the exe files within /.terraform directory from being pushed to GitHub (ensure that this is run from the project root directory):
 git update-index --assume-unchanged ~/Desktop/Project-1.0/.terraform/
If you don't, you will end up with an error about the file exceeding GitHub's file size limit of 100.00 MB

- Commit the staged files using git commit -m "initial commit"

- Log in to github.com and navigate to the new repository copy the remote repository URL from the set up page

- Run the following commands from Git bash 
    git remote add origin <your_REMOTE_URL>
    git remote -v

- Finally, Push the changes in your local repository to GitHub using the following command:
    git push origin main


## **** Extra: Configure a custom domain for the API to make the URL look beautiful
- This section is currently pending as I am sorting some issues with my DNS providers. I will update this part of the guide once that is sorted; might as well move my domains to Route53 while at it. In the meantime though, here is the proposed URL: weather.valentineezeja.com.
