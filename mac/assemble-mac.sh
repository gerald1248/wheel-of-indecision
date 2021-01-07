#!/bin/sh

sudo rm -rf /Applications/Wheel\ of\ Indecision.app
sudo cp -R Wheel\ of\ Indecision.app /Applications/
sudo productbuild --component /Applications/Wheel\ of\ Indecision.app --sign "3rd Party Mac Developer Installer: Gerald Schmidt (FBCSA85C72)" /Users/gerald/builds/wheel-of-indecision.pkg
