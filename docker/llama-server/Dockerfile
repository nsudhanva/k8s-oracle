ARG UBUNTU_VERSION=22.04

FROM ubuntu:$UBUNTU_VERSION AS build

RUN apt-get update && \
    apt-get install -y build-essential git cmake libssl-dev libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

ARG LLAMA_CPP_VERSION=b7779

WORKDIR /build

RUN git clone --depth 1 --branch $LLAMA_CPP_VERSION https://github.com/ggml-org/llama.cpp.git .

RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_NATIVE=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DGGML_BACKEND_DL=ON \
    -DGGML_CPU_ALL_VARIANTS=ON \
    -DLLAMA_CURL=ON && \
    cmake --build build -j $(nproc)

FROM ubuntu:$UBUNTU_VERSION AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends libgomp1 curl libcurl4 ca-certificates && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build /build/build/bin/llama-server /app/llama-server
COPY --from=build /build/build/src/libllama.so /app/lib/
COPY --from=build /build/build/ggml/src/libggml*.so /app/lib/

ENV LD_LIBRARY_PATH=/app/lib
ENV LLAMA_ARG_HOST=0.0.0.0

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

ENTRYPOINT ["/app/llama-server"]
