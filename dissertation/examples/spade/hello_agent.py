import time
from counter import Counter
from partner import Partner

if __name__ == "__main__":
    partner = Partner("partner@localhost", "password")
    partner_fut = partner.start()
    partner_fut.result()

    counter = Counter("counter@localhost", "password")
    counter_fut = counter.start()
    counter_fut.result()

    while not (counter.behaviour.is_killed() and partner.behaviour.is_killed()):
        try:
            time.sleep(1)
        except KeyboardInterrupt:
            break

    counter.stop()
    partner.stop()
