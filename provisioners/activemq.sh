#!/bin/bash

activemq_version=5.13.0

# Initial install
wget http://apache.javapipe.com/activemq/${activemq_version}/apache-activemq-${activemq_version}-bin.tar.gz
tar zxvf apache-activemq-${activemq_version}-bin.tar.gz
sudo mv apache-activemq-${activemq_version} /opt
sudo ln -s /opt/apache-activemq-${activemq_version} /opt/activemq

# Make sure Active MQ is started up after booting the system, and make it available as service.
sudo ln -s /opt/apache-activemq-${activemq_version}/bin/linux-x86-64/activemq /etc/init.d/activemq

# The service must run as the activemq user, not root.
sudo sed -i "s/#RUN_AS_USER=/RUN_AS_USER=activemq/g" /opt/activemq/bin/linux-x86-64/activemq

# Add Non-Privileged Account
sudo adduser -system activemq
sudo chown -R activemq: /opt/apache-activemq-${activemq_version}

# Set the user/pass wor the admin interface
admin_username=admin
admin_password=admin
sudo sed -i "s/admin:.*/admin: ${admin_username}, ${admin_password}/g" /opt/activemq/conf/jetty-realm.properties

# Start the service
sudo /etc/init.d/activemq start

# Monitor the logs
sudo tail -f /opt/activemq/data/activemq.log

# Open up the admin panel
# http://localhost:8161/admin (admin/admin)

# ActiveMQ runs on port 61616
# netstat -an | grep 61616
