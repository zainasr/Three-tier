# Multi-stage: build not required for this minimal app; we only run.
FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./

EXPOSE 80

ENV PORT=80
USER node
CMD ["node", "server.js"]
