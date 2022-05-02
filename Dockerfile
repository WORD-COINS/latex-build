FROM debian:stable-20220316-slim
# WORD内部向けコンテナなので、何か問題が有ったらSlack上で通知して下さい。
MAINTAINER Totsugekitai <37617413+Totsugekitai@users.noreply.github.com>

ENV PERSISTENT_DEPS \
    tar \
    fontconfig \
    unzip \
    wget \
    curl \
    make \
    perl \
    ghostscript \
    bash \
    git \
    groff \
    less \
    fonts-ebgaramond

ENV TEXLIVE_PATH /usr/local/texlive
ENV PATH $TEXLIVE_PATH/bin/x86_64-linux:$PATH

# キャッシュ修正とパッケージインストールは同時にやる必要がある
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    tzdata $PERSISTENT_DEPS

# install awscliv2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -r ./aws awscliv2.zip

ENV FONT_URLS \
    https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/1.050R-it.zip \
    https://github.com/adobe-fonts/source-han-sans/releases/latest/download/SourceHanSansJP.zip \
    https://github.com/adobe-fonts/source-han-serif/raw/release/SubsetOTF/SourceHanSerifJP.zip
ENV FONT_PATH /usr/share/fonts/
RUN mkdir -p $FONT_PATH && \
      wget $FONT_URLS && \
      unzip -j "*.zip" "*.otf" -d $FONT_PATH && \
      rm *.zip && \
      fc-cache -f -v

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
      ebgaramond algorithms algorithmicx xstring siunitx bussproofs

# EBGaramond
RUN cp /usr/share/fonts/opentype/ebgaramond/EBGaramond12-Regular.otf /usr/share/fonts/opentype/EBGaramond.otf && \
    fc-cache -frvv && \
    luaotfload-tool --update

VOLUME ["/workdir"]

WORKDIR /workdir

CMD ["/bin/bash", "-c", "fc-cache && make"]
