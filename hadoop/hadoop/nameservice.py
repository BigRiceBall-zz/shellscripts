class Nameservice:

    def __init__(self, name):
        self.name = name
        self.namenodes = []
        self.journalnodes = []
        self.resourcemanagers = []
        # self.zookeepers = []
        self.hostnames = {}
        self.HAenable = False

    def __repr__(self):
        return str(self)

    def __str__(self):
        return "<name: %s, namenodes: %s>" % (self.name, self.namenodes)

    def addNode(self, type, node):
        if type == "namenode":
            self.namenodes.append(node)
        elif type == "journalnode":
            self.journalnodes.append(node)
        elif type == "resourcemanager":
            self.resourcemanagers.append(node)
        # elif type == "zookeeper":
        #     self.zookeepers.append(node)

    def getNamenodesID(self):
        str = ""
        for namenode in self.namenodes[:-1]:
            str += namenode.id + ","
        else:
            str += self.namenodes[-1].id
        return str

    def getJournalnodesHost(self):
        str = "qjournal://"
        for journalnode in self.journalnodes[:-1]:
            str += journalnode.hostname + ":8485;"
        else:
            str += self.journalnodes[-1].hostname + ":8485/" + self.name
        return str

    # def getZookeepersHost(self):
    #     str = ""
    #     for zookeeper in self.zookeepers[:-1]:
    #         str += zookeeper.hostname + ":2181,"
    #     else:
    #         str += self.zookeepers[-1].hostname + ":2181"
    #     return str

    def setHostnames(self):
        for namenode in self.namenodes:
            if namenode.ip in self.hostnames:
                self.hostnames[namenode.ip].append(namenode.hostname)
            else:
                self.hostnames[namenode.ip] = []
                self.hostnames[namenode.ip].append(namenode.hostname)
        for journalnode in self.journalnodes:
            if journalnode.ip in self.hostnames:
                self.hostnames[journalnode.ip].append(journalnode.hostname)
            else:
                self.hostnames[journalnode.ip] = []
                self.hostnames[journalnode.ip].append(journalnode.hostname)
        # for zookeeper in self.zookeepers:
        #     if zookeeper.ip in self.hostnames:
        #         self.hostnames[zookeeper.ip].append(zookeeper.hostname)
        #     else:
        #         self.hostnames[zookeeper.ip] = []
        #         self.hostnames[zookeeper.ip].append(zookeeper.hostname)
        for resourcemanager in self.resourcemanagers:
            if resourcemanager.ip in self.hostnames:
                self.hostnames[resourcemanager.ip].append(resourcemanager.hostname)
            else:
                self.hostnames[resourcemanager.ip] = []
                self.hostnames[resourcemanager.ip].append(resourcemanager.hostname)

    def setHAenable(self):
        if len(self.namenodes) == 0:
            raise Exception("The number of namenodes in one cluster is 0!")
        elif len(self.namenodes) == 1:
            self.HAenable = False
        elif len(self.namenodes) == 2:
            self.HAenable = True
        elif len(self.namenodes) > 3:
            raise Exception("The number of namenodes in one cluster is more 2!")

    def validate(self):
        self.illegal = False
        all = self.namenodes + self.journalnodes + self.resourcemanagers
        self.illegal = reduce(lambda x, y : x and y, map(lambda x : x.illegal, all), True)
        if self.HAenable and (len(self.journalnodes) == 0):
            self.illegal = False
        elif not self.HAenable and (len(self.journalnodes) > 0):
            self.illegal = False
        if self.illegal == False:
            raise Exception('''ConfigureError: Your configuration is illegal. NOTE: If HA is enable ''' +
            '''(contains Two namenode in a nameservice), your have to provide ZK and journalnode.''')

# if __name__ == "__main__":
#     from node import *
#     test = Nameservice("test")
#     test.addNode("namenode", Node(1, "192.168.1.31", 1, "namenode"))
#     test.addNode("namenode", Node(1, "192.168.1.31", 1, "namenode"))
#     test.addNode("journalnode", Node(1, "192.168.1.31", 1, "journalnode"))
#     # test.addNode("zookeeper", Node(1, "192.168.1.31", 1, "zookeeper"))
#     test.setHAenable()
#     test.validate()
#     print 1 + 2
#     print test.HAenable
#     print test.illegal
