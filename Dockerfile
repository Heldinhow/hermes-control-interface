FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 10272

ENV PORT=10272
ENV HOST=0.0.0.0

CMD ["node", "server.js"]
