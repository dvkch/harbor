# build stage
FROM node:|NODE_VERSION|-alpine as build-stage
WORKDIR /app

COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn set version 3.1.1 && yarn install && yarn cache clean

COPY . .
RUN yarn generate

# production stage
FROM nginx:stable-alpine as production-stage

COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY docker-nginx.conf /etc/nginx/nginx.conf
COPY docker-nginx-server.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
