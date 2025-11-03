# ---- Etapa de construcción ----
FROM node:22-alpine AS builder
WORKDIR /usr/src/app

# Copia dependencias desde la carpeta nest_backend
COPY nest_backend/package*.json ./
RUN npm install

# Copia el resto del código y compila
COPY nest_backend ./
RUN npm run build

# ---- Etapa de ejecución ----
FROM node:22-alpine AS runner
WORKDIR /usr/src/app

# Copia solo lo necesario desde la etapa de build
COPY --from=builder /usr/src/app/dist ./dist
COPY nest_backend/package*.json ./
RUN npm install --only=production

# Variables de entorno opcionales
ENV NODE_ENV=production
ENV TZ=Europe/Madrid

EXPOSE 3001
CMD ["node", "dist/main.js"]
