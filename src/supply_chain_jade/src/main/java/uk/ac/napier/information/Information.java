package uk.ac.napier.information;

import jade.core.Agent;
import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.GenServerBehaviour;

public class Information extends Agent {
    @Override
    protected void setup() {
        GenServerBehaviour behaviour = new GenServerBehaviour(this) {
            @Override
            public void handle(ACLMessage message) {
                System.out.println(message.getContent());
            }
        };

        this.addBehaviour(behaviour);
    }
}
