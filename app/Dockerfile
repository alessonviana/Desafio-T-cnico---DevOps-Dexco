# FROM node:14

# COPY package*.json ./

# RUN npm install

# COPY . .

# EXPOSE 3000

# CMD ["node", "index.js"]

FROM node:14

# Criar diretório de trabalho
WORKDIR /app

# # Copiar apenas os arquivos de dependência e instalar
# COPY package*.json ./
# RUN npm install

# Copiar os artefatos buildados
COPY dist ./dist

EXPOSE 3000

CMD ["node", "dist/index.js"]
