# ---------- Stage 1: builder ----------
ARG PYTORCH_VERSION=2.15.0
ARG CUDA_VERSION=13.4
ARG CUDNN_VERSION=9
FROM pytorch/pytorch:${PYTORCH_VERSION}-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime AS builder

ARG COMFYUI_VERSION=0.43.0
ENV DEBIAN_FRONTEND=noninteractive

# git: fetch ComfyUI; python3.12-venv: only needed to *create* the venv
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# --branch + --depth 1 = a single snapshot of the requested tag, no full history
RUN git clone --depth 1 --branch "v${COMFYUI_VERSION}" https://github.com/Comfy-Org/ComfyUI.git . \
    && rm -rf .git

# Isolated venv: pip installs torch (and everything else) into the venv itself.
# Note: --system-site-packages must NOT be used here — ComfyUI-Manager's
# dependency check doesn't recognize torch that only lives in the base
# image's site-packages, and the container will restart-loop with
# "PyTorch is not installed".
# BuildKit cache mount = fast rebuilds with zero image-size cost.
# torchaudio: ComfyUI's requirements only install torch + torchvision, but
# the Manager's PIPFixer requires the full trio (torch, torchvision,
# torchaudio) and logs "PyTorch is not installed" on every start without it.
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install \
        --requirement requirements.txt \
        --requirement manager_requirements.txt \
        torchaudio

# ---------- Stage 2: runtime ----------
FROM pytorch/pytorch:${PYTORCH_VERSION}-cuda${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime

ARG COMFYUI_VERSION=0.38.0
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# git: ComfyUI-Manager clones/updates custom nodes at runtime;
# gosu: privilege drop; curl: healthcheck; lib*: headless OpenCV/glib deps
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        gosu \
        curl \
        libgl1 \
        libglx-mesa0 \
        libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/comfyui

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /build  /opt/comfyui

# A host volume mounted at /opt/comfyui/models hides the tree that ships in
# the image, so keep a pristine copy of the repo's models/ skeleton (empty
# folders + .gitkeep placeholders) for the entrypoint to restore.
RUN cp -a /opt/comfyui/models /opt/comfyui-models-template

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -fsSI http://localhost:8188/ || exit 1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
