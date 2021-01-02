# AWS provided base image (Amazon Linux 2)
FROM public.ecr.aws/lambda/provided:al2

# Download and install Julia
WORKDIR /usr/local
RUN yum install -y tar gzip \
 && curl -LO https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.3-linux-x86_64.tar.gz \
 && tar xf julia-1.5.3-linux-x86_64.tar.gz \
 && rm julia-1.5.3-linux-x86_64.tar.gz \
 && ln -s julia-1.5.3 julia

# Install bootstrap script
WORKDIR /var/runtime
COPY bootstrap .

# Install application
WORKDIR /var/task

# Use a special depot path to store precompiled binaries
ENV JULIA_DEPOT_PATH /var/task/.julia

# Copy application code
COPY . .

# Instantiate project and precompile packages
RUN /usr/local/julia/bin/julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.API.precompile()"

# Uncomment this line to allow more precompilation in lamdbda just in case
#ENV JULIA_DEPOT_PATH /tmp/.julia:/var/task/.julia

# This is technically not used but is required by Lambda
CMD [ "handle_event"]
