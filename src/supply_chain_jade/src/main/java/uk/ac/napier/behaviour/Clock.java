package uk.ac.napier.behaviour;

import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;

import java.util.logging.Logger;

public class Clock extends Agent {
    final static Logger logger = Logger.getLogger(Clock.class.getName());
    private static final String FINISH = "finish";

    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerLastState(new OneShotBehaviour() {
            @Override
            public void action() {
                logger.info("FSM Done");
            }
        }, FINISH);

        this.addBehaviour(fsm);
    }
}
