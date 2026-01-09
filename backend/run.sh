#!/bin/bash
# Check for Node.js
if ! command -v node &> /dev/null
then
    echo "Node.js could not be found. Please install Node.js (https://nodejs.org/) to run this backend."
    exit 1
fi

echo "Installing dependencies..."
npm install

echo "Starting Server..."
npm start
