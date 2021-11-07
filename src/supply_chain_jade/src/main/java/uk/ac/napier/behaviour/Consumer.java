package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import static jade.lang.acl.MessageTemplate.*;

public class Consumer extends Agent {
    final static Logger logger = Logger.getLogger(Consumer.class.getName());
    private static final String START_ROUND = "startRound";
    private static final String MARK_ORDERS = "markOrders";
    private static final String HANDLE_DELIVERED_ORDERS = "handleDeliveredOrders";
    private static final String HANDLE_LATE_ORDERS = "handleLateOrders";
    private static final String SEND_NEW_ORDERS = "sendNewOrders";
    private static final String SEND_FINISH_MSG = "sendFinishMsg";
    private State state;
    private HashMap<String, AgentInfo> agents;
    private ACLMessage roundMsg;
    private Random random;

    @SuppressWarnings("unchecked cast")
    @Override
    protected void setup() {
        random = new Random();

        ACLMessage agentRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "informationFilter");
        send(agentRequest);
        ACLMessage agentReply = blockingReceive(MatchConversationId(agentRequest.getConversationId()));
        try {
            agents = (HashMap<String, AgentInfo>) agentReply.getContentObject();
            agents.remove("consumer");
        } catch(UnreadableException | ClassCastException e) {
            logger.log(Level.WARNING, "Received invalid information filter", e);
        }

        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new StartRound(this), START_ROUND);
        fsm.registerState(new MarkOrders(this), MARK_ORDERS);
        fsm.registerState(new HandleDeliveredOrders(this), HANDLE_DELIVERED_ORDERS);
        fsm.registerState(new HandleLateOrders(this), HANDLE_LATE_ORDERS);
        fsm.registerState(new SendNewOrders(this), SEND_NEW_ORDERS);
        fsm.registerState(new SendFinishMsg(this), SEND_FINISH_MSG);

        fsm.registerDefaultTransition(START_ROUND, MARK_ORDERS);
        fsm.registerDefaultTransition(MARK_ORDERS, HANDLE_DELIVERED_ORDERS);
        fsm.registerDefaultTransition(HANDLE_DELIVERED_ORDERS, HANDLE_LATE_ORDERS);
        fsm.registerDefaultTransition(HANDLE_LATE_ORDERS, SEND_NEW_ORDERS);
        fsm.registerDefaultTransition(SEND_NEW_ORDERS, SEND_FINISH_MSG);
        fsm.registerDefaultTransition(SEND_FINISH_MSG, START_ROUND);

        this.addBehaviour(fsm);
    }

    private static class StartRound extends OneShotBehaviour {
        private final Consumer consumer;

        public StartRound(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            consumer.roundMsg = consumer.blockingReceive(and(MatchPerformative(ACLMessage.INFORM),
                    MatchSender(new AID("behaviour@clock", AID.ISGUID))));

            ACLMessage stateRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "state");
            consumer.send(stateRequest);
            ACLMessage reply = consumer.blockingReceive(MatchConversationId(stateRequest.getConversationId()));

            try {
                consumer.state = (State) reply.getContentObject();
            } catch(UnreadableException e) {
                logger.log(Level.WARNING, "Received invalid state", e);
            }
        }
    }

    private static class MarkOrders extends OneShotBehaviour {
        private final Consumer consumer;

        public MarkOrders(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            List<Mail> messages = consumer.state.getInbox().values().stream()
                    .filter(mail -> mail.getMessage().getPerformative() == ACLMessage.ACCEPT_PROPOSAL
                            || mail.getMessage().getPerformative() == ACLMessage.REJECT_PROPOSAL)
                    .collect(Collectors.toList());

            for(Mail mail : messages) {
                if(mail.getMessage().getPerformative() == ACLMessage.ACCEPT_PROPOSAL) {
                    consumer.state.setOrderStatus(mail.getMessage().getConversationId(), true);
                } else {
                    consumer.state.deleteOrder(mail.getMessage().getConversationId());
                }
            }
        }
    }

    private static class HandleDeliveredOrders extends OneShotBehaviour {
        private final Consumer consumer;

        public HandleDeliveredOrders(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            List<Mail> deliveredOrders = consumer.state.getInbox().values().stream()
                    .filter(m -> m.getMessage().getPerformative() == ACLMessage.INFORM)
                    .filter(m -> m.getRequest().getType().equals("delivery"))
                    .collect(Collectors.toList());

            HashMap<String, Order> orders = consumer.state.getOrders();

            for(Mail m : deliveredOrders) {
                Order order = orders.get(m.getMessage().getConversationId());

                if(order == null) {
                    logger.warning("Order does not exist: " + m.getRequest());
                    return;
                }

                if(m.getRequest().getGood().equals(order.getRequest().getGood())
                        && m.getRequest().getQuantity() == order.getRequest().getQuantity()) {
                    logger.fine("Delivery for order: " + order.getRequest());
                    consumer.state.subtractMoney(m.getRequest().getPrice() * m.getRequest().getQuantity());

                } else {
                    logger.warning("Incorrect delivery for order: " + order.getRequest());
                }

                consumer.state.deleteOrder(order.getMessage().getConversationId());
            }
        }
    }

    private static class HandleLateOrders extends OneShotBehaviour {
        private final Consumer consumer;

        public HandleLateOrders(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            consumer.state.getOrders().values().stream()
                    .filter(Order::isAccepted)
                    .filter(o -> o.getRequest().getRound() < consumer.state.getRound())
                    .forEach(o -> logger.fine("Order is late: " + o.getRequest()));
        }
    }

    private static class SendNewOrders extends OneShotBehaviour {
        private final Consumer consumer;

        public SendNewOrders(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            for(Map.Entry<String, Integer> kv : consumer.state.getComputers().entrySet()) {
                int quantity = consumer.random.nextInt(consumer.state.getMaximumQuantity());
                double price = kv.getValue() * (consumer.random.nextGaussian() * 0.5 + 2);
                BigDecimal bd = new BigDecimal(price).setScale(2, RoundingMode.HALF_UP);
                price = bd.doubleValue();

                Request request = new Request("buying", kv.getKey(), quantity, price, consumer.state.getRound() + 4);
                ACLMessage message;
                try {
                    message = Message.newMsg(ACLMessage.INFORM, null, request.intoString());
                } catch(IOException e) {
                    logger.log(Level.WARNING, "Failed to serialise request", e);
                    return;
                }

                for(AgentInfo agent : consumer.agents.values()) {
                    message.addReceiver(agent.toAID());
                    message.setSender(consumer.getAID("information"));
                    consumer.send(message);
                }

                consumer.state.addOrder(message.getConversationId(), new Order(message, request, consumer.state.getRound(), false));
            }
        }
    }

    private static class SendFinishMsg extends OneShotBehaviour {
        private final Consumer consumer;

        public SendFinishMsg(Consumer a) {
            super(a);
            consumer = a;
        }

        @Override
        public void action() {
            try {
                ACLMessage stateMsg = Message.newMsg(ACLMessage.INFORM, new AID("knowledge", AID.ISLOCALNAME), consumer.state);
                consumer.send(stateMsg);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise state", e);
            }

            ACLMessage reply = Message.reply(consumer.roundMsg, ACLMessage.INFORM, "finished");
            consumer.send(reply);
        }
    }
}
