FROM node:24-alpine

# Define el directorio de trabajo
WORKDIR /web/nest_backend

# Copia los archivos de NestJS
COPY nest_backend/package*.json ./

# Instala PM2 y dependencias del proyecto
RUN npm install -g pm2
RUN npm install

# Copia el resto del backend
COPY nest_backend .

# Expone el puerto del backend
EXPOSE 3000

# Arranca con PM2
CMD ["pm2-runtime", "start", "pm2.json"]