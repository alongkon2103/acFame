FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY *.mjs ./
COPY overlay.html ./
USER node
ENV HOST=0.0.0.0 PORT=3210
EXPOSE 3210
CMD ["node", "server.mjs"]
