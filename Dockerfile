FROM node:22-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ffmpeg \
      imagemagick \
      ghostscript \
      poppler-utils \
      libreoffice \
      python3 \
      python3-pip \
      file \
      zip \
      libheif-examples \
      clamav \
      fonts-dejavu-core \
      fonts-liberation \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages --no-cache-dir Pillow PyMuPDF

WORKDIR /app
COPY . .

# Fail the image build if the converter runtime is incomplete.
RUN node scripts/doctor.js

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/healthz').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"

CMD ["node","server.js"]
