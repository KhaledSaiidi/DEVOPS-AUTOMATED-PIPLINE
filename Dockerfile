# Make sure to add to /etc/docker/daemon.json the nexus repo url as insecure-registries

# Stage 1: Build stage
FROM openjdk:11 as base
WORKDIR /app
COPY . .
RUN chmod +x gradlew
RUN ./gradlew build

# Stage 2: Runtime stage
FROM tomcat:9
WORKDIR webapps
# Copies the built .war file from the previous stage (base) into the /webapps directory of the Tomcat container
COPY --from=base /app/build/libs/DEVOPS-AUTOMATED-PIPLINE-0.0.1-SNAPSHOT.war .
# Removes the default ROOT directory in Tomcat and renames the .war file to ROOT.war, 
# setting it as the default web application served by Tomcat
RUN rm -rf ROOT && mv DEVOPS-AUTOMATED-PIPLINE-0.0.1-SNAPSHOT.war ROOT.war