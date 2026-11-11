> [!CAUTION]
> **⚠️ DOCUMENTATION IN PROGRESS**
> This documentation is currently being updated. Please be aware that the information may not be current or fully reflect the latest project functionality.


# ComfyUI Docker

A Docker container for [ComfyUI](https://github.com/Comfy-Org/ComfyUI). Designed for easy deployment in local Docker environments or on remote servers. The [ComfyUI Manager](https://github.com/Comfy-Org/ComfyUI-Manager) extension is included by default.

## 📋 Prerequisites
Before running this container, ensure you have the following installed:
- [Docker](https://www.docker.com/) (Engine or Desktop)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (Required for GPU acceleration)

# Deployment Guide

This guide provides instructions for running and managing the ComfyUI Docker container.

## 🚀 Getting Started

### ⚡ Option 1: Instant Trial (Ephemeral)
If you just want to test ComfyUI immediately without managing persistent data, run this command. 
**Note:** All changes (models, nodes, workflows) will be lost once the container stops.

```shell
docker run -it --rm \
    --gpus all \
    --publish 8188:8188 \
    ghcr.io/thelastblt/comfyui-docker:latest
```

### 🛠️ Option 2: Permanent Setup (Recommended)

For daily use with persistent storage for your models, custom nodes, and outputs, use **Docker Compose**.

1. **Clone the repository:**
   ```shell
   git clone https://github.com/thelastblt/comfyui-docker.git
   cd comfyui-docker
   ```
2. **Prepare your host directories**
   ```shell
   mkdir -p $HOME/.comfyui/{models,custom_nodes,output}
   ```
3. **Start the service**
   ```shell
   docker compose up -d
   ```
Once started, access ComfyUI at http://localhost:8188.

## ⚙️ Configuration & Customization

### 📂 Volume Mapping & Permissions
To ensure you have write access to your files on the host system, the container runs using your host's User ID and Group ID. This prevents the common issue where files (like downloaded models) are owned by `root`.

If you are using `docker run` instead of Docker Compose, include these flags to persist your data:

```shell
--env USER_ID="$(id -u)" \
--env GROUP_ID="$(id -g)" \
--volume "$HOME/.comfyui/models:/opt/comfyui/models:rw" \
--volume "$HOME/.comfyui/custom_nodes:/opt/comfyui/custom_nodes:rw" \
--volume "$HOME/.comfyui/output:/opt/comfyui/output:rw"
```

### 🔌 Custom Nodes & Network Security
By default, this image is configured with `network_mode = personal_cloud` and `security_level = normal`. This provides a balance of ease-of-use and security for most users and is the normal local install setting.

If you need to install specific custom node packs that require broader permissions, you can temporarily lower the security level by running the following command inside the container:

```shell
# Change allow git/ installs to 'true' to allow custom node installation
docker exec -it comfyui sed -i 's/allow_git_url_install = .*/allow_git_url_install = true/' user/__manager/config.ini

# Change allow pip installs to 'true' to allow custom node installation
docker exec -it comfyui sed -i 's/allow_pip_install = .*/allow_pip_install = true/' user/__manager/config.ini

# Restart the container to apply the changes
docker restart comfyui
```

You can also enable the following features by setting them to true in the [default] section of user/__manager/config.ini:

- allow_git_url_install: Allows installing custom nodes from arbitrary git URLs.
- allow_pip_install: Allows installing arbitrary pip packages via the Manager.


> [!WARNING]
> Reducing the security level to weak may expose the ComfyUI instance to different network risks. Please review the [ComfyUI Manager Security Policy](https://github.com/Comfy-Org/ComfyUI-Manager/tree/manager-v4#risky-level-table) to understand the implications.

> [!IMPORTANT]
> While the custom nodes themselves are installed outside of the container, their requirements are installed inside of the container. This means that removing the container will remove the installed requirements and all outputs you have not saved manually. When the container is started again, the requirements will be automatically installed, but this may, depending on the number of custom nodes and their requirements, take some time.


### ⚡ Hardware & GPU Acceleration
The container is pre-configured to utilize NVIDIA GPUs. Ensure that the NVIDIA Container Toolkit is installed on your host machine to allow the container to access your hardware acceleration.

By default, Docker Compose is configured to assign all available NVIDIA GPUs on your host system to the container.

If you are running a multi-GPU system and want to limit the container to specific cards, you can modify the compose.yml file under the services.comfyui.deploy.resources.reservations.devices section.

**Examples:**

* **Use only one GPU:**
  ```yaml
  count: 1
  ```
* **Use specific GPUs (e.g., GPU 0 and GPU 3)::**
  ```yaml
  device_ids: ['0', '3']
  ```

## ⚙️ Advanced Configuration
This section is for users who need more control over the container's behavior, such as custom command-line arguments, specific image versions, or custom file paths.

### 🛠️ Customizing ComfyUI Arguments
You can pass additional command-line arguments directly to the ComfyUI process.

Using Docker Run:
Add your arguments to the end of your command. For example, to allow external web apps to connect:

```shell
docker run ... ghcr.io/thelastblt/comfyui-docker:latest --enable-cors-header <origin>
```
Using Docker Compose:
Use the command key in your compose.yml file:
```shell
services:
  comfyui:
    # ... other settings
    command: ["--enable-cors-header", "*"]
```
### 🌐 Environment Variables & .env
The container supports several environment variables that can be set via your shell or a .env file to simplify your setup.

| Variable | Description |
| :--- | :--- |
| `USER_ID` | Sets the user ID inside the container to match your host user. |
| `GROUP_ID` | Sets the group ID inside the container to match your host group. |
| `IMAGE_TAG` | Specifies the version of ComfyUI to use (e.g., `v1.2.0`). Defaults to `latest`. |
| `MODELS_PATH` | Overrides the default `/opt/comfyui/models` directory. |
| `CUSTOM_NODES_PATH` | Overrides the default `/opt/comfyui/custom_nodes` directory. |
| `OUTPUT_PATH` | Overrides the default `/opt/comfyui/output` directory. |

Example .env file:
```yaml
# User Permissions (Match your host user to avoid root-owned files)
USER_ID=1000
GROUP_ID=1000

# Custom Storage Paths
MODELS_PATH=/path/to/your/models
CUSTOM_NODES_PATH=/path/to/your/custom_nodes
OUTPUT_PATH=/path/to/your/output

# Image Version
IMAGE_TAG=latest
```

## 🔄 Updates & Tags

To keep your ComfyUI environment up to date, you should periodically pull the latest images.

### Using Docker Compose (Recommended)
If you are using Docker Compose, updating is simple:

```shell
# Pull the latest images
docker compose pull

# Restart the service with the new images
docker compose up -d
```

### Using Docker Run
If you started your container using docker run, follow these steps:

```shell
# 1. Stop and remove the existing container
docker stop comfyui
docker rm comfyui

# 2. Pull the latest image
docker pull ghcr.io/thelastblt/comfyui-docker:latest

# 3. Start the container again
# (Ensure you use the same --volume and --env flags used during initial setup)
docker run [YOUR_ORIGINAL_FLAGS] ghcr.io/thelastblt/comfyui-docker:latest
```
## 🏷️ Image Tags

This project follows [Semantic Versioning (SemVer)](https://semver.org/). We provide multiple tag patterns to give you control over how often your environment updates.

| Tag Pattern | Example | Description | Best For... |
| :--- | :--- | :--- | :--- |
| `latest` | `latest` | The most recent stable release. | Most up to date ComfyUI and Pytorch. |
| `vX.Y.Z` | `v1.2.0` | A specific, exact version. | Absolute stability and reproducibility. |
| `vX` | `v1` | The latest release within a major version. | Automatic minor/patch updates while avoiding breaking changes. |
| `vX.Y` | `v1.2` | The latest release within a minor version. | Automatic patch updates while avoiding feature changes. |
| `vX.Y.Z-legacy` | `v1.2.0-legacy` | A version optimized for older hardware/drivers. | Users on older systems who cannot run the latest dependencies. |

> [!TIP]
> **Pro-Tip:** For production or mission-critical workflows, it is highly recommended to use a specific version tag (e.g., `v1.2.0`) to ensure your environment remains identical across re-installs.

> [!WARNING]
> I only do testing on the latest image tag. Typically that is running the latest stable version of ComfyUI and Pytorch/Cuda. If you run into issues running other tags, please open an issue.

## 🛠️ Building from Source

If you want to use the bleeding-edge development version or wish to make your own modifications to the Dockerfile, you can build the image locally:

```shell
# 1. Clone the repository
git clone https://github.com/thelastblt/comfyui-docker.git
cd comfyui-docker

# 2. Build the image
docker build --tag comfyui-docker:latest source
```

Once built, you can run your custom image using the following command:

```shell
docker run \
    --name comfyui-custom \
    --detach \
    --restart unless-stopped \
    --env USER_ID="$(id -u)" \
    --env GROUP_ID="$(id -g)" \
    --volume "$HOME/.comfyui/models:/opt/comfyui/models:rw" \
    --volume "$HOME/.comfyui/custom_nodes:/opt/comfyui/custom_nodes:rw" \
    --volume "$HOME/.comfyui/output:/opt/comfyui/output:rw" \
    --volume "$HOME/.comfyui/user/default/workflows:/opt/comfyui/user/default/workflows:rw" \
    --publish 8188:8188 \
    --gpus all \
    comfyui-docker:latest
```

---
## 📜 Project Links

- **[AI Usage Policy](AI.md)** — Our commitment to privacy and the use of local, open-source AI models.
- **[Contributing Guide](CONTRIBUTING.md)** — How to help improve this project.
- **[Credits](CREDITS.md)** — Acknowledgments and credits.
- **[License](LICENSE)** — The legal terms for this project.

## ⚖️ License

This project is licensed under the **MIT License**. 

*Note: ComfyUI and ComfyUI Manager are licensed under their respective licenses (GPL 3.0) as linked in the official repositories.*

