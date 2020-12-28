# AWS provided base image (Amazon Linux 2)
FROM public.ecr.aws/lambda/provided:al2

# Download and install Julia
WORKDIR /usr/local
RUN yum install -y tar gzip \
 && curl -LO https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.3-linux-x86_64.tar.gz \
 && tar xf julia-1.5.3-linux-x86_64.tar.gz \
 && rm julia-1.5.3-linux-x86_64.tar.gz \
 && ln -s julia-1.5.3 julia

WORKDIR /var/runtime
COPY bootstrap .

WORKDIR /var/task

ENV JULIA_DEPOT_PATH /var/task/.julia

COPY . .

RUN /usr/local/julia/bin/julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.API.precompile()"

ENV JULIA_DEPOT_PATH /tmp/julia:/var/task/.julia

CMD [ "handle_event"]
