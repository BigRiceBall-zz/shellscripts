import re


class Node:

    def __init__(self, id, ip, hostname, type):
        self.id = id
        self.ip = ip
        self.hostname = hostname
        self.type = type
        self.validate()

    def validate(self):
        self.illegal = False
        if re.match("^(\d{1,3}\.){3}\d{1,3}$", self.ip):
            self.illegal = reduce(lambda x, y : x and y, map(lambda x : True if int(x) <= 255 else False, self.ip.split(".")), True)
        if self.illegal == False:
            raise Exception("IP Format Error, " + self.ip + " is illegal.")

    def __repr__(self):
        return str(self)

    def __str__(self):
        return "<IP: %s, id: %s, hostname: %s, type: %s>" % (self.ip, self.id, self.hostname, self.type)

# if __name__ == "__main__":
#     a = Node(1, "192.168.1.300", 1, 1)
#     a.validate()
