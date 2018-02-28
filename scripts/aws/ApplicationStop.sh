#!/bin/bash

# stop application
ENV=$(echo ${DEPLOYMENT_GROUP_NAME} | awk -F\- '{print $NF}')
if [[ ${ENV} == 'prd' ]]; then
  systemctl stop ${APPLICATION_NAME}-3001
  systemctl stop ${APPLICATION_NAME}-3002
else
  systemctl stop ${APPLICATION_NAME}
fi
