package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.AgentInfo;
import uk.ac.napier.util.Message;

import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Clock extends Agent {
    final static Logger logger = Logger.getLogger(Clock.class.getName());
    private static final String ASK_READY = "askReady";
    private static final String FINISH = "finish";
    private HashMap<String, AgentInfo> agents;

    @SuppressWarnings("unchecked cast")
    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        ACLMessage filterRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "informationFilter");
        send(filterRequest);
        ACLMessage reply = blockingReceive(MatchConversationId(filterRequest.getConversationId()));
        try {
            agents = (HashMap<String, AgentInfo>) reply.getContentObject();
            agents.remove("clock");
        } catch(UnreadableException | ClassCastException e) {
            logger.log(Level.WARNING, "Received invalid information filter", e);
        }

        fsm.registerFirstState(new AskReady(this), ASK_READY);
        fsm.registerLastState(new OneShotBehaviour() {
            @Override
            public void action() {
                logger.info("FSM Done");
            }
        }, FINISH);

        fsm.registerTransition(ASK_READY, FINISH, 0);
        fsm.registerTransition(ASK_READY, ASK_READY, 1);

        this.addBehaviour(fsm);
    }

    private static class AskReady extends OneShotBehaviour {
        private final Clock clock;
        private int exitCode;

        public AskReady(Clock a) {
            super(a);
            clock = a;
        }

        @Override
        public void action() {
            exitCode = 0;

            for(AgentInfo info : clock.agents.values()) {
                ACLMessage message = Message.newMsg(ACLMessage.QUERY_IF, info.toAID(), "ready?");
                clock.send(message);
                ACLMessage reply = clock.blockingReceive(MatchConversationId(message.getConversationId()));

                if(or(not(MatchContent("true")), MatchPerformative(ACLMessage.FAILURE)).match(reply)) {
                    exitCode = 1;
                    return;
                }
            }
        }

        @Override
        public int onEnd() {
            if(exitCode == 0) {
                logger.info("All nodes ready");
            }
            return exitCode;
        }
    }
}
