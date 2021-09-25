package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.core.behaviours.TickerBehaviour;
import jade.domain.DFService;
import jade.domain.FIPAAgentManagement.DFAgentDescription;
import jade.domain.FIPAAgentManagement.SearchConstraints;
import jade.domain.FIPAAgentManagement.ServiceDescription;
import jade.domain.FIPAException;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.MessageTemplate;
import uk.ac.napier.util.Message;

import java.util.logging.Level;
import java.util.logging.Logger;

public class Clock extends Agent {
    final static Logger logger = Logger.getLogger(Clock.class.getName());

    private static final String SETUP_KNOWLEDGE = "setupKnowledge";
    private static final String SETUP_AGENTS = "setupAgents";
    private static final String FINISH = "finish";

    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new SetupKnowledge(this, 1000), SETUP_KNOWLEDGE);
        fsm.registerState(new SetupAgents(this), SETUP_AGENTS);
        fsm.registerLastState(new OneShotBehaviour() {
            @Override
            public void action() {
                logger.info("FSM Done");
            }
        }, FINISH);

        fsm.registerDefaultTransition(SETUP_KNOWLEDGE, SETUP_AGENTS);
        fsm.registerTransition(SETUP_AGENTS, FINISH, 0);
        fsm.registerTransition(SETUP_AGENTS, SETUP_AGENTS, 1, new String[]{SETUP_AGENTS});

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

    private static class SetupAgents extends OneShotBehaviour {
        private final Clock clock;
        private int exitCode;

        public SetupAgents(Clock a) {
            super(a);
            clock = a;
        }

        @Override
        public void onStart() {
            exitCode = 0;
        }

        @Override
        public void action() {
            DFAgentDescription template = new DFAgentDescription();
            ServiceDescription service = new ServiceDescription();
            service.setName("information");
            template.addServices(service);

            SearchConstraints search = new SearchConstraints();
            search.setMaxDepth(1L);
            search.setMaxResults(100L);
            DFAgentDescription[] results;

            try {
                results = DFService.search(clock, clock.getDefaultDF(), template, search);
            } catch(FIPAException e) {
                logger.log(Level.WARNING, "Failed to search for information agents", e);
                return;
            }

            for(DFAgentDescription a : results) {
                ACLMessage message = Message.newMsg(ACLMessage.QUERY_IF, a.getName(), "ready?");
                clock.send(message);
                ACLMessage reply = clock.blockingReceive(MessageTemplate.MatchConversationId(message.getConversationId()));

                logger.info(reply.toString());

                if(!reply.getContent().equals("true")) {
                    exitCode = 1;
                    break;
                }
            }
        }

        @Override
        public int onEnd() {
            return exitCode;
        }
    }
}
