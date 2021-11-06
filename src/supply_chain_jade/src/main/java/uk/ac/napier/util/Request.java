package uk.ac.napier.util;

import java.io.*;
import java.util.Base64;

public class Request implements Serializable, Comparable<Request> {
    private final String type;
    private final String good;
    private final int quantity;
    private final double price;
    private final int round;

    public Request(String type, String good, int quantity, double price, int round) {
        this.type = type;
        this.good = good;
        this.quantity = quantity;
        this.price = price;
        this.round = round;
    }

    public static Request fromString(String request) throws IOException, ClassNotFoundException {
        byte[] data = Base64.getDecoder().decode(request);
        ObjectInputStream objectStream = new ObjectInputStream(new ByteArrayInputStream(data));
        Object o = objectStream.readObject();
        objectStream.close();
        return (Request) o;
    }

    public String intoString() throws IOException {
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
        ObjectOutputStream objectStream = new ObjectOutputStream(byteStream);
        objectStream.writeObject(this);
        objectStream.close();
        return Base64.getEncoder().encodeToString(byteStream.toByteArray());
    }

    public String getType() {
        return type;
    }

    public String getGood() {
        return good;
    }

    public int getQuantity() {
        return quantity;
    }

    public double getPrice() {
        return price;
    }

    public int getRound() {
        return round;
    }

    @Override
    public int compareTo(Request o) {
        return Double.compare(price, o.price);
    }

    @Override
    public String toString() {
        return "Request{" +
                "type='" + type + '\'' +
                ", good='" + good + '\'' +
                ", quantity=" + quantity +
                ", price=" + price +
                ", round=" + round +
                '}';
    }
}
