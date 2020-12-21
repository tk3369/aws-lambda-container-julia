# aws-lambda-container-julia

As of December 2020, AWS supports running Lambda functions from any container image.
This is an example of deploying Julia program as AWS lambda.

## How it works

The Dockerfile pulls from a standard Julia base image. It copies the project content
to the standard deployment directory `/var/task`. By setting `JULIA_DEPOT_PATH` environment
variable, the precompiled files will be stored in a known location. In addition, because
AWS Lambda provides a read-only file system, `JULIA_DEPOT_PATH` is again set to include
`/tmp/.julia` compilation files during runtime.

As required, Lambda functions must support the 
[Lambda Runtime API](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html).
The `main.jl` file implements the general workflow of this API, which involves
fetching incoming requests, calling user function, and reporting results back
to the Lambda execution environment.

This main program delegates lambda requests to the underlying module. In this case,
it's called `JuliaLambdaExample`. The module must define a function called
`handle_event` and the function must accept two arguments - `event_data` and `headers`.
The return value of this function will be recorded with lambda runtime.

## How to use this repo

To build your own AWS Lambda function, you can copy this repo and rename the
`JuliaLambdaExample` to whatever you want. Just make sure that all references
are renamed properly, including those in the `main.jl` file.

There is a convenient shell script in `scripts/deploy.sh` that can be used to
quickly build/tag/push a Docker image, and update the function on AWS. 

For example:
```
sh scripts/deploy.sh lambda-docker-julia-test1 latest
```

Before you use this script, you must:
1. Create the repository in AWS ECR
2. Create the lambda function with the first Docker image

## What next

In order to test lambda container images locally, we could include the Lambda Runtime
Interface Emulator (RIE) in the same image. 
See https://docs.aws.amazon.com/lambda/latest/dg/images-test.html

The `deploy.sh` script can be improved to auto-create the repo in ECR as
well as installing the first image.
