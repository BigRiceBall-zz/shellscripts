
import xml.etree.cElementTree as ET
from lxml import etree
import re
import os
import sys
import time


parser = etree.XMLParser(remove_blank_text=True)
hdfs_tree = etree.parse("./hadoopconfigfiles/hdfs-site.xml", parser)
hdfs_root = hdfs_tree.getroot()
core_tree = etree.parse("./hadoopconfigfiles/core-site.xml", parser)
core_root = core_tree.getroot()
yarn_tree = etree.parse("./hadoopconfigfiles/yarn-site.xml", parser)
yarn_root = yarn_tree.getroot()
mapred_tree = etree.parse("./hadoopconfigfiles/mapred-site.xml", parser)
mapred_root = mapred_tree.getroot()
config_tree = etree.parse("./clients/clients.xml", parser)
config_root = config_tree.getroot()

class Nameservice:

    def __init__(self, name):
        self.name = name
        self.namenodes = []
        self.journalnodes = []
        self.resourcemanagers = []
        self.zookeepers = []
        self.hostnames = {}

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
        elif type == "zookeeper":
            self.zookeepers.append(node)


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

    def getZookeepersHost(self):
        str = ""
        for zookeeper in self.zookeepers[:-1]:
            str += zookeeper.hostname + ":2181,"
        else:
            str += self.zookeepers[-1].hostname + ":2181"
        return str

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
        for zookeeper in self.zookeepers:
            if zookeeper.ip in self.hostnames:
                self.hostnames[zookeeper.ip].append(zookeeper.hostname)
            else:
                self.hostnames[zookeeper.ip] = []
                self.hostnames[zookeeper.ip].append(zookeeper.hostname)
        for resourcemanager in self.resourcemanagers:
            if resourcemanager.ip in self.hostnames:
                self.hostnames[resourcemanager.ip].append(resourcemanager.hostname)
            else:
                self.hostnames[resourcemanager.ip] = []
                self.hostnames[resourcemanager.ip].append(resourcemanager.hostname)

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


class Configuration:
    def __init__(self, root):
        self.root = root
        self.nameservices = []
        self.datanodes = []
        self.addNameservices()
        self.addDatanodes()
        self.ip = self.get_ip()
        self.clients = {}
        self.setClients()
        self.addJobhistory()
        self.setHostNamenode()
        self.allMachines = set()
        self.setAllMachines()

    def setHostNamenode(self):
        for nameservice in self.nameservices:
            for namenode in nameservice.namenodes:
                if self.ip == namenode.ip:
                    self.namenode = namenode

    def get_ip(self):
        cmd = "ip route get 8.8.8.8 | head -1 | cut -d' ' -f8"
        ip = os.popen(cmd).readlines()[0].translate(None, '\n')
        return ip

    def addNameservices(self):
        for nameservice_ in self.root.findall("nameservice"):
            nameservice = Nameservice(nameservice_.get("name"))
            self.addNodes(nameservice_, nameservice, "namenode")
            self.addNodes(nameservice_, nameservice, "journalnode")
            self.addNodes(nameservice_, nameservice, "zookeeper")
            self.addNodes(nameservice_, nameservice, "resourcemanager")
            nameservice.setHostnames()
            self.nameservices.append(nameservice)

    def addNodes(self, tree, nameservice, type):
        for index, node_ in enumerate(tree.findall(type)):
            id = node_.get("id")
            if id == None:
                node = Node(type + "-" + str(index+1), node_.get("ip"), nameservice.name + "-" + type + "-" + str(index+1), type)
            else:
                node = Node(id, node_.get("ip"), nameservice.name + "-" + id, type)
            nameservice.addNode(type, node)

    def addDatanodes(self):
        for index, datanode in enumerate(self.root.findall("datanode")):
            id = datanode.get("id")
            if id == None:
                self.datanodes.append(Node("datanode-" + str(index+1), datanode.get("ip"), "datanode" + "-" + str(index+1), "datanode"))
            else:
                self.datanodes.append(Node(datanode.get("id"), datanode.get("ip"), datanode.get("id"), "datanode"))

    def addJobhistory(self):
        result = self.root.find("jobhistory")
        if result == None:
            self.jobhistory = Node("", self.nameservices[0].namenode[0].ip, "jobhistory", "jobhistory")
        else:
            self.jobhistory = Node("", result.get("ip"), "jobhistory", "jobhistory")


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
        string.append(self.jobhistory.ip + " " + self.jobhistory.hostname + "\n")
        return string

    def getSlaves(self):
        slaves = []
        for datanode in self.datanodes:
            slave = datanode.hostname + "\n"
            slaves.append(slave)
        return slaves

    def setClients(self):
        for nameservice in self.nameservices:
            for namenode in nameservice.namenodes:
                if self.ip != namenode.ip and not namenode.ip in self.clients:
                    self.clients[namenode.ip] = namenode.hostname
        for datanode in self.datanodes:
            if self.ip != datanode.ip and not datanode.ip in self.clients:
                self.clients[datanode.ip] = datanode.hostname
        for nameservice in self.nameservices:
            for journalnode in nameservice.journalnodes:
                if self.ip != journalnode.ip and not journalnode.ip in self.clients:
                    self.clients[journalnode.ip] = journalnode.hostname

    def setAllMachines(self):
        for nameservice in self.nameservices:
            for namenode in nameservice.namenodes:
                self.allMachines.add(namenode.ip)
            for journalnode in nameservice.journalnodes:
                self.allMachines.add(journalnode.ip)
            for resourcemanager in nameservice.resourcemanagers:
                self.allMachines.add(resourcemanager.ip)
            for zookeeper in nameservice.zookeepers:
                self.allMachines.add(zookeeper.ip)
        for datanode in self.datanodes:
            self.allMachines.add(namenode.ip)
        self.allMachines.add(self.jobhistory.ip)


    def __repr__(self):
        return str(self)

    def __str__(self):
        return "Nameservices: %s" % self.nameservices

def addProperty(root, name, value):
    property = etree.XML('''<property><name>''' + name + '''</name><value>''' + value + '''</value></property>''')
    root.append(property)

def modifyProperty(root, name, value):
    for property in root:
        for elem in property:
            if re.match(name, elem.text):
                elem.getnext().text = value

def clean(root, pattern):
    for property in root:
        for elem in property:
            if re.match(pattern, elem.text):
                root.remove(property)



def initialise():
    clean(hdfs_root, "dfs.ha.namenodes*")
    clean(hdfs_root, "dfs.namenode.rpc-address*")
    clean(hdfs_root, "dfs.namenode.http-address*")
    clean(hdfs_root, "dfs.namenode.shared.edits.dir*")
    clean(hdfs_root, "dfs.client.failover.proxy.provider*")
    clean(hdfs_root, "dfs.ha.fencing.methods*")
    clean(hdfs_root, "dfs.ha.fencing.ssh.private-key-files*")
    clean(hdfs_root, "dfs.namenode.checkpoint*")
    clean(hdfs_root, "dfs.journalnode.edits.dir*")
    clean(hdfs_root, "dfs.nameservices*")
    clean(hdfs_root, "dfs.ha.automatic-failover.enabled*")
    clean(core_root, "ha.zookeeper.quorum*")

def setnamenodeHA():
    addProperty(hdfs_root, "dfs.nameservices", config.getNameservicesname())
    for nameservice in config.nameservices:
        addProperty(hdfs_root, "dfs.ha.namenodes." + nameservice.name, nameservice.getNamenodesID())
        for namenode in nameservice.namenodes:
            addProperty(hdfs_root, "dfs.namenode.rpc-address." + nameservice.name + "." + namenode.id,
                        namenode.hostname + ":8020")
            addProperty(hdfs_root, "dfs.namenode.http-address." + nameservice.name + "." + namenode.id,
                        namenode.hostname + ":50070")
        addProperty(hdfs_root, "dfs.namenode.shared.edits.dir", nameservice.getJournalnodesHost())
        addProperty(hdfs_root, "dfs.client.failover.proxy.provider." + nameservice.name,
                    "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider")
        addProperty(hdfs_root, "dfs.ha.automatic-failover.enabled", "true")
        addProperty(core_root, "ha.zookeeper.quorum", nameservice.getZookeepersHost())
        modifyProperty(core_root, "fs.defaultFS", "hdfs://" + nameservice.name)

    addProperty(hdfs_root, "dfs.ha.fencing.methods", "sshfence")
    addProperty(hdfs_root, "dfs.journalnode.edits.dir", "/home/sunyue/hadoop_work/hdfs/journalnode")
    addProperty(hdfs_root, "dfs.ha.fencing.ssh.private-key-files", "/home/sunyue/.ssh/id_rsa")
    modifyProperty(yarn_root, "yarn.resourcemanager.hostname", nameservice.resourcemanagers[0].hostname)
    modifyProperty(mapred_root, "mapreduce.jobhistory.address", config.jobhistory.hostname + ":10020")
    modifyProperty(mapred_root, "mapreduce.jobhistory.webapp.address", config.jobhistory.hostname + ":19888")

    et = etree.ElementTree(hdfs_root)
    docinfo= hdfs_tree.docinfo
    et.write("./hadoopconfigfiles/hdfs-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(core_root)
    docinfo= core_tree.docinfo
    et.write("./hadoopconfigfiles/core-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(yarn_root)
    docinfo= yarn_tree.docinfo
    et.write("./hadoopconfigfiles/yarn-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(mapred_root)
    docinfo= mapred_tree.docinfo
    et.write("./hadoopconfigfiles/mapred-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)

def setHost():
    if os.path.isfile("./hadoopconfigfiles/hosts"):
        os.remove("./hadoopconfigfiles/hosts")
    with open("./hadoopconfigfiles/hosts", "w") as file:
        newhosts = config.getHosts()
        newhosts.insert(0, "127.0.0.1 localhost\n")
        file.writelines(newhosts)

def setSlaves():
    if os.path.isfile("./hadoopconfigfiles/slaves"):
        os.remove("./hadoopconfigfiles/slaves")
    with open("./hadoopconfigfiles/slaves", "w") as file:
        slaves = config.getSlaves()
        file.writelines(slaves)

def setConfiguration():
    setnamenodeHA()
    setHost()
    setSlaves()

def startJournalNodes(config):
    for nameservice in config.nameservices:
        for journalnode in nameservice.journalnodes:
            os.system("ssh -o StrictHostKeyChecking=no " + journalnode.ip + " /usr/local/hadoop/sbin/hadoop-daemon.sh start journalnode")

def formatNamenode(config):
    os.system("source /etc/profile.d/jdkenv.sh && source /etc/profile.d/hadoopenv.sh && \
               /usr/local/hadoop/bin/hdfs namenode -format && /usr/local/hadoop/sbin/hadoop-daemon.sh start namenode")
    for nameservice in config.nameservices:
        for namenode in nameservice.namenodes:
            if namenode.ip != config.ip:
                os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " <<DONE\n\
                            /usr/local/hadoop/bin/hdfs namenode -bootstrapStandby\n\
                            /usr/local/hadoop/sbin/hadoop-daemon.sh start namenode\nDONE\n")

def sshNNtoNN(config, password):
    for nameservice in config.nameservices:
        for namenode in nameservice.namenodes:
            if namenode.ip != config.ip:
                os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " -C '/bin/bash -s' < ./sshserver.sh " + password )
                for ip in config.allMachines:
                    if namenode.ip != ip:
                        os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " bash -s < ./sshclient.sh " + password + " " + ip)

def setZookeeper(config, password):
    for nameservice in config.nameservices:
        for index, zookeeper in enumerate(nameservice.zookeepers):
            os.system("./zookeeper.sh " + password + " " + zookeeper.ip + " " + str(index+1))

def formatZookeeper():
    os.system("$HADOOP_PREFIX/bin/hdfs zkfc -formatZK")

if __name__ == "__main__":
    config = Configuration(config_root)
    initialise()
    setConfiguration()
    argv = sys.argv
    if len(sys.argv) != 2:
        print 'Usage : Script <password>'
        sys.exit(1)
    if os.system("./serverpreconfig.sh" + " " + argv[1]) == 0:
        os.system("clear")
        print "Pre-configuration of Server is done."
    else:
        print "Pre-configuration of Server failed."
        sys.exit(1)
    for ip in config.clients.keys():
        if os.system("./clientpreconfig.sh" + " " + argv[1] + " " + ip) == 0:
            os.system("clear")
            print "Pre-configuration of client " + ip + " is done."
        else:
            print "Pre-configuration of client " + ip + " failed."
            sys.exit(1)

    if os.system("./hadoopmaster.sh" + " " + argv[1] + " " + config.namenode.hostname) == 0:
        os.system("clear")
        print "Hadoop configuration of Server is done."
    else:
        print "Hadoop configuration of Server failed."
        sys.exit(1)
    for (ip, hostname) in config.clients.items():
        if os.system("./hadoopslave.sh" + " " + argv[1] + " " + ip + " " + hostname) == 0:
            os.system("clear")
            print "Hadoop configuration of client " + ip + " is done."
        else:
            print "Hadoop configuration  of client " + ip + " failed."
            sys.exit(1)
    startJournalNodes(config)
    formatNamenode(config)
    sshNNtoNN(config, argv[1])
    setZookeeper(config, argv[1])
    formatZookeeper()
