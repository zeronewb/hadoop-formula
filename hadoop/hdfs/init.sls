{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
{%- from 'hadoop/keystore_macro.sls' import keystore with context %}
include:
  - hadoop.systemd
  
{%- set username = 'hdfs' %}
{%- set uid = hadoop.users[username] %}

{{ hadoop_user(username, uid) }}

# every node can advertise any JBOD drives to the framework by setting the hdfs_data_disk grain
{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

{% for disk in hdfs_disks %}
{{ disk }}/hdfs:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
{% if hdfs.is_namenode %}
{{ disk }}/hdfs/nn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{{ disk }}/hdfs/snn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{% endif %}

{%- if hdfs.tmp_dir != '/tmp' %}
{{ hdfs.tmp_dir }}:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
    - mode: '1775'
{% endif %}


{%- if hdfs.is_datanode %}
{{ disk }}/hdfs/dn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{%- endif %}

{%- if hdfs.is_journalnode %}
{{ disk }}/hdfs/journal:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{%- endif %}

{% endfor %}

{{ hadoop.alt_config }}/masters:
  file.managed:
    - mode: 644
    - contents: {{ hdfs.namenode_host }}

{{ hadoop.alt_config }}/slaves:
  file.managed:
    - mode: 644
    - contents: |
{%- for slave in hdfs.datanode_hosts %}
        {{ slave }}
{%- endfor %}

{{ hadoop.alt_config }}/dfs.hosts:
  file.managed:
    - mode: 644
    - contents: |
{%- for slave in hdfs.datanode_hosts %}
        {{ slave }}
{%- endfor %}

{{ hadoop.alt_config }}/dfs.hosts.exclude:
  file.managed

{% if hadoop.secure_mode %}
/etc/krb5/hdfs.keytab:
  file.managed:
    - source: salt://kerberos/files/{{grains['cluster_id']}}/{{username}}-{{ grains['fqdn'] }}.keytab
    - user: {{ username }}
    - group: {{ username }}
    - mode: '400'
{% if hdfs.is_namenode or hdfs.is_journalnode or hdfs.is_datanode %}
/etc/krb5/spnego.keytab:
  file.managed:
    - source: salt://kerberos/files/{{grains['cluster_id']}}/spnego-{{ grains['fqdn'] }}.keytab
    - user: {{ username }}
    - group: hadoop
    - mode: '440'
{% endif %}

{{ keystore(username)}}
{% endif %}

{% if hdfs.is_namenode %}

{%- if hdfs.namenode_count == 1 %}
format-namenode:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
    - user: hdfs
    - unless: test -d {{ test_folder }}
{%- endif %}

systemd-hadoop-namenode:
  file.managed:
    - name: /etc/systemd/system/hadoop-namenode.service
    - source: salt://hadoop/files/{{ hadoop.initscript_systemd }}
    - user: root
    - group: root
    - mode: '644'
    - template: jinja
    - context:
      hadoop_svc: namenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
    - watch_in:
      - cmd: systemd-reload

{%- if hdfs.namenode_count == 1 %}
systemd-hadoop-secondarynamenode:
  file.managed:
    - name: /etc/systemd/system/hadoop-secondarynamenode.service
    - source: salt://hadoop/files/systemd.init.jinja
    - user: root
    - group: root
    - mode: '644'
    - template: jinja
    - context:
      service: hadoop-secondarynamenode
    - watch_in:
      - cmd: systemd-reload
{%- else %}
systemd-hadoop-zkfc:
  file.managed:
    - name: /etc/systemd/system/hadoop-zkfc.service
    - source: salt://hadoop/files/{{ hadoop.initscript_systemd }}
    - user: root
    - group: root
    - mode: '644'
    - template: jinja
    - context:
      hadoop_svc: zkfc
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
    - watch_in:
      - cmd: systemd-reload
{% endif %} 
{% endif %}

{% if hdfs.is_datanode %}
systemd-hadoop-datanode:
  file.managed:
    - name: /etc/systemd/system/hadoop-datanode.service
    - source: salt://hadoop/files/{{ hadoop.initscript_systemd }}
    - user: root
    - group: root
    - mode: '644'
    - template: jinja
    - context:
      hadoop_svc: datanode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
    - watch_in:
      - cmd: systemd-reload
{% endif %}

{% if hdfs.is_journalnode %}
systemd-hadoop-journalnode:
  file.managed:
    - name: /etc/systemd/system/hadoop-journalnode.service
    - source: salt://hadoop/files/{{ hadoop.initscript_systemd }}
    - user: root
    - group: root
    - mode: '644'
    - template: jinja
    - context:
      hadoop_svc: journalnode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      user: hdfs
    - watch_in:
      - cmd: systemd-reload
{% endif %}

{% if hdfs.is_namenode and hdfs.namenode_count == 1 %}
hdfs-nn-services:
  service.running:
    - enable: True
    - names:
      - hadoop-secondarynamenode
      - hadoop-namenode
{%- if hdfs.restart_on_config_change == True %}
    - watch:
      - file: {{ hadoop.alt_config }}/core-site.xml
      - file: {{ hadoop.alt_config }}/hdfs-site.xml
{%- endif %}
{%- endif %}

{% if hdfs.is_datanode or hdfs.is_journalnode %}
hdfs-services:
  service.running:
    - enable: True
    - names:
{%- if hdfs.is_datanode %}
      - hadoop-datanode
{%- endif %}
{%- if hdfs.is_journalnode %}
      - hadoop-journalnode
{%- endif %}
{%- if hdfs.restart_on_config_change == True %}
    - watch:
      - file: {{ hadoop.alt_config }}/core-site.xml
      - file: {{ hadoop.alt_config }}/hdfs-site.xml
{%- endif %}
{%- endif %}
