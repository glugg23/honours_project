package uk.ac.napier.knowledge;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.KnowledgeBehaviour;
import uk.ac.napier.util.Mail;
import uk.ac.napier.util.Request;

public class Producer extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        KnowledgeBehaviour behaviour = new KnowledgeBehaviour(this) {
            @Override
            public void handleOther(ACLMessage message) {
                Request request = null;
                try {
                    request = Request.fromString(message.getContent());
                } catch(Exception ignored) {
                }

                state.addToInbox(message.getConversationId(), new Mail(message, request, state.getRound()));
            }
        };

        this.addBehaviour(behaviour);
    }
}
