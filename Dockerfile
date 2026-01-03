FROM python:3.11-slim

WORKDIR /app

# Install Playwright system dependencies (from upstream)
RUN apt-get update && apt-get install -y \
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

# Create a non-root user
RUN useradd -m -u 1000 user

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=user . .

# Create necessary directories and set permissions
RUN mkdir -p /app/data /app/logs && \
    chown -R user:user /app && \
    chmod -R 777 /app/data /app/logs

# Switch to non-root user
USER user

# Install Playwright browser (from upstream, run as user)
RUN playwright install chromium

# Set environment variables
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PORT=7860 \
    HOST=0.0.0.0

EXPOSE 7860

CMD ["python", "main.py"]
