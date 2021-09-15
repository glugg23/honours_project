package uk.ac.napier;

import jade.core.Agent;

public class Main extends Agent {
    @Override
    protected void setup() {
        System.out.println("Hello from " + this.getAID().getName());
    }
}
