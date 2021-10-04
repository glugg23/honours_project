package uk.ac.napier.information;

import jade.core.AID;
import jade.core.Agent;
import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.GenServerBehaviour;
import uk.ac.napier.util.Message;

import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Information extends Agent {
    final static Logger logger = Logger.getLogger(Information.class.getName());

    @Override
    protected void setup() {
        Object[] args = this.getArguments();
        String type = (String) args[0];

        GenServerBehaviour behaviour = new GenServerBehaviour(this) {
            @Override
            public void handle(ACLMessage message) {
                if(and(MatchPerformative(ACLMessage.QUERY_IF), MatchContent("ready?")).match(message)) {
                    ACLMessage forward = Message.forward(message, new AID("knowledge", AID.ISLOCALNAME));
                    myAgent.send(forward);

                } else if(MatchPerformative(ACLMessage.NOT_UNDERSTOOD).match(message)) {
                    logger.warning(message.toString());

                } else {
                    ACLMessage reply = Message.reply(message, ACLMessage.NOT_UNDERSTOOD, null);
                    myAgent.send(reply);
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
