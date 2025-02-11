#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
cd ~/code/department-of-veteran-affairs/component-library/packages/web-components/
nvm use 18.20.4
yarn install
yarn build
yarn build-bindings
cd ../react-components/
yarn install
yarn build
cd ../core/
yarn install
yarn build
cd ../storybook/
yarn install
yarn storybook
