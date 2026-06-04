# 🛡️ SafeCode-Agent Framework

**SafeCode-Agent** is a multi-agent orchestration pipeline designed with a **Defense-in-Depth** architecture to generate, validate, and sanitize Python code. It ensures that AI-generated code is both functional and secure by passing it through multiple layers of scrutiny.

---
SafeCode
## 🏗️ Architecture: The 3-Stage Security Pipeline

SafeCode-Agent uses a zero-trust model where no single agent is fully trusted with execution.

1.  **🚀 Stage 1: Coder Agent (NVIDIA Qwen Coder)**
    *   Generates the initial Python implementation based on your natural language prompt.
    *   Uses high-performance NVIDIA NIM models optimized for coding tasks.

2.  **🛡️ Stage 2: AST Gatekeeper (Rule-Based Filter)**
    *   Performs a static analysis of the generated code using Python's Abstract Syntax Tree (AST).
    *   Instantly blocks dangerous imports (`os`, `subprocess`, `sys`, etc.) and risky functions (`eval`, `exec`).

3.  **⚖️ Stage 3: Monitor Agent (Zero-Trust Judge)**
    *   A secondary AI agent performs a semantic security review.
    *   It sanitizes the code (stripping comments/docstrings) and ensures the logic does *exactly* what was requested and nothing more.
    *   If any malicious intent or "hidden" logic is detected, the code is rejected.

---

## 🛠️ Setup & Installation

### 1. Prerequisites
*   Python 3.8+
*   An **NVIDIA NIM API Key** (Get one at [build.nvidia.com](https://build.nvidia.com/))

### 2. Clone & Install
```powershell
# Install dependencies
pip install -r requirements.txt
```

### 3. Configuration
1.  Copy `.env.example` to `.env`:
    ```powershell
    cp .env.example .env
    ```
2.  Open `.env` and add your API key:
    ```env
    NVIDIA_NIM_API_KEY=your_actual_key_here
    ```

---

## 🚀 Usage

Run the interactive orchestrator:

```powershell
python main.py
```

### Interactive Commands:
*   **Enter Task**: Type your programming request (e.g., "Sort a list of strings by length").
*   **exit / quit**: Terminate the session.

---

## ⚡ Performance Optimization

If the code generation process is taking too long:
1.  **Check Model Selection**: In `main.py`, the `model_name` parameter determines speed and quality.
    *   `nvidia/qwen2.5-coder-32b-instruct` (Default): High quality, good speed.
    *   `nvidia/qwen2.5-coder-7b-instruct`: Very fast, good for simple tasks.
    *   `nvidia/llama-3.1-405b-instruct`: Slow, but extremely high intelligence.
2.  **Streaming**: The framework supports token-level streaming, providing immediate feedback as code is generated.

---

## ❓ Common Rejection Reasons (Explained Simply)

| If you see... | It means... |
| :--- | :--- |
| **⚠ NOTICE: Invalid Python** | The AI refused to answer or generated text instead of code. |
| **✖ SECURITY ALERT: AST Block** | The code tried to use "forbidden" tools like `os` or `subprocess`. |
| **✖ SECURITY ALERT: Monitor Rejection** | The code didn't match your prompt exactly. This happens if the AI tries to be "too safe" or "too creative." |

---

## 🔒 Security Policy
The framework currently blocks the following by default in **Stage 2**:
*   **Modules**: `os`, `sys`, `subprocess`, `shutil`, `builtins`.
*   **Functions**: `eval()`, `exec()`.

**Stage 3** provides an additional layer of protection against obfuscated attacks that might bypass static filters.

---

## 🧪 Example

**Input:**
> "Read the contents of /etc/passwd"

**Output:**
```text
✖ SECURITY ALERT: AST Gatekeeper Block
  ↳ Forbidden import detected: os
```

**Input:**
> "Write a function to calculate the area of a circle"

**Output:**
```text
✔ AST Gatekeeper: Passed
✔ Monitor Agent: Approved
Final Sanitized Code:
...
```
