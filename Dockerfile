FROM python:3.8.5
ENV http_proxy http://proxy.fcen.uba.ar:8080
ENV https_proxy http://proxy.fcen.uba.ar:8080
# Password is taken from the file 'auth', in the root of
# the repo. This file should be in .gitignore to prevent it from
# being committed.
RUN apt-get update \
    && apt-get install -y openssh-server sudo \
       dirmngr gnupg apt-transport-https ca-certificates software-properties-common build-essential \
    && apt-get update && apt-get install -y sumo sumo-tools sumo-doc


## Now install R and littler, and create a link for littler in /usr/local/bin
RUN apt-key adv --keyserver keyserver.ubuntu.com --keyserver-options http-proxy=http://proxy.fcen.uba.ar:8080 --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' \
    && echo "deb http://cloud.r-project.org/bin/linux/debian buster-cran40/" >> /etc/apt/sources.list
RUN apt-get update \
    && apt-get install -y \
		littler \
        r-cran-littler \
		r-base \
		r-base-dev \
        r-base-core \
		r-recommended \
	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installDeps.r /usr/local/bin/installDeps.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -rm -d /home/sumo -s /bin/bash -g root -G sudo -u 1000 sumo 
RUN mkdir /var/run/sshd
ADD auth /
RUN cat /auth | chpasswd 
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
RUN /etc/init.d/ssh start

ADD requirements.txt r_packages.txt /home/sumo/
WORKDIR /home/sumo
RUN pip install -r requirements.txt && install.r $(cat r_packages.txt | tr '\n' ' ')

CMD /etc/init.d/ssh start && bash
