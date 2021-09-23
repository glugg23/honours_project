package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.TickerBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.MessageTemplate;
import uk.ac.napier.Message;

public class Clock extends Agent {
    private static final String SETUP_KNOWLEDGE = "setupKnowledge";

    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new SetupKnowledge(this, 1000), SETUP_KNOWLEDGE);

        this.addBehaviour(fsm);
    }

    private static class SetupKnowledge extends TickerBehaviour {
        public SetupKnowledge(Agent a, long period) {
            super(a, period);
        }

        @Override
        protected void onTick() {
            ACLMessage message = Message.newMsg(ACLMessage.QUERY_IF, new AID("knowledge", AID.ISLOCALNAME), "ready?");
            myAgent.send(message);
            ACLMessage reply = myAgent.blockingReceive(MessageTemplate.MatchConversationId(message.getConversationId()));
            if(reply.getContent().equals("true")) {
                this.stop();
            }
        }
    }
}
