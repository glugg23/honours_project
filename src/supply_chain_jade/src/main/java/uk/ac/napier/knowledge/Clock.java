package uk.ac.napier.knowledge;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.KnowledgeBehaviour;
import uk.ac.napier.util.Message;

import static jade.lang.acl.MessageTemplate.*;

public class Clock extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        KnowledgeBehaviour behaviour = new KnowledgeBehaviour(this) {
            @Override
            public void handleOther(ACLMessage message) {
                if(and(MatchPerformative(ACLMessage.REQUEST), MatchContent("maxRounds")).match(message)) {
                    ACLMessage reply = Message.reply(message, ACLMessage.INFORM, properties.getProperty("clock.maxRounds"));
                    myAgent.send(reply);

                } else {
                    ACLMessage reply = Message.reply(message, ACLMessage.NOT_UNDERSTOOD, null);
                    myAgent.send(reply);
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
