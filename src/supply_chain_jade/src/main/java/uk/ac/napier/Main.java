package uk.ac.napier;

import jade.core.Profile;
import jade.core.ProfileImpl;
import jade.core.Runtime;

public class Main {
    public static void main(String[] args) {
        Runtime runtime = Runtime.instance();

        Profile profile = new ProfileImpl();
        String name = System.getenv("NAME");
        String platform = System.getenv("PLATFORM");
        profile.setParameter(Profile.AGENTS, name + ":uk.ac.napier.MyAgent");
        profile.setParameter(Profile.PLATFORM_ID, platform);

        runtime.setCloseVM(true);
        runtime.createMainContainer(profile);
    }
}
