# Llama Farm

```bash
python -m venv .venv
.venv/bin/pip install -U "huggingface_hub[cli]"
.venv/bin/huggingface-cli download microsoft/BitNet-b1.58-2B-4T-gguf --local-dir BitNet-b1.58-2B-4T

sudo docker build https://github.com/loris-intergalactique/llama-farm.git#master -t llama-farm:latest
sudo docker run -it --rm llama-farm:latest api
```
