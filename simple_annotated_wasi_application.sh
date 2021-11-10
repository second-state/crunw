#!/bin/bash
sudo crictl pull docker.io/hydai/wasm-wasi-example:with-wasm-annotation
if [ -f sandbox_config.json ]
then 
    rm -rf sandbox_config.json
fi
if [ -f annotated_container_wasi.json ]
then 
    rm -rf annotated_container_wasi.json
fi
wget https://raw.githubusercontent.com/second-state/crunw/main/sandbox_config.json
wget https://raw.githubusercontent.com/second-state/crunw/main/annotated_container_wasi.json
echo -e "Creating POD ..."
POD_ID=$(sudo crictl runp sandbox_config.json)
echo -e "POD_ID: $POD_ID"
CONTAINER_ID=$(sudo crictl create $POD_ID annotated_container_wasi.json sandbox_config.json)
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
rm -rf sandbox_config.json
rm -rf annotated_container_wasi.json
echo -e "Done!"
