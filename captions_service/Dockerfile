# A plain Node buildpack doesn't let us install system packages, and
# @sparticuz/chromium - despite being the minimal, serverless-oriented
# Chromium build - still needs a handful of real OS shared libraries
# present (confirmed directly: it failed to even launch without libnss3).
# This installs exactly the set Chromium headless needs on Debian, no more.
FROM node:24-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .

ENV NODE_ENV=production
EXPOSE 8080
CMD ["node", "index.js"]
