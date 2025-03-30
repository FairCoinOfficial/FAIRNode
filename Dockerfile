# Usa una imagen base con Ubuntu 18.04
FROM ubuntu:18.04

# Establece una variable de entorno para evitar la selección interactiva de la zona horaria
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Establece un directorio de trabajo
WORKDIR /app

# Instala las dependencias necesarias, incluyendo una versión específica de OpenSSL
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    libssl1.0-dev \
    libevent-dev \
    libboost-all-dev \
    git \
    cmake \
    wget \
    gcc-7 \
    g++-7 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Establece gcc 7 como el compilador por defecto
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 50 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 50

# Descargar y compilar Berkeley DB 4.8
RUN wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz && \
    tar -xzvf db-4.8.30.NC.tar.gz && \
    cd db-4.8.30.NC/build_unix && \
    ../dist/configure --enable-cxx && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf db-4.8.30.NC db-4.8.30.NC.tar.gz

# Establecer las variables de entorno para Berkeley DB
ENV BDB_PREFIX="/usr/local/BerkeleyDB.4.8"
ENV LD_LIBRARY_PATH="${BDB_PREFIX}/lib"

# Clona el repositorio de FairCoin
RUN git clone https://github.com/FairCoinOfficial/FairCoin.git .

# Compila el código fuente
RUN ./autogen.sh && \
    CXXFLAGS="-Wno-error" ./configure LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" --with-ssl=openssl && \
    make

# Expone el puerto del nodo
EXPOSE 40404

# Comando para ejecutar el nodo
CMD ["./src/faircoind"]
