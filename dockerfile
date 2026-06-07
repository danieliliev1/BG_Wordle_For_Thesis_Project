# 1. Стейдж за билдване (остава непроменен)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . . 
RUN npx vite build

# 2. Стейдж за контейнера
FROM nginx:alpine

# Използваме последната стабилна версия на адаптера
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

# Копираме фронтенда
COPY --from=builder /app/dist /usr/share/nginx/html

# 🚀 ПРОМЕНИ САМО ТОЗИ РЕД: Презаписваме главния nginx.conf, а не default.conf
COPY nginx.conf /etc/nginx/nginx.conf

RUN chmod -R 755 /usr/share/nginx/html

ENV PORT=8080
ENV AWS_LAMBDA_ADAPTER_LOG_LEVEL=debug
ENV REMOVE_BASE_PATH=/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]