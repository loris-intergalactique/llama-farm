FROM python:3.10-slim
ENV DEBIAN_FRONTEND=noninteractive
ENV LLVM_VERSION=19
ENV CC=clang
ENV CXX=clang++

RUN <<EOF
    set -ex
    apt update
    apt install -y git lsb-release wget software-properties-common gnupg cmake
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    ./llvm.sh ${LLVM_VERSION}
    cp /usr/bin/clang++-${LLVM_VERSION} /usr/bin/clang++
    cp /usr/bin/clang-${LLVM_VERSION} /usr/bin/clang
    clang -v
    clang++ -v
EOF

WORKDIR /opt
RUN git clone --recursive https://github.com/microsoft/BitNet.git bitnet
WORKDIR /opt/bitnet

RUN pip install -r requirements.txt

COPY BitNet-b1.58-2B-4T /models/BitNet-b1.58-2B-4T

RUN python setup_env.py -md /models/BitNet-b1.58-2B-4T -q i2_s || true

WORKDIR /opt/bitnet/3rdparty/llama.cpp/
RUN <<EOF
    set -ex
    cmake -B build -Wno-dev
    cmake --build build --target llama-server
EOF

COPY <<EOF /opt/entrypoint.sh
#!/usr/bin/env bash
set -ex

if [ \$# -eq 0 ]; then
    echo "Usage: \$0 <command>"
    echo "Commands:"
    echo "  web: Run the web server"
    echo "  cli: Run the CLI"
    exit 1
else
    COMMAND=\$1
    shift
fi

case "\$COMMAND" in
    api)
        /opt/bitnet/3rdparty/llama.cpp/build/bin/llama-server \\
            -m /models/BitNet-b1.58-2B-4T/*.gguf \\
            -c 2048 \\
            \$@
        ;;
    cli)
        /opt/bitnet/run_inference.py \\
            -m /models/BitNet-b1.58-2B-4T/*.gguf \\
            -cnv \\
            \$@
        ;;

    *)
        echo "Unknown command: \$COMMAND"
        exit 1
        ;;
esac
EOF
RUN chmod +x /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["api"]
EXPOSE 8080
