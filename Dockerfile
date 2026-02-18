FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Core packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    make \
    vim \
    bat \
    fish \
    sudo \
    jq \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Go (latest stable from official tarball)
ARG GO_VERSION=1.23.6
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Node.js (LTS via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with sudo access
ARG USERNAME=dev
RUN useradd -m -s /usr/bin/fish ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USERNAME}
ENV HOME="/home/${USERNAME}"
WORKDIR ${HOME}

# Claude Code (official native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="${HOME}/.local/bin:${PATH}"

# Fish config (vim mode + bat alias)
RUN mkdir -p ${HOME}/.config/fish \
    && echo 'fish_vi_key_bindings' >> ${HOME}/.config/fish/config.fish \
    && echo 'alias bat="batcat"' >> ${HOME}/.config/fish/config.fish

# Vim config
COPY --chown=${USERNAME}:${USERNAME} vimrc ${HOME}/.vimrc
RUN mkdir -p ${HOME}/.vim/backup ${HOME}/.vim/swp ${HOME}/.vim/undo

# Save default dotfiles to skeleton so entrypoint can seed them into a mounted home
USER root
RUN cp -a ${HOME}/. /etc/skel-dev/ && chown -R ${USERNAME}:${USERNAME} /etc/skel-dev
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Run entrypoint as root so it can adjust UID/GID, then exec as dev
ENTRYPOINT ["entrypoint.sh"]
CMD ["fish"]
