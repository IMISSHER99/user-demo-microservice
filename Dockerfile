# Stage 1: Build the application
FROM gradle:8.8.0-jdk21-alpine AS build
WORKDIR /workspace
COPY build.gradle settings.gradle gradle.properties ./
COPY gradlew ./
COPY gradle ./gradle
COPY src ./src
RUN chmod +x ./gradlew && ./gradlew clean build -Dquarkus.package.type=fast-jar

# Stage 2: Create the runtime image
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY --from=build /workspace/build/quarkus-app/lib/ ./lib/
COPY --from=build /workspace/build/quarkus-app/app/ ./app/
COPY --from=build /workspace/build/quarkus-app/quarkus/ ./quarkus/
COPY --from=build /workspace/build/quarkus-app/*.jar ./
COPY --from=build /workspace/build/quarkus-app/quarkus/quarkus-application.dat ./quarkus-application.dat

CMD ["java", "-jar", "quarkus-run.jar"]
