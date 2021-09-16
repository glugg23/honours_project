package uk.ac.napier.behaviour;

import jade.core.Agent;

public class Consumer extends Agent {
    @Override
    protected void setup() {
        System.out.println(this.getName());
    }
}
