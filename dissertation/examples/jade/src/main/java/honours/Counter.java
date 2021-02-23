package honours;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.OneShotBehaviour;
import jade.core.behaviours.SequentialBehaviour;
import jade.core.behaviours.TickerBehaviour;
import jade.lang.acl.ACLMessage;
import jade.util.Logger;

import java.util.logging.Level;

public class Counter extends Agent {
    private final Logger logger = Logger.getJADELogger(this.getClass().getName());

    @Override
    protected void setup() {
        super.setup();
        logger.setLevel(Level.INFO);

        logger.info("[" + getLocalName() + "] Starting");

        SequentialBehaviour behaviour = new SequentialBehaviour(this);

        behaviour.addSubBehaviour(new OneShotBehaviour(this) {
            @Override
            public void action() {
                ACLMessage helloMsg = new ACLMessage(ACLMessage.INFORM);
                helloMsg.addReceiver(new AID("PARTNER", AID.ISLOCALNAME));
                helloMsg.setContent("Hello");
                send(helloMsg);

                ACLMessage reply;
                do {
                    reply = blockingReceive();

                } while(!reply.getContent().equals("Hello"));

                logger.info("[" + getLocalName() + "] found another agent " + reply.getSender());
                logger.info("[" + getLocalName() + "] I'm " + myAgent.getAID());
            }
        });

        behaviour.addSubBehaviour(new TickerBehaviour(this, 1000) {
            protected int count = 0;

            @Override
            public void onStart() {
                super.onStart();
                logger.info("[" + getLocalName() + "] Starting to count");
            }

            @Override
            protected void onTick() {
                logger.info("[" + getLocalName() + "] count => " + count);

                if(count == 3) {
                    logger.info("[" + getLocalName() + "] orders Partner to die");

                    ACLMessage dieMsg = new ACLMessage(ACLMessage.INFORM);
                    dieMsg.addReceiver(new AID("PARTNER", AID.ISLOCALNAME));
                    dieMsg.setContent("Die");
                    send(dieMsg);

                    myAgent.doDelete();

                } else {
                    count++;
                }
            }
        });

        addBehaviour(behaviour);
    }
}
