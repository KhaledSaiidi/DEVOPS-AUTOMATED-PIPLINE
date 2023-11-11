# DevOps-Automated-Pipeline

This DevOps project automates the continuous integration and delivery (CI/CD) pipeline for a Java application using various powerful tools in the DevOps ecosystem.

## Project Objectives

The primary objectives of this project are to:

1. **Dockerize Application and Nexus Integration:**
   - Containerize the Java application.
   - Push the Docker image to a Nexus repository for artifact management.

2. **Gradle Build and SonarQube Integration:**
   - Build the project using Gradle.
   - Perform automated testing with SonarQube for code quality analysis.

3. **Helm Charts and Kubernetes Deployment:**
   - Utilize Helm for packaging and managing Kubernetes applications.
   - Create Helm charts for the Java application.
   - Ensure Helm charts are tested for misconfigurations using datree.io.
   - Deploy the Helm charts on a Kubernetes cluster.

## Tools Used

- **Jenkins:**
  - Orchestrates the entire CI/CD pipeline.
  - Listens for GitHub commits and triggers the pipeline.

- **Docker:**
  - Containers for packaging the Java application.

- **Nexus Repository:**
  - Stores and manages Docker artifacts.

- **Gradle:**
  - Build automation for the Java application.

- **SonarQube:**
  - Provides automated code quality analysis.

- **Helm:**
  - Manages Kubernetes applications with packaging and deployment.

- **Kubernetes:**
  - Orchestrates the deployment of containerized applications.

- **datree.io:**
  - Tests Helm charts for misconfigurations.