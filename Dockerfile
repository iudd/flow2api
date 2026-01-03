FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (Playwright + Rclone + Utilities)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    dos2unix \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && rm -rf /var/lib/apt/lists/*

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Create a non-root user
RUN useradd -m -u 1000 user

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browser
RUN playwright install chromium

# Copy application code
COPY --chown=user . .

# Create necessary directories and set permissions
RUN mkdir -p /app/data /app/logs /home/user/.config/rclone && \
    chown -R user:user /app /home/user/.config && \
    chmod -R 777 /app/data /app/logs

# Switch to non-root user
USER user

# Set environment variables
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PORT=7860 \
    HOST=0.0.0.0

EXPOSE 7860

CMD ["python", "boot.py"]
