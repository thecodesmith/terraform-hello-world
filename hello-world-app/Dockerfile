FROM node:20.10.0

COPY --chown=node:node ./ /home/node
WORKDIR /home/node
USER node
RUN npm install --production

CMD ["node", "index.js"]
