# OpenVSCode Server + Java 17 + Spark 3.5.1
FROM gitpod/openvscode-server:1.94.2

# Security: refresh all security fixes in the base, then remove risky/unused tools
USER root
ENV DEBIAN_FRONTEND=noninteractive

# 1) Bring the base up to date (fixes many CVEs in glibc, curl, git, krb5, pam, expat, etc.)
RUN apt-get update && apt-get -y upgrade

# 2) Explicitly upgrade frequently-flagged libs (idempotent; OK if already current)
RUN apt-get install -y --only-upgrade \
    curl libcurl4 \
    libtasn1-6 libcap2 libssh-4 \
    sqlite3 libsqlite3-0 \
    libc6 libc-bin \
    libpam0g \
    libexpat1 \
    libkrb5-3 libk5crypto3 libgssapi-krb5-2 libkrb5support0 \
    git

# 3) Remove stuff you don't need (reduces attack surface)
#    Only purge if you truly don't need them in the running container.
RUN apt-get purge -y sudo perl || true

# 4) Clean up
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*


USER root
ENV DEBIAN_FRONTEND=noninteractive

# ---- Java 17 (OpenJDK) & basic tools ----
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates wget gnupg tar unzip bash procps \
      openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ---- Spark 3.5.1 (pick Hadoop line that matches your cluster) ----
ARG SPARK_VERSION=4.0.1
ARG HADOOP_LINE=3
ENV SPARK_HOME=/opt/spark

#https://downloads.apache.org/spark/spark-4.0.1/spark-4.0.1-bin-hadoop3.tgz
RUN curl -fsSL "https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_LINE}.tgz" \
      -o /tmp/spark.tgz \
 && tar -xzf /tmp/spark.tgz -C /opt \
 && mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_LINE}" "${SPARK_HOME}" \
 && rm -f /tmp/spark.tgz

ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"

# --- Python 3.11 (with pip), make `python` point to 3.11 ---
# (for Ubuntu-based images; gitpod/openvscode-server is Ubuntu)
RUN apt-get update && apt-get install -y --no-install-recommends \
      software-properties-common ca-certificates curl \
  && add-apt-repository ppa:deadsnakes/ppa -y \
  && apt-get update && apt-get install -y --no-install-recommends \
      python3.11 python3.11-venv python3.11-distutils \
  && curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
  && python3.11 /tmp/get-pip.py \
  && rm -f /tmp/get-pip.py \
  # set `python` to 3.11 and (optionally) make python3 default 3.11
  && ln -sf /usr/bin/python3.11 /usr/local/bin/python \
  && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2

ENV PYSPARK_PYTHON=/usr/bin/python3.11
RUN mv /usr/bin/python3.10 /usr/bin/python3.10.disabled || true

# Use python3.11's pip so packages land under 3.11
RUN python3.11 -m pip install --no-cache-dir \
      jupyter \
      ipykernel==6.29.5
# (add pandas, pyarrow, boto3, etc. as needed)


# Python + Jupyter bits users expect
#RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip && rm -rf /var/lib/apt/lists/*
#RUN pip3 install --no-cache-dir \
#    jupyter \
#    ipykernel==6.29.5

RUN python3.11 -m ipykernel install --user --name py311 --display-name "Python 3.11"

# Preinstall VS Code extensions for notebooks
ENV OPENVSCODE_SERVER_ROOT=/home/.openvscode-server
RUN ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --install-extension ms-python.python \
 && ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --install-extension ms-toolsai.jupyter


# Drop back to the non-root user used by openvscode-servere
USER 1000:1000