package uk.ac.napier.information;

import jade.core.AID;
import jade.core.Agent;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.behaviours.GenServerBehaviour;
import uk.ac.napier.util.AgentInfo;
import uk.ac.napier.util.Message;

import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.MatchConversationId;
import static jade.lang.acl.MessageTemplate.MatchPerformative;

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
                    if(MatchPerformative(ACLMessage.NOT_UNDERSTOOD).match(message)) {
                        logger.warning(message.toString());

                    } else {
                        ACLMessage forward = Message.forward(message, new AID("knowledge", AID.ISLOCALNAME));
                        myAgent.send(forward);
                    }
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
