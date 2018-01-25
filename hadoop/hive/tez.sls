{% set version = salt['pillar.get']('hive:tez:version', '0.9.0') %}

tez-directory-symlink:
  file.symlink:
    - target: /usr/lib/tez-{{ version }}-bin
    - name: /usr/lib/tez

/etc/hive/conf/tez-site.xml:
  file.managed:
    - makedirs: True
    - user: hive
    - template: jinja
    - source: salt://hadoop/conf/hive/tez-site.xml

install-tez:
  cmd.run:
    - cwd: /usr/lib
    - name: wget http://mirror.funkfreundelandshut.de/apache/tez/{{ version }}/apache-tez-{{ version }}-bin.tar.gz; tar xvf apache-tez-{{ version }}-bin.tar.gz 
    - unless: ls /usr/lib/apache-tez-{{ version }}-bin/conf/tez-default-template.xml

copy-to-hdfs:
  cmd.run:
    - user: hdfs
    - name: hadoop fs -copyFromLocal /usr/lib/apache-tez-{{ version }}-bin /apps/tez/
    - unless: hadoop fs -ls /apps/tez/apache-tez-{{ version }}-bin/share/tez.tar.gz

chown-as-hive:
  cmd.run:
    - user: hdfs
    - name: hadoop fs -chown -R hive /apps/tez
