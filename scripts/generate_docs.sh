#!/bin/sh

#  generate_docs.sh
#  SCAStateMachine
#
#  Created by Sean Atkinson on 23/07/2016.
#

cd ../
jazzy \
  --clean \
  --module SCAStateMachine \
  --author SeanCAtkinson \
  --author_url http://seancatkinson.com \
  --github_url https://github.com/seancatkinson/SCAStateMachine \
  --theme fullwidth
