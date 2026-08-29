# Pin a un digest/version concreta para builds reproducibles si lo necesitas.
FROM jenkins/jenkins:lts-jdk17

USER root

# Docker CLI + buildx: los pipelines lo usan para hablar con el sidecar dind.
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
  && chmod a+r /etc/apt/keyrings/docker.asc \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
       > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /var/jenkins_conf && chown jenkins:jenkins /var/jenkins_conf

USER jenkins

# Zona horaria GMT-5 (Colombia, sin horario de verano) para el SO y la JVM.
ENV TZ=America/Bogota

# Sin wizard: el admin y toda la config vienen de JCasC.
# El YAML vive FUERA de /var/jenkins_home para que un rebuild siempre embarque
# la version nueva (el volumen jenkins-home no la pisa).
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Duser.timezone=America/Bogota"
ENV CASC_JENKINS_CONFIG=/var/jenkins_conf/jenkins.yaml

COPY --chown=jenkins:jenkins casc/jenkins.yaml /var/jenkins_conf/jenkins.yaml

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
