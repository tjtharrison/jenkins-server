FROM jenkins/jenkins:lts
USER root
# Copy Dirs
COPY ./config/git-config /etc/gitconfig

# Install packages
RUN curl -sSL https://get.docker.com/ | sh && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated \
        apt-transport-https \
        ca-certificates\
        gnupg \
        jq \
        google-cloud-sdk \
        nano \
        wget \
        curl \
        telnet && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`\
    curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    usermod -aG docker jenkins && \
    apt-get install wget apt-transport-https gnupg lsb-release && \
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - && \
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install trivy

# Install NodeJS and useful packages
RUN cd /tmp/ && \
    curl -sL https://deb.nodesource.com/setup_10.x  | bash && \
    apt-get install nodejs && \
    npm install -g npm@latest && \
    npm install -g eslint

# Setup Helm
RUN cd /tmp/ && \
    wget https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz && \
    tar -zxf helm-v3.0.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/ && \
    ## helm repo add chartmuseum http://chartmuseum.tjth.co:8080 && \
    helm plugin install https://github.com/chartmuseum/helm-push.git && \
    ## helm repo update && \
    rm -rf /tmp/helm-v3.0.0-linux-amd64.tar.gz

# Setup Jenkins User
USER jenkins
RUN git config --global user.email "jenkins@tjth.co" && \
    git config --global user.name "Jenkins Server"