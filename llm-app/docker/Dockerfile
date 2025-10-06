FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python packages SEPARATELY to avoid memory issues
RUN pip3 install --upgrade pip

# Install PyTorch with CUDA 12.1 support explicitly
RUN pip3 install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu121

# Install other packages one at a time
RUN pip3 install --no-cache-dir transformers
RUN pip3 install --no-cache-dir fastapi
RUN pip3 install --no-cache-dir "uvicorn[standard]"
RUN pip3 install --no-cache-dir pydantic
RUN pip3 install --no-cache-dir accelerate

# Copy application
COPY app.py .

# Run the application
CMD ["python3", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]