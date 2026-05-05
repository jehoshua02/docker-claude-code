FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    openssh-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash claude

USER claude
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root

RUN mkdir -p /workspace && chown claude:claude /workspace

RUN mkdir -p /home/claude/.ssh && \
    ssh-keyscan -H github.com gitlab.com bitbucket.org > /home/claude/.ssh/known_hosts 2>/dev/null && \
    cp /home/claude/.ssh/known_hosts /home/claude/known_hosts.bak && \
    chown claude:claude /home/claude/known_hosts.bak && \
    chmod 644 /home/claude/known_hosts.bak && \
    chown -R claude:claude /home/claude/.ssh && \
    chmod 700 /home/claude/.ssh && \
    chmod 644 /home/claude/.ssh/known_hosts

ENV PATH="/home/claude/.local/bin:${PATH}"
ENV GIT_CONFIG_GLOBAL="/tmp/.gitconfig"

RUN rm -f /home/claude/.claude.json && ln -s /tmp/.claude.json /home/claude/.claude.json

USER claude
WORKDIR /workspace

COPY --chown=claude:claude entrypoint.sh /home/claude/entrypoint.sh
RUN chmod +x /home/claude/entrypoint.sh

ENTRYPOINT ["/home/claude/entrypoint.sh"]
CMD []
