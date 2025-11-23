#!/bin/sh

sops -d .enc.env | source /dev/stdin
