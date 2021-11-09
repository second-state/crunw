#!/bin/bash
sudo crictl pull docker.io/tpmccallum/http_client
if [ -f http_client_sandbox_config.json ]
then 
    rm -rf http_client_sandbox_config.json
fi
if [ -f http_client_container_wasi.json ]
then 
    rm -rf http_client_container_wasi.json
fi
wget https://raw.githubusercontent.com/second-state/crunw/main/http_client_sandbox_config.json
wget https://raw.githubusercontent.com/second-state/crunw/main/http_client_container_wasi.json
echo -e "Creating POD ..."
POD_ID=$(sudo crictl runp http_client_sandbox_config.json)
echo -e "POD_ID: $POD_ID"
CONTAINER_ID=$(sudo crictl create $POD_ID http_client_container_wasi.json http_client_sandbox_config.json)
echo -e "CONTAINER_ID: $CONTAINER_ID"
sudo crictl start $CONTAINER_ID
sudo crictl ps -a
echo -e "Sleeping for 10 seconds"
sleep 10
echo -e "Awake again"
sudo crictl ps -a
echo -e "Checking logs ...\n\n"
sudo crictl logs $CONTAINER_ID
echo -e "\n\nFinished\n\n"
# Clean up
echo -e "Cleaning up ..."
rm -rf http_client_sandbox_config.json
rm -rf http_client_container_wasi.json
echo -e "Done!"

sudo crictl pull docker.io/tpmccallum/http_server
if [ -f http_server_sandbox_config.json ]
then 
    rm -rf http_server_sandbox_config.json
fi
if [ -f http_server_container_wasi.json ]
then 
    rm -rf http_server_container_wasi.json
fi
wget https://raw.githubusercontent.com/second-state/crunw/main/http_server_sandbox_config.json
wget https://raw.githubusercontent.com/second-state/crunw/main/http_server_container_wasi.json
echo -e "Creating POD ..."
POD_ID=$(sudo crictl runp http_server_sandbox_config.json)
echo -e "POD_ID: $POD_ID"
CONTAINER_ID=$(sudo crictl create $POD_ID http_server_container_wasi.json http_server_sandbox_config.json)
echo -e "CONTAINER_ID: $CONTAINER_ID"
sudo crictl start $CONTAINER_ID
sudo crictl ps -a
echo -e "Sleeping for 10 seconds"
sleep 10
echo -e "Awake again"
sudo crictl ps -a
echo -e "Checking logs ...\n\n"
sudo crictl logs $CONTAINER_ID
echo -e "\n\nFinished\n\n"
# Clean up
echo -e "Cleaning up ..."
rm -rf http_server_sandbox_config.json
rm -rf http_server_container_wasi.json
echo -e "Done!"
