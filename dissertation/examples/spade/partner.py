from spade.agent import Agent
from spade.behaviour import CyclicBehaviour

class Partner(Agent):
    class Behaviour(CyclicBehaviour):
        async def run(self):
            msg = await self.receive(timeout=1)

            if msg is not None:
                if msg.body == 'Hello':
                    print("[{}] Say hello!".format(self.agent.jid))
                    reply = msg.make_reply()
                    reply.body = 'Hello'
                    await self.send(reply)
                elif msg.body == 'Die':
                    print("[{}] is dying".format(self.agent.jid))
                    self.kill(exit_code=0)

    async def setup(self):
        print("[{}] Starting".format(self.jid))
        self.behaviour = self.Behaviour()
        self.add_behaviour(self.behaviour)
