# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Install system dependencies and PostgreSQL client libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the requirements file first to cache dependencies
COPY requirements.txt ./

# Copy the required wizexercise.txt file
COPY wizexercise.txt ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Expose the port the app will run on
EXPOSE 5000

# Command to run the application
CMD ["python", "backend-api.py"]

