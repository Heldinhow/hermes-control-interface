FROM node:22-slim

WORKDIR /app

# Install build tools for node-pty and better-sqlite3
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

ENV PORT=10272
ENV HOST=0.0.0.0

EXPOSE 10272

CMD ["node", "server.js"]
