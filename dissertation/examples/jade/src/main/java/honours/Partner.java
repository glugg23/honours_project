package honours;

import jade.core.Agent;
import jade.core.behaviours.CyclicBehaviour;
import jade.lang.acl.ACLMessage;
import jade.util.Logger;

import java.util.logging.Level;

public class Partner extends Agent {
    private final Logger logger = Logger.getJADELogger(this.getClass().getName());

    @Override
    protected void setup() {
        super.setup();
        logger.setLevel(Level.INFO);

        logger.info("[" + getLocalName() + "] Starting");

        addBehaviour(new CyclicBehaviour(this) {
            @Override
            public void action() {
                ACLMessage msg = myAgent.receive();

                if(msg != null) {
                    switch(msg.getContent()) {
                        case "Hello":
                            logger.info("[" + getLocalName() + "] Say hello!");
                            ACLMessage reply = msg.createReply();
                            reply.setContent("Hello");
                            send(reply);
                            break;
                        case "Die":
                            logger.info("[" + getLocalName() + "] is dying");
                            myAgent.doDelete();
                            break;
                        default:
                            break;
                    }

                } else {
                    block();
                }
            }
        });
    }
}
