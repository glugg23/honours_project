FROM maven:3.8.2-adoptopenjdk-8

WORKDIR /supply_chain

COPY pom.xml .

RUN mvn clean install
RUN mvn exec:exec -Dexec.executable="echo" # Dummy exec to pull in deps

COPY . .

RUN mvn compile

CMD ["mvn", "-Pmain", "exec:java"]
