package uk.ac.napier.behaviours;

import jade.lang.acl.ACLMessage;
import uk.ac.napier.Message;
import uk.ac.napier.knowledge.Knowledge;

import java.util.logging.Logger;

public abstract class KnowledgeBehaviour extends GenServerBehaviour {
    final static Logger logger = Logger.getLogger(KnowledgeBehaviour.class.getName());
    private final Knowledge knowledge;

    public KnowledgeBehaviour(Knowledge a) {
        super(a);
        knowledge = a;
    }

    @Override
    public void handle(ACLMessage message) {
        if(message.getPerformative() == ACLMessage.QUERY_IF && message.getContent().equals("ready?")) {
            ACLMessage reply = Message.reply(message, ACLMessage.INFORM, Boolean.toString(knowledge.isReady()));
            knowledge.send(reply);

        } else if(message.getPerformative() == ACLMessage.NOT_UNDERSTOOD) {
            logger.warning(message.toString());

        } else {
            handleOther(message);
        }
    }

    public abstract void handleOther(ACLMessage message);
}
