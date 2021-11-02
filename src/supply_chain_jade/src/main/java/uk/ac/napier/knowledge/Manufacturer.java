package uk.ac.napier.knowledge;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.KnowledgeBehaviour;
import uk.ac.napier.util.Mail;
import uk.ac.napier.util.Message;
import uk.ac.napier.util.Request;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.stream.Collectors;

import static jade.lang.acl.MessageTemplate.*;

public class Manufacturer extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        KnowledgeBehaviour behaviour = new KnowledgeBehaviour(this) {
            @Override
            public void handleOther(ACLMessage message) {
                if(and(MatchPerformative(ACLMessage.REQUEST), MatchContent("refreshInbox")).match(message)) {
                    HashMap<String, Mail> inbox = (HashMap<String, Mail>) state.getInbox().entrySet().stream()
                            .filter(kv -> kv.getValue().getRound() <= state.getRound())
                            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

                    try {
                        ACLMessage reply = Message.reply(message, ACLMessage.INFORM, inbox);
                        myAgent.send(reply);

                    } catch(IOException e) {
                        logger.log(Level.WARNING, "Failed to serialise inbox", e);
                    }

                } else {
                    Request request = null;
                    try {
                        request = Request.fromString(message.getContent());
                    } catch(Exception ignored) {
                    }

                    state.addToInbox(message.getConversationId(), new Mail(message, request, state.getRound()));
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
