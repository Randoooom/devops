#!/bin/sh

if [ -f .session ]; then
  while read -r pid; do
    kill "$pid" 2>/dev/null
  done < .session

  rm -f .session
fi
