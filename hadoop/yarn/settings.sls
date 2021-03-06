{% set p  = salt['pillar.get']('yarn', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('yarn', {}) %}
{% set gc = g.get('config', {}) %}
{% from 'hadoop/settings.sls' import hadoop with context %}

{%- set resourcetracker_port        = gc.get('resourcetracker_port', pc.get('resourcetracker_port', '8031')) %}
{%- set scheduler_port              = gc.get('scheduler_port', pc.get('scheduler_port', '8030')) %}
{%- set resourcemanager_port        = gc.get('resourcemanager_port', pc.get('resourcemanager_port', '8032')) %}
{% if hadoop.secure_mode %}
  {% set webapp_port='8090' %}
  {% set webapp_protocol='https' %}
{% else %}
  {% set webapp_port='8088' %}
  {% set webapp_protocol='http' %}
{% endif %}

{%- set resourcemanager_webapp_port = gc.get('resourcemanager_webapp_port', pc.get('resourcemanager_webapp_port', webapp_port)) %}
{%- set resourcemanager_webapp_protocol = gc.get('resourcemanager_webapp_protocol', pc.get('resourcemanager_webapp_protocol', webapp_protocol )) %}
{%- set resourcemanager_admin_port  = gc.get('resourcemanager_admin_port', pc.get('resourcemanager_admin_port', '8033')) %}
{%- set nodemanager_port            = gc.get('nodemanager_port', pc.get('nodemanager_port', '50024')) %}
{%- set nodemanager_webapp_port     = gc.get('nodemanager_webapp_port', pc.get('nodemanager_webapp_port', '50025')) %}
{%- set nodemanager_localizer_port  = gc.get('nodemanager_localizer_port', pc.get('nodemanager_localizer_port', '50026')) %}
{%- set resourcemanager_target      = g.get('resourcemanager_target', p.get('resourcemanager_target', 'roles:hadoop_master')) %}
{%- set nodemanager_target          = g.get('nodemanager_target', p.get('nodemanager_target', 'roles:hadoop_slave')) %}
# this is a deliberate duplication as to not re-import hadoop/settings multiple times
{%- set targeting_method            = salt['grains.get']('hadoop:targeting_method', salt['pillar.get']('hadoop:targeting_method', 'grain')) %}
{%- set resourcemanager_host        = salt['mine.get'](resourcemanager_target, 'network.interfaces', expr_form=targeting_method)|first() %}
{%- set resourcemanager_hosts       = salt['mine.get'](resourcemanager_target, 'network.interfaces', expr_form=targeting_method) %}
{%- set zookeeper_target            = g.get('zookeeper_target', p.get('zookeeper_target', 'roles:zookeeper')) %}
{%- set zookeeper_hosts             = salt['mine.get'](zookeeper_target, 'network.interfaces', expr_form=targeting_method).keys() %}

{%- set cluster_id                  = salt['grains.get']('cluster_id', 'cluster1') %}

{%- set local_disks                 = salt['grains.get']('yarn_data_disks', ['/yarn_data']) %}
{%- set ranger_plugin               = gc.get('ranger_plugin', pc.get('ranger_plugin', False)) %}
{%- set config_yarn_site            = gc.get('yarn-site', pc.get('yarn-site', {})) %}
{%- set config_capacity_scheduler   = gc.get('capacity-scheduler', pc.get('capacity-scheduler', {})) %}
# these are system accounts blacklisted with the YARN LCE
{%- set banned_users                = gc.get('banned_users', pc.get('banned_users', ['hdfs','yarn','mapred','bin'])) %}

{%- set is_resourcemanager = salt['match.' ~ targeting_method](resourcemanager_target) %}
{%- set is_nodemanager     = salt['match.' ~ targeting_method](nodemanager_target) %}

{%- set yarn = {} %}
{%- do yarn.update({ 'resourcetracker_port'        : resourcetracker_port,
                     'scheduler_port'              : scheduler_port,
                     'resourcemanager_port'        : resourcemanager_port,
                     'resourcemanager_webapp_port' : resourcemanager_webapp_port,
                     'resourcemanager_webapp_protocol' : resourcemanager_webapp_protocol,
                     'resourcemanager_admin_port'  : resourcemanager_admin_port,
                     'resourcemanager_host'        : resourcemanager_host,
                     'resourcemanager_hosts'       : resourcemanager_hosts,
                     'nodemanager_port'            : nodemanager_port,
                     'nodemanager_webapp_port'     : nodemanager_webapp_port,
                     'nodemanager_localizer_port'  : nodemanager_localizer_port,
                     'local_disks'                 : local_disks,
                     'first_local_disk'            : local_disks|sort()|first(),
                     'config_yarn_site'            : config_yarn_site,
                     'config_capacity_scheduler'   : config_capacity_scheduler,
                     'banned_users'                : banned_users,
                     'is_resourcemanager'          : is_resourcemanager,
                     'is_nodemanager'              : is_nodemanager,
                     'zookeeper_hosts'             : zookeeper_hosts,
                     'cluster_id'                  : cluster_id,
                     'ranger_plugin'               : ranger_plugin,
                   }) %}
