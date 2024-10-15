# Project Overview

This project focuses on deploying a microservices-based web application using **Kubernetes (EKS)** and **EC2** for database hosting, leveraging **Terraform** for automated infrastructure provisioning. The setup includes both public and private networking layers, ensuring that critical services like the backend API and database are securely isolated, while the frontend remains publicly accessible.

## Infrastructure Deployment with Terraform

We used **Terraform** to provision and manage the entire infrastructure:
- **EKS Cluster**: The application is hosted on an EKS cluster, where a Webapp Frontend service and a Backend API are deployed as containerized applications. Terraform automates the provisioning and scaling of the EKS cluster, ensuring that resources are allocated efficiently.
- **EC2 for PostgreSQL Database**: The PostgreSQL database is hosted on an EC2 instance. Using Terraform, we automated the creation of the EC2 instance, including the setup of security groups, storage, and networking configurations.

## Networking Architecture

The infrastructure is divided into **public and private networks** to ensure security and isolation of services:
- **Private Network**: The backend API and PostgreSQL database reside in the private subnets, which are inaccessible from the public internet. This ensures that sensitive services remain isolated and are only accessible from within the Kubernetes cluster or through controlled ingress rules.
- **Public Network**: The frontend web application is hosted on the EKS cluster and is exposed to the internet via a **Kubernetes Ingress Controller**. External users can access the application, but all communication with the backend is routed internally within the cluster.
- **Internet Gateway**: The **Internet Gateway** provides secure outbound access for services within the private network, such as the backend API and database, enabling them to access external resources, such as AWS S3 for backups.

## Backend API and Database Integration

The **backend API** connects to a **PostgreSQL database** hosted on an EC2 instance. Key aspects include:
- **Data Persistence**: The PostgreSQL database is the primary data store for the application, with a focus on high availability and secure internal networking.
- **Backup Process**: Automated backups of the PostgreSQL database are configured, with simple database dumps stored in an AWS S3 bucket. The data is regularly backed up with a custom Linux service unit.

## Kubernetes and Security Configuration

The project leverages Kubernetes networking and security best practices:
- **Internal-Only Backend API**: The backend API is exposed only within the Kubernetes cluster through a **ClusterIP** service, ensuring it is not accessible from the public internet.
- **Public Frontend via Ingress Controller**: The frontend web application is exposed via an NGINX Ingress Controller, enabling secure public access while routing requests to the backend internally.
- **Role-Based Access Control (RBAC)**: Kubernetes **RBAC** is used to control permissions and access for resources within the cluster, ensuring that only authorized users and services can access sensitive components.
