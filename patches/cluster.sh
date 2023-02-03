#!/usr/bin/env bash
ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root cluster.yml
#ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root reset.yml
