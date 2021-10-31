package uk.ac.napier.knowledge;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.KnowledgeBehaviour;
import uk.ac.napier.util.Mail;

public class Manufacturer extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        KnowledgeBehaviour behaviour = new KnowledgeBehaviour(this) {
            @Override
            public void handleOther(ACLMessage message) {
                state.addToInbox(message.getConversationId(), new Mail(message, state.getRound()));
            }
        };

        this.addBehaviour(behaviour);
    }
}
