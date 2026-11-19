# ---------- Stage 1: builder ----------
FROM ubuntu:26.04 AS builder

ARG COMFYUI_VERSION=0.46.0
ENV DEBIAN_FRONTEND=noninteractive

# git: fetch ComfyUI; python3.14-venv: only needed to *create* the venv.
# ubuntu:26.04 ships no Python by default and no torch/CUDA — the venv is
# fully self-contained (pip's torch wheels bundle the CUDA stack), so a
# framework base image is no longer needed.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        python3.14 \
        python3.14-venv \
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
# python3.14 is named explicitly: the venv's interpreter is fixed at creation
# time, so don't rely on the base image's default python.
# BuildKit cache mount = fast rebuilds with zero image-size cost.
# torchaudio: ComfyUI's requirements only install torch + torchvision, but
# the Manager's PIPFixer requires the full trio (torch, torchvision,
# torchaudio) and logs "PyTorch is not installed" on every start without it.
RUN --mount=type=cache,target=/root/.cache/pip \
    python3.14 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install \
        --requirement requirements.txt \
        --requirement manager_requirements.txt \
        torchaudio

# ---------- Stage 2: runtime ----------
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# git: ComfyUI-Manager clones/updates custom nodes at runtime;
# gosu: privilege drop; curl: healthcheck; lib*: headless OpenCV/glib deps.
# libglib2.0-0t64 is the 26.04 name for libglib2.0-0 (time_t64 rename).
# No python packages: the venv ships its own interpreter link and pip.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        gosu \
        curl \
        libgl1 \
        libglx-mesa0 \
        libglib2.0-0t64 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/comfyui

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /build  /opt/comfyui

# ComfyUI-Manager creates user/__manager/config.ini only on first start, with
# network_mode=public. The server listens on 0.0.0.0, so the manager treats it
# as non-local and blocks install/update actions inside the container until
# network_mode=personal_cloud. Seed the config at build time so in-container
# node updates work out of the box instead of sed-ing the file after boot.
COPY config.ini /opt/comfyui/user/__manager/config.ini

# A host volume mounted at /opt/comfyui/models hides the tree that ships in
# the image, so keep a pristine copy of the repo's models/ skeleton (empty
# folders + .gitkeep placeholders) for the entrypoint to restore.
RUN cp -a /opt/comfyui/models /opt/comfyui-models-template

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -fsSI http://localhost:8188/ || exit 1

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
