from hadoop.hadoopinfo import *

import sys

config = Configuration(config_root)

def setSSHClient(password, nameservices, client):
    for nameservice in nameservices:
        for namenode in nameservice.namenodes:
            os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " -C '/bin/bash -s' < "
            + path + "/ssh/sshclient.sh " + password + " " + client)

def clientpreconfig(password, client):
    os.system(path + "/clientpreconfig.sh " + password + " " + client)

def updateFiles(password):
    for ip in config.allNodesIp:
        os.system("scp " + path + "/conf/hadoop/slaves " + ip + ":$HADOOP_PREFIX/etc/hadoop" )
        os.system("expect <<- DONE\n\
        spawn sudo scp " + path + "/conf/hadoop/hosts " + ip + ":/etc/hosts\n\
        expect \"*?assword*\"\n\
        send -- \"" + password + "\\r\"\n\
        expect \"*?assword*\"\n\
        send -- \"" + password + "\\r\"\n\
        expect eof \nDONE")

def setHadoopslave(password, client, hostname):
    os.system(path + "/hadoop/hadoopslave.sh " + password + " " + client + " " + hostname)

def startNode(hostname, type):
    os.system("ssh -o StrictHostKeyChecking=no " + hostname + " $HADOOP_PREFIX/sbin/hadoop-daemon.sh start " + type)

def addDatanode(password, client):
    property = etree.XML("<datanode></datanode>")
    property.set("ip", client)
    config_root.find("datanodes").append(property)
    et = etree.ElementTree(config_root)
    docinfo = config_tree.docinfo
    et.write(path + "/clients/clients.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    hostname = "datanode-" + str(int(config.datanodes[-1].hostname[-1]) + 1)
    config.datanodes.append(Node(hostname, client, hostname, "datanode"))
    config.writeSlaves()
    config.writeHosts()
    updateFiles(password)
    setSSHClient(password, config.nameservices, client)
    clientpreconfig(password, client)
    setHadoopslave(password, client, hostname)
    startNode(hostname, type)

def addNode(password, client, type):
    if type == "datanode":
        addDatanode(password, client)
    else:
        print "Can not add the node with the type " + type

if __name__ == "__main__":
    argv = sys.argv
    if len(sys.argv) != 4:
        print 'Usage : Script <password> <type> <client>'
        sys.exit(1)
    password = argv[1]
    type = argv[2]
    client = argv[3]
    addDatanode(password, client)
    # updateFiles(password)
