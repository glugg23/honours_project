package uk.ac.napier.information;

import jade.core.AID;
import jade.core.Agent;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import jade.wrapper.StaleProxyException;
import uk.ac.napier.behaviours.GenServerBehaviour;
import uk.ac.napier.util.AgentInfo;
import uk.ac.napier.util.Message;

import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Information extends Agent {
    final static Logger logger = Logger.getLogger(Information.class.getName());
    private HashMap<String, AgentInfo> agents;

    @SuppressWarnings("unchecked cast")
    @Override
    protected void setup() {
        Object[] args = this.getArguments();
        String type = (String) args[0];

        ACLMessage filterRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "informationFilter");
        send(filterRequest);
        ACLMessage reply = blockingReceive(MatchConversationId(filterRequest.getConversationId()));
        try {
            agents = (HashMap<String, AgentInfo>) reply.getContentObject();
        } catch(UnreadableException | ClassCastException e) {
            logger.log(Level.WARNING, "Received invalid information filter", e);
        }

        GenServerBehaviour behaviour = new GenServerBehaviour(this) {
            @Override
            public void handle(ACLMessage message) {
                String agentType = message.getSender().getName().split("@")[1];
                AgentInfo info = agents.get(agentType);

                if(!info.getIgnored()) {
                    if(and(MatchPerformative(ACLMessage.QUERY_IF), MatchContent("ready?")).match(message)) {
                        ACLMessage forward = Message.forward(message, new AID("knowledge", AID.ISLOCALNAME));
                        myAgent.send(forward);

                    } else if(MatchPerformative(ACLMessage.INFORM).match(message) && message.getContent().contains("startRound")) {
                        ACLMessage reply = Message.reply(message, ACLMessage.INFORM, "finished");
                        myAgent.send(reply);

                    } else if(and(MatchPerformative(ACLMessage.REQUEST), MatchContent("stop")).match(message)) {
                        //https://jade.tilab.com/pipermail/jade-develop/2013q2/019133.html
                        Thread thread = new Thread(() -> {
                            try {
                                myAgent.getContainerController().kill();
                            } catch(StaleProxyException e) {
                                logger.log(Level.WARNING, "Failed to kill container", e);
                            }
                        });
                        thread.start();

                    } else if(MatchPerformative(ACLMessage.NOT_UNDERSTOOD).match(message)) {
                        logger.warning(message.toString());

                    } else {
                        ACLMessage reply = Message.reply(message, ACLMessage.NOT_UNDERSTOOD, null);
                        myAgent.send(reply);
                    }
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
