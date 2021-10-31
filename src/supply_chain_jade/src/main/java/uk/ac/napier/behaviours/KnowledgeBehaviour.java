package uk.ac.napier.behaviours;

import jade.core.AID;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.knowledge.Knowledge;
import uk.ac.napier.util.Message;
import uk.ac.napier.util.State;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public abstract class KnowledgeBehaviour extends GenServerBehaviour {
    final static Logger logger = Logger.getLogger(KnowledgeBehaviour.class.getName());
    private final Knowledge knowledge;

    public KnowledgeBehaviour(Knowledge a) {
        super(a);
        knowledge = a;
    }

    @Override
    public void handle(ACLMessage message) {
        if(and(MatchPerformative(ACLMessage.QUERY_IF), MatchContent("ready?")).match(message)) {
            ACLMessage reply = Message.reply(message, ACLMessage.INFORM, Boolean.toString(knowledge.isReady()));
            knowledge.send(reply);

        } else if(and(MatchPerformative(ACLMessage.REQUEST), MatchContent("informationFilter")).match(message)) {
            try {
                ACLMessage reply = Message.reply(message, ACLMessage.INFORM, knowledge.getInformationFilter());
                knowledge.send(reply);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise information filter", e);
            }

        } else if(and(MatchPerformative(ACLMessage.REQUEST), MatchContent("state")).match(message)) {
            try {
                ACLMessage reply = Message.reply(message, ACLMessage.INFORM, knowledge.getStateObject());
                knowledge.send(reply);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise state", e);
            }

        } else if(and(MatchPerformative(ACLMessage.INFORM), MatchSender(new AID("behaviour", AID.ISLOCALNAME))).match(message)) {
            try {
                State newState = (State) message.getContentObject();
                knowledge.setStateObject(newState);
            } catch(UnreadableException e) {
                logger.log(Level.WARNING, "Could not deserialise state", e);
            }

        } else if(MatchPerformative(ACLMessage.INFORM).match(message) && message.getContent().contains("startRound")) {
            ACLMessage forward = Message.forward(message, new AID("behaviour", AID.ISLOCALNAME));
            myAgent.send(forward);

        } else if(MatchPerformative(ACLMessage.NOT_UNDERSTOOD).match(message)) {
            logger.warning(message.toString());

        } else {
            handleOther(message);
        }
    }

    public abstract void handleOther(ACLMessage message);
}
