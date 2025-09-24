# OpenVSCode Server + Java 17 + Spark 3.5.1
FROM gitpod/openvscode-server:1.94.2

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