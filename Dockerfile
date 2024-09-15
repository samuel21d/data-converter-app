ARG FROMIMAGE=icp.icr.io/cp/apc/ace-server-prod@sha256:c411543e71a30bbbde61459c965f49ef3c86260e71143b8f33a6fbca277a3b9
FROM ${FROMIMAGE}

USER root

# Copy the BAR files into /tmp and process them:
# - Each file is compiled to ensure faster server startup
# - The files are unpacked into the server work directory
# - Once all files are in place, the work directory is optimized to speed up server start
# - The contents are made world-writable to allow for random users at runtime
# 
# The results of the commands can be found in the /tmp/deploys file.

COPY *.bar /tmp

RUN export LICENSE=accept \
    && /opt/ibm/ace-12/server/bin/mqsiprofile \
    && set -x && for FILE in /tmp/*.bar; do \
    echo "$FILE" >> /tmp/deploys && \
    ibmint package --compile-maps-and-schemas --input-bar-file "$FILE" --output-bar-file /tmp/temp.bar 2>&1 | tee -a /tmp/deploys && \
    ibmint deploy --input-bar-file /tmp/temp.bar --output-work-directory /home/aceuser/ace-server 2>&1 | tee -a /tmp/deploys; done \
    && ibmint optimize server --work-dir /home/aceuser/ace-server 2>&1 | tee -a /tmp/deploys \
    && chmod -R ugo+rwx /home/aceuser/

USER 1001