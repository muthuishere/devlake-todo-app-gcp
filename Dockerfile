FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# Copy gradle configuration files first
COPY gradle/ gradle/
COPY gradlew build.gradle settings.gradle ./
RUN chmod +x gradlew

# Download dependencies first (this layer will be cached)
RUN ./gradlew dependencies

# Copy source code and build
COPY src/ src/
RUN ./gradlew build -x test --no-daemon

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

# Add container health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:9090/actuator/health || exit 1

EXPOSE 9090
# Add JVM optimization flags
ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-jar", "app.jar"]
