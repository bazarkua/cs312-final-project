#!/bin/bash
screen -S minecraft -p 0 -X stuff "/say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\n"
screen -S minecraft -p 0 -X stuff "/save-all\n"
sleep 10
screen -S minecraft -p 0 -X stuff "/stop\n"
