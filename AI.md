# AI Usage Disclosure

This repository leverages Artificial Intelligence (AI) to enhance development productivity. In alignment with the principles of privacy and open-source software, this project prioritizes local, open-source AI workflows.

## 🔒 Privacy & Data
This project **does not use cloud-based AI services** (such as OpenAI, Anthropic, or Google Gemini). 

By using **locally hosted models**, we ensure:
- **Zero Data Leaks:** No code, configuration, or sensitive project data is ever sent to a third-party server.
- **Privacy:** All processing happens entirely on local hardware.
- **Open Ecosystem:** We prioritize models that support the open-source community.

## 🤖 Models Used
Development is assisted by locally hosted, open-source Large Language Models (LLMs) running on private hardware. This includes models from the **Qwen, Gemma, Nemotron, and Muse Glimmer** families.

## 🛠️ How AI is Used
AI is utilized for:
- **Documentation:** Drafting, formatting, and refining `README.md`, `CHANGELOG.md`, and `CONTRIBUTING.md`.
- **Code Assistance:** Explaining complex logic, suggesting refactors, and assisting in writing unit tests.
- **Troubleshooting:** Analyzing error logs and suggesting potential fixes for build issues.

## 🛡️ Human Oversight (The "Human-in-the-Loop" Guarantee)
**AI is a tool for augmentation, not a replacement for engineering.** 

Every line of code, every configuration change, and every documentation update generated or suggested by AI is:
1.  **Reviewed** by the maintainer for accuracy, security, and logic.
2.  **Tested** within a Docker environment to ensure full functionality.
3.  **Verified** to ensure it meets the high standards of this project.

The maintainer remains fully responsible for all content and code within this repository.
