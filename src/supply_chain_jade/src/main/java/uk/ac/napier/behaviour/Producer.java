package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.AgentInfo;
import uk.ac.napier.util.Message;
import uk.ac.napier.util.Request;
import uk.ac.napier.util.State;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Producer extends Agent {
    final static Logger logger = Logger.getLogger(Producer.class.getName());
    private static final String START_ROUND = "startRound";
    private static final String SEND_FINISH_MSG = "sendFinishMsg";
    private static final String SEND_NEW_FIGURES = "sendNewFigures";
    private State state;
    private HashMap<String, AgentInfo> agents;
    private ACLMessage roundMsg;

    @SuppressWarnings("unchecked cast")
    @Override
    protected void setup() {
        ACLMessage agentRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "informationFilter");
        send(agentRequest);
        ACLMessage agentReply = blockingReceive(MatchConversationId(agentRequest.getConversationId()));
        try {
            agents = (HashMap<String, AgentInfo>) agentReply.getContentObject();
            agents.remove("producer");
        } catch(UnreadableException | ClassCastException e) {
            logger.log(Level.WARNING, "Received invalid information filter", e);
        }

        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new StartRound(this), START_ROUND);
        fsm.registerState(new SendNewFigures(this), SEND_NEW_FIGURES);
        fsm.registerState(new SendFinishMsg(this), SEND_FINISH_MSG);

        fsm.registerDefaultTransition(START_ROUND, SEND_NEW_FIGURES);
        fsm.registerDefaultTransition(SEND_NEW_FIGURES, SEND_FINISH_MSG);
        fsm.registerDefaultTransition(SEND_FINISH_MSG, START_ROUND);

        this.addBehaviour(fsm);
    }

    private static class StartRound extends OneShotBehaviour {
        private final Producer producer;

        public StartRound(Producer a) {
            super(a);
            producer = a;
        }

        @Override
        public void action() {
            producer.roundMsg = producer.blockingReceive(and(MatchPerformative(ACLMessage.INFORM),
                    MatchSender(new AID("behaviour@clock", AID.ISGUID))));

            ACLMessage stateRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "state");
            producer.send(stateRequest);
            ACLMessage reply = producer.blockingReceive(MatchConversationId(stateRequest.getConversationId()));

            try {
                producer.state = (State) reply.getContentObject();
            } catch(UnreadableException e) {
                logger.log(Level.WARNING, "Received invalid state", e);
            }
        }
    }

    private static class SendNewFigures extends OneShotBehaviour {
        private final Producer producer;

        public SendNewFigures(Producer a) {
            super(a);
            producer = a;
        }

        @Override
        public void action() {
            HashMap<String, Integer> storage = producer.state.getStorage();
            HashMap<String, Integer> components = producer.state.getComponents();
            String produces = producer.state.getProduces();

            int quantity = storage.getOrDefault(produces, 0) + 1;
            double price = components.get(produces).doubleValue();
            price = price * ((double) quantity / producer.state.getProductionCapacity() + 1);
            BigDecimal bd = new BigDecimal(price).setScale(2, RoundingMode.HALF_UP);
            price = bd.doubleValue();

            Request request = new Request("selling", produces, quantity, price, producer.state.getRound());
            String requestString;

            try {
                requestString = request.intoString();
            } catch(IOException e) {
                logger.log(Level.WARNING, "Failed to serialise request", e);
                return;
            }

            for(AgentInfo agent : producer.agents.values()) {
                ACLMessage message = Message.newMsg(ACLMessage.INFORM, agent.toAID(), requestString);
                producer.send(message);
            }
        }
    }

    private static class SendFinishMsg extends OneShotBehaviour {
        private final Producer producer;

        public SendFinishMsg(Producer a) {
            super(a);
            producer = a;
        }

        @Override
        public void action() {
            try {
                ACLMessage stateMsg = Message.newMsg(ACLMessage.INFORM, new AID("knowledge", AID.ISLOCALNAME), producer.state);
                producer.send(stateMsg);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise state", e);
            }

            ACLMessage reply = Message.reply(producer.roundMsg, ACLMessage.INFORM, "finished");
            producer.send(reply);
        }
    }
}
