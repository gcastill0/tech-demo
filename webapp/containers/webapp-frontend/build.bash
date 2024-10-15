#!/bin/bash
APP_NAME="webapp-frontend"
IMG_NAME="gcastill0/${APP_NAME}"

docker build -t $IMG_NAME .
