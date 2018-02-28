#!/bin/bash

# start application
ENV=$(echo ${DEPLOYMENT_GROUP_NAME} | awk -F\- '{print $NF}')
if [[ ${ENV} == 'prd' ]]; then
  systemctl start ${APPLICATION_NAME}-3001
  systemctl start ${APPLICATION_NAME}-3002
else
  systemctl start ${APPLICATION_NAME}
fi
