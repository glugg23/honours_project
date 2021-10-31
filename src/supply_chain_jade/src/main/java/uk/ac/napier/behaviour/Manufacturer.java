package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.Message;
import uk.ac.napier.util.State;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import static jade.lang.acl.MessageTemplate.*;

public class Manufacturer extends Agent {
    final static Logger logger = Logger.getLogger(Manufacturer.class.getName());
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
        private final Manufacturer manufacturer;

        public StartRound(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            manufacturer.roundMsg = manufacturer.blockingReceive(and(MatchPerformative(ACLMessage.INFORM),
                    MatchSender(new AID("behaviour@clock", AID.ISGUID))));

            ACLMessage stateRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "state");
            manufacturer.send(stateRequest);
            ACLMessage reply = manufacturer.blockingReceive(MatchConversationId(stateRequest.getConversationId()));

            try {
                manufacturer.state = (State) reply.getContentObject();
            } catch(UnreadableException e) {
                logger.log(Level.WARNING, "Received invalid state", e);
            }
        }
    }

    private static class SendFinishMsg extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public SendFinishMsg(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            manufacturer.state.deleteInboxBeforeRound();

            try {
                ACLMessage stateMsg = Message.newMsg(ACLMessage.INFORM, new AID("knowledge", AID.ISLOCALNAME), manufacturer.state);
                manufacturer.send(stateMsg);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise state", e);
            }

            ACLMessage reply = Message.reply(manufacturer.roundMsg, ACLMessage.INFORM, "finished");
            manufacturer.send(reply);
        }
    }
}
