class Node:

    def __init__(self, id, ip, hostname, type):
        self.id = id
        self.ip = ip
        self.hostname = hostname
        self.type = type

    def __repr__(self):
        return str(self)

    def __str__(self):
        return "<IP: %s, id: %s, hostname: %s, type: %s>" % (self.ip, self.id, self.hostname, self.type)
