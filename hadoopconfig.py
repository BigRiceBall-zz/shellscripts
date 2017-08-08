#! /bin/python

from lxml import etree
import re
import os
import sys
import time

from hadoop.hadoop.node import *
from hadoop.hadoop.nameservice import *
from hadoop.hadoop.hadoopinfo import *

home = os.environ['HOME']

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
    et = etree.ElementTree(hdfs_root)
    docinfo= hdfs_tree.docinfo
    et.write(path + "/conf/hadoop/hdfs-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(core_root)
    docinfo= core_tree.docinfo
    et.write(path + "/conf/hadoop/core-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)

def setNormalConfiguration(config):
    modifyProperty(core_root, "fs.defaultFS", "hdfs://" + config.nameservices[0].namenodes[0].hostname + ":8020")
    modifyProperty(hdfs_root, "dfs.namenode.name.dir", "file:" + home +"/hadoop_work/hdfs/namenode")
    modifyProperty(hdfs_root, "dfs.datanode.data.dir", "file:" + home +"/hadoop_work/hdfs/datanode")
    modifyProperty(yarn_root, "yarn.nodemanager.local-dirs", "file:" + home +"/hadoop_work/yarn/local")
    modifyProperty(yarn_root, "yarn.nodemanager.log-dirs", "file:" + home +"/hadoop_work/yarn/log")
    modifyProperty(mapred_root, "mapreduce.jobhistory.address", config.jobhistory.hostname + ":10020")
    modifyProperty(mapred_root, "mapreduce.jobhistory.webapp.address", config.jobhistory.hostname + ":19888")
    modifyProperty(core_root, "hadoop.tmp.dir", "file:" + home +"/tmp")

def setnamenodeHA(config):
    addProperty(hdfs_root, "dfs.nameservices", config.getNameservicesname())
    for nameservice in config.nameservices:
        if nameservice.HAenable:
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
            modifyProperty(core_root, "fs.defaultFS", "hdfs://" + nameservice.name)
    addProperty(core_root, "ha.zookeeper.quorum", config.getZookeepersHost())
    modifyProperty(yarn_root, "yarn.resourcemanager.hostname", config.nameservices[0].resourcemanagers[0].hostname)
    addProperty(hdfs_root, "dfs.ha.fencing.methods", "sshfence")
    addProperty(hdfs_root, "dfs.journalnode.edits.dir", home + "/hadoop_work/hdfs/journalnode")
    addProperty(hdfs_root, "dfs.ha.fencing.ssh.private-key-files", home + "/.ssh/id_rsa")

def writeConfiguration():
    et = etree.ElementTree(hdfs_root)
    docinfo= hdfs_tree.docinfo
    et.write(path + "/conf/hadoop/hdfs-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(core_root)
    docinfo= core_tree.docinfo
    et.write(path + "/conf/hadoop/core-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(yarn_root)
    docinfo= yarn_tree.docinfo
    et.write(path + "/conf/hadoop/yarn-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)
    et = etree.ElementTree(mapred_root)
    docinfo= mapred_tree.docinfo
    et.write(path + "/conf/hadoop/mapred-site.xml", pretty_print=True, xml_declaration=True, encoding=docinfo.encoding)

def setConfiguration(config):
    setNormalConfiguration(config)
    writeConfiguration()
    if config.HAenable:
        setnamenodeHA(config)
    writeConfiguration()
    config.writeHosts()
    config.writeSlaves()

def startJournalNodes(config):
    for nameservice in config.nameservices:
        for journalnode in nameservice.journalnodes:
            os.system("ssh -o StrictHostKeyChecking=no " + journalnode.ip + " /usr/local/hadoop/sbin/hadoop-daemon.sh start journalnode")

def formatNamenode(config):
    # os.system("source /etc/profile.d/jdkenv.sh && source /etc/profile.d/hadoopenv.sh && \
    #            /usr/local/hadoop/bin/hdfs namenode -format && /usr/local/hadoop/sbin/hadoop-daemon.sh start namenode")
    for index_ns, nameservice in enumerate(config.nameservices):
        for index_nn, namenode in enumerate(nameservice.namenodes):
            if index_ns == 0 and index_nn == 0:
                os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " <<DONE\n\
                            /usr/local/hadoop/bin/hdfs namenode -format\n\
                            /usr/local/hadoop/sbin/hadoop-daemon.sh start namenode\nDONE\n")
            else:
                os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " <<DONE\n\
                            /usr/local/hadoop/bin/hdfs namenode -bootstrapStandby\n\
                            /usr/local/hadoop/sbin/hadoop-daemon.sh start namenode\nDONE\n")

def setSSHInNN(config, password):
    for nameservice in config.nameservices:
        for namenode in nameservice.namenodes:
            if namenode != config.namenode:
                os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " -C '/bin/bash -s' < " + path + "/ssh/sshserver.sh " + password)
                for ip in config.allNodesIp:
                    if namenode.ip != ip:
                        os.system("ssh -o StrictHostKeyChecking=no " + namenode.hostname + " bash -s < " + path + "/ssh/sshclient.sh " + password + " " + ip)

def setZookeepers(config, password):
    os.system("rm " + path + "/conf/zookeeper/zoo.cfg")
    os.system("cp " + path + "/conf/zookeeper/zoo_sample.cfg " + path + "/conf/zookeeper/zoo.cfg")
    # for zookeeper in config.zookeepers:
    for index, zookeeper in enumerate(config.zookeepers):
        os.system("echo server." + str(index + 1) + "=" + zookeeper.hostname + ":2888:3888 >> " + path + "/conf/zookeeper/zoo.cfg")
    # for nameservice in config.nameservices:
    for index, zookeeper in enumerate(config.zookeepers):
        os.system(path + "/zookeeper/zookeeper.sh " + password + " " + zookeeper.ip + " " + str(index+1))

def formatZookeeper():
    os.system("/usr/local/hadoop/sbin/stop-dfs.sh")
    os.system("source /etc/profile.d/jdkenv.sh && source /etc/profile.d/hadoopenv.sh && $HADOOP_PREFIX/bin/hdfs zkfc -formatZK")

if __name__ == "__main__":
    config = Configuration(config_root)
    initialise()
    setConfiguration(config)
    argv = sys.argv
    if len(sys.argv) != 2:
        print 'Usage : Script <password>'
        sys.exit(1)
    if os.system(path + "/serverpreconfig.sh" + " " + argv[1]) == 0:
        os.system("clear")
        print "Pre-configuration of Server is done."
    else:
        print "Pre-configuration of Server failed."
        sys.exit(1)
    for ip in config.allNodesIp:
        if ip != config.namenode.ip:
            if os.system(path + "/clientpreconfig.sh" + " " + argv[1] + " " + ip) == 0:
                os.system("clear")
                print "Pre-configuration of client " + ip + " is done."
            else:
                print "Pre-configuration of client " + ip + " failed."
                sys.exit(1)
    if os.system(path + "/hadoop/hadoopmaster.sh" + " " + argv[1] + " " + config.namenode.hostname) == 0:
        os.system("clear")
        print "Hadoop configuration of Server is done."
    else:
        print "Hadoop configuration of Server failed."
        sys.exit(1)
    for (ip, hostname) in config.clients.items():
        if os.system(path + "/hadoop/hadoopslave.sh" + " " + argv[1] + " " + ip + " " + hostname) == 0:
            os.system("clear")
            print "Hadoop configuration of client " + ip + " is done."
        else:
            print "Hadoop configuration  of client " + ip + " failed."
            sys.exit(1)
    startJournalNodes(config)
    formatNamenode(config)
    setSSHInNN(config, argv[1])
    setZookeepers(config, argv[1])
    formatZookeeper()
