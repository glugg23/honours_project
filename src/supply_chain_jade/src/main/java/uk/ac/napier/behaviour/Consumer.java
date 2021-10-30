package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import uk.ac.napier.util.Message;

import static jade.lang.acl.MessageTemplate.*;

public class Consumer extends Agent {
    private static final String START_ROUND = "startRound";
    private static final String SEND_FINISH_MSG = "sendFinishMsg";

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
        private final Consumer consumer;

        public StartRound(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            consumer.roundMsg = consumer.blockingReceive(and(MatchPerformative(ACLMessage.INFORM),
                    MatchSender(new AID("behaviour@clock", AID.ISGUID))));
        }
    }

    private static class SendFinishMsg extends OneShotBehaviour {
        private final Consumer consumer;

        public SendFinishMsg(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            ACLMessage reply = Message.reply(consumer.roundMsg, ACLMessage.INFORM, "finished");
            consumer.send(reply);
        }
    }
}
