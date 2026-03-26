FROM maven:3.9.9-eclipse-temurin-17
WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn -q clean package

CMD ["java", "-jar", "target/PayBridge-D-1.0-SNAPSHOT.jar"]
