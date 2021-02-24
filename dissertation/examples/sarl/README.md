# SARL

A SARL implementation of a counter agent.

This agent says hello to a partner, then counts to 3 and kills the partner agent.

Run with:
```
mvn install
mvn sarl:compile
mvn exec:exec -Dexec.executable=java "-Dexec.args=-cp %classpath io.sarl.sre.boot.Boot honours.Boot"
```
