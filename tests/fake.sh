#!/bin/bash

source common.sh


trap 'echo exiting; exit;' SIGHUP SIGINT

sleep 10
