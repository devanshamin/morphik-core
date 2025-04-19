# Build stage
FROM python:3.12.5-slim as builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    cmake \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Download NLTK data
RUN python -m nltk.downloader -d /usr/local/share/nltk_data punkt averaged_perceptron_tagger

# Production stage
FROM python:3.12.5-slim

# Set working directory
WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libmagic1 \
    tesseract-ocr \
    postgresql-client \
    poppler-utils \
    gcc \
    g++ \
    cmake \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /root/.local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /root/.local/bin /usr/local/bin
# Copy NLTK data from builder
COPY --from=builder /usr/local/share/nltk_data /usr/local/share/nltk_data

# Create necessary directories
RUN mkdir -p storage logs

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV HOST=0.0.0.0
ENV PORT=8000
ENV PATH="/usr/local/bin:$PATH"

# Copy startup script
COPY scripts/docker-entrypoint.sh /app/docker-entrypoint.sh 
RUN chmod +x /app/docker-entrypoint.sh

# Copy application code
COPY morphik.toml morphik.toml
COPY core ./core
COPY README.md LICENSE ./

# Labels for the image
LABEL org.opencontainers.image.title="Morphik Core"
LABEL org.opencontainers.image.description="Morphik Core - A powerful document processing and retrieval system"
LABEL org.opencontainers.image.source="https://github.com/yourusername/morphik"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="MIT"

# Expose port
EXPOSE 8000

# Set the entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
