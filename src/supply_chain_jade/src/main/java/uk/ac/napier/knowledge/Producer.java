package uk.ac.napier.knowledge;

public class Producer extends Knowledge {
    @Override
    protected void setup() {
        super.setup();
        System.out.println(this.getName());
    }
}
