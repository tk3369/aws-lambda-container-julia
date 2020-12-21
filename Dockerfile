FROM julia:alpine

WORKDIR /var/task

ENV JULIA_DEPOT_PATH /var/task/.julia

COPY . .

RUN julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.API.precompile()" 

ENV JULIA_DEPOT_PATH /tmp/julia:/var/task/.julia

ENTRYPOINT [ "/usr/local/julia/bin/julia", "--project=.", "main.jl" ]
