Role Name
=========

A full deployment of symdash to a server. 

Requirements
------------

Ansible 2.1.0.0

Tested clean installs work on Ubuntu 14.04 LTS (Trusty Tahr) and Debian 8 (Jessie)
Need to have a config.py file. The default location is in the symdash/files/config.py, but the location can be changed by altering symdash/vars/main.yml

Must run as sudo

Role Variables
--------------

The cache that holds the symdash code on the ansible server before deployment:
cache_dir: cache

The repo that contains the actual symdash code:
git_repo: git@github.rackspace.com:symetric/symdash.git

Where the symdash code lives on the remote computer: 
deploy_home: /etc/symdash

The file used by the symdash app to control settings:
config_file: config.py

Dependencies
------------

Symdash is a standalone role.
The role pulls from this github: https://github.rackspace.com/symetric/symdash/
^ An ssh key is needed to pull from this github. 


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

- hosts: erebor
  gather_facts: false
  roles:
    - symdash 

License
-------

BSD

Author Information
------------------

GITHUB: https://github.rackspace.com/symetric/
