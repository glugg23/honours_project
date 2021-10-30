FROM maven:3.8.3-openjdk-8

WORKDIR /supply_chain

# https://jade.tilab.com/ is down so copy local maven cache into Docker container
COPY .m2 /root/.m2

COPY pom.xml .

RUN mvn clean install
RUN mvn exec:exec -Dexec.executable="echo" # Dummy exec to pull in deps

COPY src src

RUN mvn compile

CMD ["mvn", "exec:java"]
