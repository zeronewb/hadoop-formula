{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/ranger/settings.sls' import ranger with context %}

hadoop:
  group.present:
    - gid: {{ hadoop.users['hadoop'] }}

{%- if grains['os_family'] == 'RedHat' %}
redhat-lsb:
  pkg.installed
{%- endif %}

create-common-folders:
  file.directory:
    - user: root
    - group: hadoop
    - mode: 775
    - names:
      - {{ hadoop.log_root }}
      - /var/lib/hadoop
    - require:
      - group: hadoop
    - makedirs: True

{%- if hadoop.log_root != hadoop.default_log_root %}
/var/log/hadoop:
  file.symlink:
    - target: {{ hadoop.log_root }}
{%- endif %}

unpack-hadoop-dist:
  archive.extracted:
    - name: /usr/lib/
    - source: {{ hadoop.source_url }}
{%- if hadoop.source_hash %}
    - source_hash: md5={{ hadoop.source_hash }}
{%- else %}
    - skip_verify: True
{%- endif %}
    - archive_format: tar
    - if_missing: {{ hadoop['real_home'] }}
    - require_in:
      - alternatives: hadoop-home-link
      - alternatives: hadoop-bin-link
      - alternatives: hdfs-bin-link
      - alternatives: mapred-bin-link
      - alternatives: yarn-bin-link

hadoop-home-link:
  alternatives.install:
    - link: {{ hadoop['alt_home'] }}
    - path: {{ hadoop['real_home'] }}
    - priority: 30
    - onlyif: test -d {{ hadoop['real_home'] }} && test ! -L {{ hadoop['alt_home'] }}
  file.symlink:
    - name: {{ hadoop['alt_home'] }}
    - target: {{ hadoop['real_home'] }}
    - require:
      - alternatives: hadoop-home-link
      
hadoop-bin-link:
  alternatives.install:
    - link: /usr/bin/hadoop
    - path: {{ hadoop['alt_home'] }}/bin/hadoop
    - priority: 30
    - onlyif: test -f {{ hadoop['alt_home'] }}/bin/hadoop && test ! -L /usr/bin/hadoop
  file.symlink:
    - name: /usr/bin/hadoop
    - target: {{ hadoop['alt_home'] }}/bin/hadoop
    - require:
      - alternatives: hadoop-bin-link
      
hdfs-bin-link:
  alternatives.install:
    - link: /usr/bin/hdfs
    - path: {{ hadoop['alt_home'] }}/bin/hdfs
    - priority: 30
    - onlyif: test -f {{ hadoop['alt_home'] }}/bin/hdfs && test ! -L /usr/bin/hdfs
  file.symlink:
    - name: /usr/bin/hdfs
    - target: {{ hadoop['alt_home'] }}/bin/hdfs
    - require:
      - alternatives: hdfs-bin-link
      
mapred-bin-link:
  alternatives.install:
    - link: /usr/bin/mapred
    - path: {{ hadoop['alt_home'] }}/bin/mapred
    - priority: 30
    - onlyif: test -f {{ hadoop['alt_home'] }}/bin/mapred && test ! -L /usr/bin/mapred
  file.symlink:
    - name: /usr/bin/mapred
    - target: {{ hadoop['alt_home'] }}/bin/mapred
    - require:
      - alternatives: mapred-bin-link
      
yarn-bin-link:
  alternatives.install:
    - link: /usr/bin/yarn
    - path: {{ hadoop['alt_home'] }}/bin/yarn
    - priority: 30
    - onlyif: test -f {{ hadoop['alt_home'] }}/bin/yarn && test ! -L /usr/bin/yarn
  file.symlink:
    - name: /usr/bin/yarn
    - target: {{ hadoop['alt_home'] }}/bin/yarn
    - require:
      - alternatives: yarn-bin-link
      
/etc/profile.d/hadoop.sh:
  file.managed:
    - source: salt://hadoop/files/hadoop.jinja
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      var_export: true
      java_home: {{ hadoop.java_home }}
      hadoop_home: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}
      hadoop_major_version: {{ hadoop.major_version }}

{% set real_config_src = hadoop['real_home'] + '/etc/hadoop' %}

/etc/hadoop:
  file.directory:
    - user: root
    - group: root
    - mode: 755

move-hadoop-dist-conf:
  file.directory:
    - name: {{ hadoop['real_config'] }}
    - user: root
    - group: root
  cmd.run:
    - name: mv  {{ real_config_src }} {{ hadoop.real_config_dist }}
    - unless: test -d {{ hadoop.real_config_dist }}
    - onlyif: test -d {{ real_config_src }}
    - require:
      - file: /etc/hadoop

{{ real_config_src }}:
  file.symlink:
    - target: {{ hadoop['alt_config'] }}
    - force: true
    - require:
      - cmd: move-hadoop-dist-conf

hadoop-conf-link:
  alternatives.install:
    - link: {{ hadoop['alt_config'] }}
    - path: {{ hadoop['real_config'] }}
    - priority: 30
    - onlyif: test -d {{ hadoop['real_config'] }} && test ! -L {{ hadoop['alt_config'] }}
    - require:
      - file: {{ hadoop['real_config'] }}
  file.symlink:
    - name: {{ hadoop['alt_config'] }}
    - target: {{ hadoop['real_config'] }}
    - require:
      - alternatives: hadoop-conf-link
      
{{ hadoop['real_config'] }}/log4j.properties:
  file.copy:
    - source: {{ hadoop['real_config_dist'] }}/log4j.properties
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ hadoop['real_config'] }}
      - alternatives: hadoop-conf-link

{{ hadoop['real_config'] }}/hadoop-env.sh:
  file.managed:
    - source: salt://hadoop/conf/hadoop-env.sh
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      jmx_export: {{ hadoop.jmx_export }}
      java_home: {{ hadoop.java_home }}
      hadoop_home: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}

{%- if hadoop.jmx_export %}
{{ hadoop['real_config'] }}/jmx_hdfs_nn.yaml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/jmx_hdfs_nn.yaml
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop['real_config'] }}/jmx_hdfs_dn.yaml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/jmx_hdfs_dn.yaml
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop['real_config'] }}/jmx_hdfs_zkfc.yaml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/jmx_hdfs_zkfc.yaml
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop['real_config'] }}/jmx_hdfs_jn.yaml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/jmx_hdfs_jn.yaml
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop['real_config'] }}/jmx_yarn_rm.yaml:
  file.managed:
    - source: salt://hadoop/conf/yarn/jmx_yarn_rm.yaml
    - template: jinja
    - mode: 644
    - user: root
    - group: root

{{ hadoop['real_config'] }}/jmx_yarn_nm.yaml:
  file.managed:
    - source: salt://hadoop/conf/yarn/jmx_yarn_nm.yaml
    - template: jinja
    - mode: 644
    - user: root
    - group: root
{%- endif %}

{{ hadoop.alt_config }}/core-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/core-site.xml
    - template: jinja
    - mode: 644

{{ hadoop.alt_config }}/hdfs-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/hdfs-site.xml
    - template: jinja
    - mode: 644

{{ hadoop.alt_config }}/yarn-site.xml:
  file.managed:
    - source: salt://hadoop/conf/yarn/yarn-site.xml
    - mode: 644
    - user: root
    - template: jinja

{{ hadoop['alt_config'] }}/mapred-site.xml:
  file.managed:
    - source: salt://hadoop/conf/mapred/mapred-site.xml
    - template: jinja
    - mode: 644

/etc/default/hadoop:
  file.managed:
    - source: salt://hadoop/files/hadoop.jinja
    - mode: '644'
    - template: jinja
    - user: root
    - group: root
    - context:
      var_export: true
      java_home: {{ hadoop.java_home }}
      hadoop_home: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}
      hadoop_major_version: {{ hadoop.major_version }}
/etc/default/hadoop-systemd:
  file.managed:
    - source: salt://hadoop/files/hadoop.jinja
    - mode: '644'
    - template: jinja
    - user: root
    - group: root
    - context:
      var_export: false
      java_home: {{ hadoop.java_home }}
      hadoop_home: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}
      hadoop_major_version: {{ hadoop.major_version }}
