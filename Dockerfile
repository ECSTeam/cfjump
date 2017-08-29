FROM ubuntu:16.04
MAINTAINER CGI 

ENV HOME /home/ops
ENV ENAML /opt/enaml
ENV OMG_PLUGIN_DIR $ENAML/plugins
ENV OMGBIN $ENAML/bin
ENV CFPLUGINS /opt/cf-plugins
ENV GOPATH /opt/go
ENV GOBIN /opt/go/bin
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/bin:/usr/local/go/bin:$GOBIN:$OMGBIN

ADD update_enaml.sh /usr/local/bin

RUN mkdir -p $HOME
RUN mkdir -p $ENAML
RUN mkdir -p $GOBIN
RUN mkdir -p $CFPLUGINS
RUN mkdir -p $OMG_PLUGIN_DIR
VOLUME $HOME
WORKDIR $HOME
RUN mkdir -p $HOME/bin
RUN cp -n /etc/skel/.[a-z]* .

RUN cat /etc/apt/sources.list | sed 's/archive/us.archive/g' > /tmp/s && mv /tmp/s /etc/apt/sources.list
RUN apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
RUN apt-get update && apt-get -y --no-install-recommends install wget curl apt-transport-https
RUN echo "deb [arch=amd64] http://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update && apt-get -y --no-install-recommends install ruby libroot-bindings-ruby-dev \
           build-essential git ssh zip software-properties-common dnsutils \
           iputils-ping traceroute jq vim wget unzip sudo iperf screen tmux \
           file openstack tcpdump nmap less s3cmd s3curl direnv \
           netcat npm nodejs-legacy python3-pip python3-setuptools \
           apt-utils libdap-bin mysql-client mongodb-clients postgresql-client-9.5 \
           redis-tools libpython2.7-dev libxml2-dev libxslt-dev azure-cli

RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-xenial main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update && sudo apt-get -y --no-install-recommends install google-cloud-sdk

RUN curl -O https://bootstrap.pypa.io/get-pip.py && python2.7 ./get-pip.py && rm -f python2.7 ./get-pip.py

RUN pip3 install --upgrade pip

RUN pip3 install awscli

RUN curl -L \
    "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" \
    | tar -C /usr/local/bin -zx

# Install the latest version of Hashicorp's Vault 
RUN wget $(wget -O- -q https://www.vaultproject.io/downloads.html | grep linux_amd | awk -F "\"" '{print$2}') -O vault.zip && unzip vault.zip && cp vault /usr/local/bin/vault
RUN chmod 755 /usr/local/bin/vault

# Install latest version of Terraform
RUN wget -O terraform.zip \
    "https://releases.hashicorp.com/terraform/$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')/terraform_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')_linux_amd64.zip" && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin && \
    rm terraform.zip

RUN gem install cf-uaac --no-rdoc --no-ri

RUN cd /usr/local/bin && wget -q -O om \
    "$(curl -s https://api.github.com/repos/pivotal-cf/om/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url' | grep linux)" && chmod +x om 

RUN cd /usr/local/bin && wget -q -O fly \
    "$(curl -s https://api.github.com/repos/concourse/fly/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url' | grep linux)" && chmod +x fly

# Install BOSH
RUN gem install bosh_cli --no-ri --no-rdoc

# Install BOSH-v2 CLI
RUN cd /usr/local/bin && wget -q -O bosh2 https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.28-linux-amd64 && chmod 0755 bosh2

RUN cd /usr/local/bin && wget -q -O pivnet \
    "$(curl -s https://api.github.com/repos/pivotal-cf/pivnet-cli/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url' | grep linux | grep -v zip)" && chmod +x pivnet

RUN cd /usr/local/bin && wget -q -O cfops \
    "$(curl -s https://api.github.com/repos/pivotalservices/cfops/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url')" && chmod +x cfops

RUN cd /usr/local/bin && wget -q -O spiff.zip \
    "$(curl -s https://api.github.com/repos/cloudfoundry-incubator/spiff/releases/latest \
    | jq -r '.assets[] | select(.name == "spiff_linux_amd64.zip") | .browser_download_url')" \
    && unzip spiff.zip \
    && rm spiff.zip

RUN cd /usr/local/bin && wget -q -O spruce \
    "$(curl -s https://api.github.com/repos/geofffranks/spruce/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url' | grep linux | grep -v zip)" && chmod +x spruce

RUN cd /usr/local/bin && wget -q -O safe \
    "$(curl -s https://api.github.com/repos/starkandwayne/safe/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url' | grep linux)" && chmod +x safe

RUN cd /usr/local/bin && wget -q -O cf-mgmt \
    "$(curl -s https://api.github.com/repos/pivotalservices/cf-mgmt/releases/latest \
    |jq --raw-output '.assets[] | .browser_download_url' | grep linux | grep -v zip)" && chmod +x cf-mgmt

RUN cd /usr/local/bin && wget -q -O cliaas \
    "$(curl -s https://api.github.com/repos/pivotal-cf/cliaas/releases/latest|jq --raw-output '.assets[] | .browser_download_url' | grep linux)" && chmod +x cliaas

RUN cd /usr/local/bin && wget -q -O - https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/1.2.0/credhub-linux-1.2.0.tgz | tar xzf - > credhub && chmod 0755 credhub

RUN cd /usr/local/bin && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod 0755 kubectl

ADD firstrun.sh /usr/local/bin
ADD add_go.sh /usr/local/bin
ADD add_extras.sh /usr/local/bin
RUN apt-get -y autoremove && apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*

CMD ["/bin/bash"]
