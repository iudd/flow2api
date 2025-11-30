FROM python:3.11-slim

WORKDIR /app

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

# Set environment variables
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PORT=7860 \
    HOST=0.0.0.0

EXPOSE 7860

CMD ["python", "main.py"]
