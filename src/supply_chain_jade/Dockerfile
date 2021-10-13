FROM maven:3.8.3-openjdk-8

WORKDIR /supply_chain

COPY pom.xml .

RUN mvn clean install
RUN mvn exec:exec -Dexec.executable="echo" # Dummy exec to pull in deps

COPY . .

RUN mvn compile

CMD ["mvn", "exec:java"]
