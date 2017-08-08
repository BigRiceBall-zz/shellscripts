import os
from lxml import etree


from node import *
from nameservice import *

path = str.strip(os.popen("cd -P -- \"$(dirname -- \"$0\")\" && pwd -P").readlines()[0])
parser = etree.XMLParser(remove_blank_text=True)
hdfs_tree = etree.parse(path + "/conf/hadoop/hdfs-site.xml", parser)
hdfs_root = hdfs_tree.getroot()
core_tree = etree.parse(path + "/conf/hadoop/core-site.xml", parser)
core_root = core_tree.getroot()
yarn_tree = etree.parse(path + "/conf/hadoop/yarn-site.xml", parser)
yarn_root = yarn_tree.getroot()
mapred_tree = etree.parse(path + "/conf/hadoop/mapred-site.xml", parser)
mapred_root = mapred_tree.getroot()
config_tree = etree.parse(path + "/clients/clients.xml", parser)
config_root = config_tree.getroot()

class Configuration:

    def __init__(self, root):
        self.root = root
        self.nameservices = []
        self.datanodes = []
        self.zookeepers = []
        self.addNameservices()
        self.addNodes_("datanodes")
        self.addNodes_("zookeepers")
        self.addNode("jobhistory")
        self.setAllNodesIp()
        self.setHostNamenode()
        self.setClients()

    def setHostNamenode(self):
        for nameservice in self.nameservices:
            for namenode in nameservice.namenodes:
                if self.getIP() == namenode.ip:
                    self.namenode = namenode

    def getIP(self):
        cmd = "ip route get 8.8.8.8 | head -1 | cut -d' ' -f8"
        ip = os.popen(cmd).readlines()[0].translate(None, '\n')
        return ip

    def addNameservices(self):
        nameservices = self.root.find("nameservices")
        for nameservice_ in nameservices:
            nameservice = Nameservice(nameservice_.get("name"))
            self.addNodes(nameservice_.find("namenodes"), nameservice, "namenode")
            self.addNodes(nameservice_.find("journalnodes"), nameservice, "journalnode")
            # self.addNodes(nameservice_.find("zookeepers"), nameservice, "zookeeper")
            self.addNodes(nameservice_, nameservice, "resourcemanager")
            nameservice.setHostnames()
            nameservice.setHAenable()
            nameservice.validate()
            self.nameservices.append(nameservice)
        self.HAenable = reduce(lambda x, y : x or y, map(lambda x : x.HAenable, self.nameservices), False)


    def addNodes(self, tree, nameservice, type):
        try:
          tree.findall(type)
        except AttributeError:
          return
        for index, node_ in enumerate(tree.findall(type)):
            id = node_.get("id")
            if id == None:
                node = Node(type + "-" + str(index+1), node_.get("ip"), nameservice.name + "-" + type + "-" + str(index+1), type)
            else:
                node = Node(id, node_.get("ip"), nameservice.name + "-" + id, type)
            nameservice.addNode(type, node)

    def addNode(self, type, node=None):
        if type == "datanode":
            self.datanodes.append(node)
        elif type == "zookeeper":
            self.zookeepers.append(node)
        elif type == "jobhistory":
            result = self.root.find("jobhistory")
            if result == None:
                self.jobhistory = Node("", self.nameservices[0].namenode[0].ip, "jobhistory", "jobhistory")
            else:
                self.jobhistory = Node("", result.get("ip"), "jobhistory", "jobhistory")

    def addNodes_(self, type):
        node = type[:-1]
        results = self.root.find(type)
        for index, result in enumerate(results):
            id = result.get("id")
            if id == None:
                self.addNode(node, node=Node(node + "-" + str(index+1), result.get("ip"), node + "-" + str(index+1), node))
            else:
                self.addNode(node, node=Node(id, result.get("ip"), result, node))

    def getZookeepersHost(self):
        str = ""
        for zookeeper in self.zookeepers[:-1]:
            str += zookeeper.hostname + ":2181,"
        else:
            str += self.zookeepers[-1].hostname + ":2181"
        return str

    # def addDatanodes(self):
    #     datanodes = self.root.find("datanodes")
    #     for index, datanode in enumerate(datanodes):
    #         id = datanode.get("id")
    #         if id == None:
    #             self.datanodes.append(Node("datanode-" + str(index+1), datanode.get("ip"), "datanode" + "-" + str(index+1), "datanode"))
    #         else:
    #             self.datanodes.append(Node(datanode.get("id"), datanode.get("ip"), datanode.get("id"), "datanode"))
    #
    # def addJobhistory(self):
    #     result = self.root.find("jobhistory")
    #     if result == None:
    #         self.addNode( "jobhistory", Node("", self.nameservices[0].namenode[0].ip, "jobhistory", "jobhistory"))
    #     else:
    #         self.addNode( "jobhistory", Node("", result.get("ip"), "jobhistory", "jobhistory"))


    def getNameservicesname(self):
        str = ""
        for nameservice in self.nameservices[:-1]:
            str += nameservice.name + ","
        else:
            str += self.nameservices[-1].name
        return str

    def getHosts(self):
        string = []
        for nameservice in self.nameservices:
            for item in nameservice.hostnames.items():
                hostmap = ""
                for hostname in item[1]:
                    hostmap = item[0] + " " + hostname + "\n"
                    string.append(hostmap)
        for datanode in self.datanodes:
            hostmap = datanode.ip + " " + datanode.hostname + "\n"
            string.append(hostmap)
        for zookeeper in self.zookeepers:
            hostmap = zookeeper.ip + " " + zookeeper.hostname + "\n"
            string.append(hostmap)
        string.append(self.jobhistory.ip + " " + self.jobhistory.hostname + "\n")
        return string

    def getSlaves(self):
        slaves = []
        for datanode in self.datanodes:
            slave = datanode.hostname + "\n"
            slaves.append(slave)
        return slaves

    def writeHosts(self):
        if os.path.isfile(path + "/conf/hadoop/hosts"):
            os.remove(path + "/conf/hadoop/hosts")
        with open(path + "/conf/hadoop/hosts", "w") as file:
            newhosts = self.getHosts()
            newhosts.insert(0, "127.0.0.1 localhost\n")
            file.writelines(newhosts)

    def writeSlaves(self):
        if os.path.isfile(path + "/conf/hadoop/slaves"):
            os.remove(path + "/conf/hadoop/slaves")
        with open(path + "/conf/hadoop/slaves", "w") as file:
            slaves = self.getSlaves()
            file.writelines(slaves)

    # def setAll(self):
    #     self.all = set()
    #     for nameservice in self.nameservices:
    #         for namenode in nameservice.namenodes:
    #             self.allNodesIp.add(namenode.ip)
    #         for journalnode in nameservice.journalnodes:
    #             self.allNodesIp.add(journalnode.ip)
    #         for resourcemanager in nameservice.resourcemanagers:
    #             self.allNodesIp.add(resourcemanager.ip)
    #         for zookeeper in nameservice.zookeepers:
    #             self.allNodesIp.add(zookeeper.ip)
    #     for datanode in self.datanodes:
    #         self.allNodesIp.add(namenode.ip)
    #     self.allNodesIp.add(self.jobhistory.ip)

    def setAllNodesIp(self):
        self.allNodesIp = set()
        for nameservice in self.nameservices:
            for namenode in nameservice.namenodes:
                self.allNodesIp.add(namenode.ip)
            for journalnode in nameservice.journalnodes:
                self.allNodesIp.add(journalnode.ip)
            for resourcemanager in nameservice.resourcemanagers:
                self.allNodesIp.add(resourcemanager.ip)
        for zookeeper in self.zookeepers:
            self.allNodesIp.add(zookeeper.ip)
        for datanode in self.datanodes:
            self.allNodesIp.add(namenode.ip)
        self.allNodesIp.add(self.jobhistory.ip)

    def setClients(self):
        self.clients = {}
        for nameservice in self.nameservices:
            for namenode in nameservice.namenodes:
                if self.namenode.ip != namenode.ip and not namenode.ip in self.clients:
                    self.clients[namenode.ip] = namenode.hostname
            for resourcemanager in nameservice.resourcemanagers:
                if self.namenode.ip != resourcemanager.ip and not resourcemanager.ip in self.clients:
                    self.clients[resourcemanager.ip] = resourcemanager.hostname
        for datanode in self.datanodes:
            if self.namenode.ip != datanode.ip and not datanode.ip in self.clients:
                self.clients[datanode.ip] = datanode.hostname
        for nameservice in self.nameservices:
            for journalnode in nameservice.journalnodes:
                if self.namenode.ip != journalnode.ip and not journalnode.ip in self.clients:
                    self.clients[journalnode.ip] = journalnode.hostname
        if self.namenode.ip != self.jobhistory.ip and not self.jobhistory.ip in self.clients:
            self.clients[jobhistory.ip] = jobhistory.hostname


    def __repr__(self):
        return str(self)

    def __str__(self):
        return "Nameservices: %s %s" % (self.nameservices, self.datanodes)
