
import xml.etree.cElementTree as ET
from lxml import etree
import re

parser = etree.XMLParser(remove_blank_text=True)
hdfs_root = etree.parse("./hadoopconfigfiles/hdfs-site.xml", parser).getroot()
core_root = etree.parse("./hadoopconfigfiles/core-site.xml", parser).getroot()
tree = etree.parse("./clients/clients.xml", parser)
root = tree.getroot()

class Nameservice:

    def __init__(self, name):
        self.name = name
        self.namenodes = []
        self.journalnodes = []

    def __repr__(self):
        return str(self)

    def __str__(self):
        return "<name: %s, namenodes: %s>" % (self.name, self.namenodes)

    def addNameNode(self, namenode):
        self.namenodes.append(namenode)

    def addJournalnode(self, journalnode):
        self.journalnodes.append(journalnode)

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

class Namenode:

    def __init__(self, id, ip, hostname):
        self.id = id
        self.ip = ip
        self.hostname = hostname

    def __repr__(self):
        return str(self)

    def __str__(self):
        return "<IP: %s>" % self.ip

class Journalnode:
    def __init__(self, id, ip, hostname):
        self.id = id
        self.ip = ip
        self.hostname = hostname

    def __repr__(self):
        return str(self)

    def __str__(self):
        return "<IP: %s>" % self.ip


class Configuration:
    def __init__(self, root):
        self.root = root
        self.nameservices = []
        self.addNameservices()

    def addNameservices(self):
        for nameservice_ in root.findall("nameservice"):
            nameservice = Nameservice(nameservice_.get("name"))
            for namenode_ in nameservice_.findall("namenode"):
                namenode = Namenode(namenode_.get("id"), namenode_.get("ip"), nameservice.name + "-" + namenode_.get("id"))
                nameservice.addNameNode(namenode)
            for journalnode_ in nameservice_.findall("journalnode"):
                journalnode = Journalnode(journalnode_.get("id"), journalnode_.get("ip"), nameservice.name + "-" + journalnode_.get("id"))
                nameservice.addJournalnode(journalnode)
            self.nameservices.append(nameservice)

    def getNameservicesname(self):
        str = ""
        for nameservice in self.nameservices[:-1]:
            str += nameservice.name + ","
        else:
            str += self.nameservices[-1].name
        return str

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


def indent(elem, level=0):
    i = "\n" + level*"    "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "    "
        if not elem.tail :
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def clean(root, pattern):
    for property in root:
        for elem in property:
            if re.match(pattern, elem.text):
                root.remove(property)



def initialise():
    clean(hdfs_root, "*dfs.ha.namenodes*")
    clean(hdfs_root, "*dfs.namenode.rpc-address*")
    clean(hdfs_root, "*dfs.namenode.http-address*")
    clean(hdfs_root, "*dfs.namenode.shared.edits.dir*")
    clean(hdfs_root, "*dfs.client.failover.proxy.provider*")
    clean(hdfs_root, "*dfs.ha.fencing.methods*")
    clean(hdfs_root, "*dfs.ha.fencing.ssh.private-key-files*")
    clean(hdfs_root, "*dfs.namenode.checkpoint*")


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
        addProperty(hdfs_root, "dfs.ha.fencing.methods", "sshfence")
        addProperty(hdfs_root, "dfs.journalnode.edits.dir", "/home/sunyue/hadoop_work/hdfs/journalnode")
        modifyProperty(core_root, "fs.defaultFS", "hdfs://" + nameservice.name)

if __name__ == "__main__":
    config = Configuration(root)
    setnamenodeHA()
    print etree.tostring(core_root, pretty_print=True)
    # addProperty(root, "hag", "gah")
    # setnamenodeHA()
    # tree = etree.parse("./hadoopconfigfiles/core-site.xml", parser)
    # root = tree.getroot()
    # for property in root:
    #     for elem in property:
    #         if re.match("fs.*",elem.text):
    #             print elem.text
    #
    # config = Configuration(root)
    # config.addNameservices()
    # root.append(etree.XML("<root>data</root>"))
    # # root.append( etree.Element("child1") )
    # et = etree.ElementTree(root)
    # docinfo= tree.docinfo
    # indent(root)
    # et.write(sys.stdout, pretty_print=True)
    # et.write("./hadoopconfigfiles/core-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    # print root.Comment()
    # print etree.tostring(root, pretty_print=True, encoding="UTF-8")
    # hdfs_tree = etree.parse("./hadoopconfigfiles/hdfs-site.xml", parser)
    # hdfs_root = hdfs_tree.getroot()
    # for property in hdfs_root:
    #     for elem in property:
    #         if re.match("dfs..namenode*",elem.text):
    #             hdfs_root.remove(elem.getparent())
    #             # elem.getparent().remove(elem)
    # print etree.tostring(hdfs_root, pretty_print=True)
