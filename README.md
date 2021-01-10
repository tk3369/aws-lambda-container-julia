# aws-lambda-container-julia

As of December 2020, AWS supports running Lambda functions from any container image.
This is an example of deploying Julia program as AWS lambda.

## How it works

The `Dockerfile` uses an AWS provided base image. It is more convenient because their
base image already includes the 
[Runtime Interface Emulator](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-images.html#runtimes-test-emulator) (RIE).  It would be possible
to use a different base image but then the RIE has to be installed separately.
Julia is downloaded and installed from the official julialang.org web site.

Project content are copied to the standard deployment directory `/var/task`. 
By setting `JULIA_DEPOT_PATH` environment variable, the precompiled files 
will be stored in a known location.

Note that AWS Lambda provides a read-only file system. If needed, the `JULIA_DEPOT_PATH`
can be reset to include `/tmp/.julia` for additional precompilation during runtime.
See [AWS FAQ for container images](https://aws.amazon.com/lambda/faqs/#Container_Image_Support)
for more information.

As required, Lambda functions must support the 
[Lambda Runtime API](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html).
The `main.jl` file implements the general workflow of this API, which involves
fetching lambda invocation requests, calling the `handle_event` function,
and reporting results back to the Lambda execution environment. This runtime is normally
provided by AWS for the officially supported languages. For Julia, we're just rolling
our own.

This main program delegates lambda requests to the underlying module. In this case,
it's called `JuliaLambdaExample`. The module must define a function called
`handle_event` and the function must accept two arguments - `event_data` and `headers`.
The return value of this function is then passed back to the lambda environment.

## How to use this repo

To build your own AWS Lambda function, you can copy this repo and rename the
`JuliaLambdaExample` to whatever you want. Just make sure that all references
are renamed properly.

There is a convenient shell script in `scripts/deploy.sh` that can be used to
quickly build/tag/push a Docker image and deploy the function on AWS. 

For example:
```
sh scripts/deploy.sh julia-lambda latest
```

The script does not deploy the lambda function unless it is already created.
Hence, just for the first time, you must create the lambda function using
your preferred approach (web interface, cloud formation, CDK, etc.)

## Contributions welcome!

Feel free to raise an issue or PR if you would like to contribute to this
repo.

