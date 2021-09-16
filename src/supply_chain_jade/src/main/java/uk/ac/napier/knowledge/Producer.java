package uk.ac.napier.knowledge;

import jade.core.Agent;

public class Producer extends Agent {
    @Override
    protected void setup() {
        System.out.println(this.getName());
    }
}
