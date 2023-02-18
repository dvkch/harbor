FROM node:|NODE_VERSION|-alpine as build-stage
WORKDIR /app

COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn set version 3.1.1 && yarn install && yarn cache clean

# switch to prod and allow nuxt server to connect to the outside
ENV NODE_ENV production
ENV SERVER_HOST 0.0.0.0
ENV SERVER_PORT 80

COPY . .
RUN yarn build

EXPOSE 80
CMD ["sh", "-c", "yarn start"]
