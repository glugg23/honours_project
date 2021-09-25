package uk.ac.napier.knowledge;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.KnowledgeBehaviour;
import uk.ac.napier.util.Message;

public class Consumer extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        KnowledgeBehaviour behaviour = new KnowledgeBehaviour(this) {
            @Override
            public void handleOther(ACLMessage message) {
                ACLMessage reply = Message.reply(message, ACLMessage.NOT_UNDERSTOOD, null);
                myAgent.send(reply);
            }
        };

        this.addBehaviour(behaviour);
    }
}
