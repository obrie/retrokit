#!/bin/bash

# When the controls change, we reload powerkit in order to pick up the latest
# input configurations
sudo systemctl restart powerkit
