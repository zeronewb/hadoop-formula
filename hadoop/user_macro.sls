{%- from 'hadoop/settings.sls' import hadoop with context %}

{% macro hadoop_user(username, uid, ssh=True) -%}
{%- set userhome='/home/'+username %}
{{ username }}:
  group.present:
    - gid: {{ uid }}
  user.present:
    - uid: {{ uid }}
    - gid: {{ uid }}
    - home: {{ userhome }}
    - shell: /bin/bash
    - groups: ['hadoop']
    - require:
      - group: {{ username }}
#  file.directory:
#    - user: {{ username }}
#    - group: hadoop
#    - names:
#      - /var/log/hadoop/{{ username }}
#      - /var/run/hadoop/{{ username }}
#      - /var/lib/hadoop/{{ username }}

{% if ssh %}
{{ userhome }}/.ssh:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 744
    - require:
      - user: {{ username }}
      - group: {{ username }}

{{ username }}_private_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_rsa
    - user: {{ username }}
    - group: {{ username }}
    - mode: 600
    - source: salt://hadoop/files/rsa-{{ username }}
    - require:
      - file: {{ userhome }}/.ssh

{{ username }}_public_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_rsa.pub
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - source: salt://hadoop/files/rsa-{{ username }}.pub
    - require:
      - file: {{ username }}_private_key

ssh_rss_{{ username }}:
  ssh_auth.present:
    - user: {{ username }}
    - source: salt://hadoop/files/rsa-{{ username }}.pub
    - require:
      - file: {{ username }}_private_key

{{ userhome }}/.ssh/config:
  file.managed:
    - source: salt://hadoop/conf/ssh/ssh_config
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - file: {{ userhome }}/.ssh
{% endif %}

{{ userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:{{ hadoop['alt_home'] }}/bin:{{ hadoop['alt_home'] }}/sbin

/etc/security/limits.d/99-{{username}}.conf:
  file.managed:
    - mode: 644
    - user: root
    - contents: |
        {{username}} soft nofile 65536
        {{username}} hard nofile 65536
        {{username}} soft nproc 65536
        {{username}} hard nproc 65536

{%- endmacro %}
