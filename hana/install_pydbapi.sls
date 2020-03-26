{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host %}
{% if loop.first %}
{% set pydbapi_output_dir = '/tmp/pydbapi' %}
hana_install_python_pip:
  pkg.installed:
    {% if grains['pythonversion'][0] == 2 %}
    - name: python-pip
    {% else %}
    - name: python3-pip
    {% endif %}
    - retry:
        attempts: 3
        interval: 15
    - resolve_capabilities: true

# The software_folders is retrieved in this order: 
# 1. node.exporter.hana_client_path
# 2. node.install.software_path
# 3. hana.software_path
{% if node.exporter.hana_client_path is defined or node.install.software_path is defined  %}
{% set software_folders = node.exporter.hana_client_path|default(node.install.software_path) %}
{% else %}
{% set software_folders = hana.software_path %}
{% endif %}

hana_extract_pydbapi_client:
  hana.pydbapi_extracted:
    - name: PYDBAPI.TGZ
    - software_folders: [{{ software_folders }}]
    - output_dir: {{ pydbapi_output_dir }}
    - hana_version: '20'
    - force: true

# pip.installed fails as it cannot manage propler file names with regular expressions
# TODO: Improve this to use pip.installed somehow
hana_install_pydbapi_client:
  cmd.run:
    {% if grains['pythonversion'][0] == 2 %}
    - name: /usr/bin/python -m pip install {{ pydbapi_output_dir }}/hdbcli-*.tar.gz
    {% else %}
    - name: /usr/bin/python3 -m pip install {{ pydbapi_output_dir }}/hdbcli-*.tar.gz
    {% endif %}
    - require:
      - hana_install_python_pip
      - hana_extract_pydbapi_client

hana_remove_pydbapi_client:
  file.absent:
    - name: {{ pydbapi_output_dir }}
    - onchanges:
      - hana_extract_pydbapi_client
{% endif %}
{% endfor %}
