FROM alpine:3.11
# WORD内部向けコンテナなので、何か問題が有ったらSlack上で通知して下さい。
MAINTAINER rizaudo <rizaudo@users.noreply.github.com>

ENV TEXLIVE_DEPS \
    xz \
    tar \
    fontconfig-dev

ENV FONT_DEPS \
    unzip \
    fontconfig-dev

ENV PERSISTENT_DEPS \
    wget \
    curl \
    make \
    perl \
    ghostscript \
    bash \
    git

ENV TEXLIVE_PATH /usr/local/texlive
ENV PATH $TEXLIVE_PATH/bin/x86_64-linuxmusl:$PATH

ENV GLIBC_VER=2.35-r0

# キャッシュ修正とパッケージインストールは同時にやる必要がある
RUN apk upgrade --update-cache && \
    apk add --no-cache tzdata && \
    apk add --no-cache --virtual .texlive-deps $TEXLIVE_DEPS && \
    apk add --no-cache --virtual .persistent-deps $PERSISTENT_DEPS && \
    apk add --no-cache --virtual .font-deps $FONT_DEPS && \
    # install glibc
    apk add --no-cache binutils curl && \
    curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk && \
    apk add --no-cache glibc-${GLIBC_VER}.apk glibc-bin-${GLIBC_VER}.apk && \
    # install aws-cli
    curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip -q awscliv2.zip && \
    aws/install && \
    rm awscliv2.zip

ENV FONT_URLS \
    https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/1.050R-it.zip \
    https://github.com/adobe-fonts/source-han-sans/releases/latest/download/SourceHanSansJP.zip \
    https://github.com/adobe-fonts/source-han-serif/raw/release/SubsetOTF/SourceHanSerifJP.zip 
ENV FONT_PATH /usr/share/fonts/
RUN mkdir -p $FONT_PATH && \
      wget $FONT_URLS && \
      unzip -j "*.zip" "*.otf" -d $FONT_PATH && \
      rm *.zip && \
      fc-cache -f -v && \
      apk del .font-deps

RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo 'Asia/Tokyo' > /etc/timezone

# Install TeXLive
RUN mkdir -p /tmp/install-tl-unx && \
    wget -qO- http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | \
      tar -xz -C /tmp/install-tl-unx --strip-components=1 && \
    printf "%s\n" \
      "TEXDIR $TEXLIVE_PATH" \
      "selected_scheme scheme-small" \
      "option_doc 0" \
      "option_src 0" \
      "option_autobackup 0" \
      > /tmp/install-tl-unx/texlive.profile && \
    /tmp/install-tl-unx/install-tl \
      -profile /tmp/install-tl-unx/texlive.profile

# tlmgr section
RUN tlmgr update --self

# package install
RUN tlmgr install --no-persistent-downloads \
      latexmk collection-luatex collection-langjapanese \
      collection-fontsrecommended type1cm mdframed needspace newtx \
      fontaxes boondox everyhook svn-prov framed subfiles titlesec \
      tocdata xpatch etoolbox l3packages \
      biblatex pbibtex-base logreq biber import environ trimspaces tcolorbox \
      ebgaramond algorithms algorithmicx xstring siunitx && \
    apk del .texlive-deps

VOLUME ["/workdir"]

WORKDIR /workdir

CMD ["/bin/bash", "-c", "make"]
