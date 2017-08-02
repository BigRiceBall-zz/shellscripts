from node import *
from nameservice import *
import os

cmd = "$HADOOP_PREFIX/bin/hdfs getconf -confKey dfs.nameservices"
nameservices_info = map(lambda x: str.strip(x), os.popen(cmd).readlines())
nameservices = []
for name in nameservices_info:
    nameservice = Nameservice(name)
    cmd = "$HADOOP_PREFIX/bin/hdfs getconf -confKey dfs.ha.namenodes." + name
    namenode_info = map(lambda)
    nameservices.append(nameservice)
