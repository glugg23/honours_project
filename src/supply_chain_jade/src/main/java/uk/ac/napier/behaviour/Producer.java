package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.Message;
import uk.ac.napier.util.State;

import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Producer extends Agent {
    final static Logger logger = Logger.getLogger(Producer.class.getName());
    private static final String START_ROUND = "startRound";
    private static final String SEND_FINISH_MSG = "sendFinishMsg";
    private State state;
    private ACLMessage roundMsg;

    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new StartRound(this), START_ROUND);
        fsm.registerState(new SendFinishMsg(this), SEND_FINISH_MSG);

        fsm.registerDefaultTransition(START_ROUND, SEND_FINISH_MSG);
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

    private static class SendFinishMsg extends OneShotBehaviour {
        private final Producer producer;

        public SendFinishMsg(Producer a) {
            super(a);
            producer = a;
        }

        @Override
        public void action() {
            ACLMessage reply = Message.reply(producer.roundMsg, ACLMessage.INFORM, "finished");
            producer.send(reply);
        }
    }
}
