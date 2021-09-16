package uk.ac.napier.information;

import jade.core.Agent;

public class Information extends Agent {
    @Override
    protected void setup() {
        System.out.println(this.getName());
    }
}
