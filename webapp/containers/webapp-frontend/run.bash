#!/bin/bash
APP_NAME="webapp-frontend"
IMG_NAME="gcastill0/${APP_NAME}"

docker run -d --name=$APP_NAME \
  -h "frontend.example.com" \
  -e PREFIX="tech" \
  -e POSTFIX="12345ABC" \
  -p 8080:80 $IMG_NAME:latest
