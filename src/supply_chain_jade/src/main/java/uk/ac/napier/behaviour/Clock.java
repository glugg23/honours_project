package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.behaviours.GenServerBehaviour;
import uk.ac.napier.util.AgentInfo;
import uk.ac.napier.util.Message;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Clock extends Agent {
    final static Logger logger = Logger.getLogger(Clock.class.getName());
    private static final String ASK_READY = "askReady";
    private static final String START_ROUND = "startRound";
    private static final String FINISH_ROUND = "finishRound";
    private static final String STOP_AGENTS = "stopAgents";
    private int maxRounds;
    private HashMap<String, AgentInfo> agents;
    private int round = 0;

    @SuppressWarnings("unchecked cast")
    @Override
    protected void setup() {
        ACLMessage filterRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "informationFilter");
        send(filterRequest);
        ACLMessage filterReply = blockingReceive(MatchConversationId(filterRequest.getConversationId()));
        try {
            agents = (HashMap<String, AgentInfo>) filterReply.getContentObject();
            agents.remove("clock");
        } catch(UnreadableException | ClassCastException e) {
            logger.log(Level.WARNING, "Received invalid information filter", e);
        }

        ACLMessage maxRoundsRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "maxRounds");
        send(maxRoundsRequest);
        ACLMessage roundsReply = blockingReceive(MatchConversationId(maxRoundsRequest.getConversationId()));
        maxRounds = Integer.parseInt(roundsReply.getContent());

        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new AskReady(this), ASK_READY);
        fsm.registerState(new StartRound(this), START_ROUND);
        fsm.registerState(new FinishRound(this), FINISH_ROUND);
        fsm.registerLastState(new StopAgents(this), STOP_AGENTS);

        fsm.registerTransition(ASK_READY, START_ROUND, 0);
        fsm.registerTransition(ASK_READY, ASK_READY, 1);
        fsm.registerDefaultTransition(START_ROUND, FINISH_ROUND, new String[]{FINISH_ROUND});
        fsm.registerTransition(FINISH_ROUND, START_ROUND, 0);
        fsm.registerTransition(FINISH_ROUND, STOP_AGENTS, 1);

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

    private static class StartRound extends OneShotBehaviour {
        private final Clock clock;

        public StartRound(Clock a) {
            super(a);
            clock = a;
        }

        @Override
        public void action() {
            clock.round += 1;

            logger.info("Start round " + clock.round);

            if(clock.round == 1) {
                logger.info("MEASURE=round,cpu_usage,memory");
            }

            for(AgentInfo info : clock.agents.values()) {
                ACLMessage message = Message.newMsg(ACLMessage.INFORM, info.toAID(), "startRound," + clock.round);
                clock.send(message);
            }
        }
    }

    private static class FinishRound extends GenServerBehaviour {
        private final Clock clock;
        private final Set<String> totalAgents;
        private Set<String> finishedAgents;
        private int exitCode = 0;

        public FinishRound(Clock a) {
            super(a);
            clock = a;
            totalAgents = clock.agents.keySet();
        }

        @Override
        public void onStart() {
            finishedAgents = new HashSet<>();
        }

        @Override
        public void handle(ACLMessage message) {
            if(and(MatchPerformative(ACLMessage.INFORM), MatchContent("finished")).match(message)) {
                String agentType = message.getSender().getName().split("@")[1];
                finishedAgents.add(agentType);

                if(clock.round == clock.maxRounds) {
                    exitCode = 1;
                }
            }
        }

        @Override
        public boolean done() {
            return finishedAgents.equals(totalAgents);
        }

        @Override
        public int onEnd() {
            return exitCode;
        }
    }

    private static class StopAgents extends OneShotBehaviour {
        private final Clock clock;

        public StopAgents(Clock a) {
            super(a);
            clock = a;
        }

        @Override
        public void action() {
            logger.info("Stopping all nodes");

            for(AgentInfo info : clock.agents.values()) {
                ACLMessage message = Message.newMsg(ACLMessage.REQUEST, info.toAID(), "stop");
                clock.send(message);
            }

            ACLMessage message = Message.newMsg(ACLMessage.REQUEST, new AID("information", AID.ISLOCALNAME), "stop");
            clock.send(message);
        }
    }
}
