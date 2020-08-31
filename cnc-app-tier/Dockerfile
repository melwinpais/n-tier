FROM node:10-alpine

# COPY certs/rds-ca-2019-root.pem /usr/local/share/ca-certificates/rds-ca-2019-root.pem
# RUN update-ca-certificates
# ENV PGSSLROOTCERT /etc/ssl/certs/ca-certificates.crt
# ENV PGSSLMODE verify-full

WORKDIR /usr/src/app

COPY package*.json ./
COPY certs/rds-ca-2019-root.pem ./certs/

RUN npm install
COPY . .

EXPOSE 3000
CMD [ "node", "index.js" ]
