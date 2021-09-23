package uk.ac.napier.knowledge;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.Message;
import uk.ac.napier.behaviours.GenServerBehaviour;

public class Clock extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        GenServerBehaviour behaviour = new GenServerBehaviour() {
            @Override
            public void handle(ACLMessage message) {
                if(message.getPerformative() == ACLMessage.QUERY_IF && message.getContent().equals("ready?")) {
                    ACLMessage reply = Message.reply(message, ACLMessage.INFORM, Boolean.toString(ready));
                    myAgent.send(reply);
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
