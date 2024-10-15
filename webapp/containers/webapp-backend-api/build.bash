#!/bin/bash
APP_NAME="backend-api"
IMG_NAME="gcastill0/${APP_NAME}"

docker build -t ${APP_NAME} .
