<!-- Created with Claude -->
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
  xmlns:atom="http://www.w3.org/2005/Atom"
  exclude-result-prefixes="itunes atom">

<xsl:output method="html" version="5" encoding="UTF-8" indent="yes"/>

<xsl:template match="/">
  <html lang="da">
    <head>
      <meta charset="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <title><xsl:value-of select="/rss/channel/title"/> &#x2014; DR Lyd Recycled</title>
      <link rel="icon" href="/assets/icon-recycle.svg"/>
      <link rel="stylesheet" href="/shared.css"/>

      <!-- Apply saved theme before first paint to avoid flash -->
      <script>
        (function () {
          var m = document.cookie.match(/(?:^|;\s*)theme=(dark|light)/);
          if (m) document.documentElement.setAttribute('data-theme', m[1]);
        })();
      </script>

      <style>
        /* feed.xsl only: details/summary chevron rotates via CSS open state */
        details > summary { list-style: none; cursor: pointer; }
        details > summary::-webkit-details-marker { display: none; }
        .episode-chevron { display: inline-block; transition: transform 0.2s; }
        details[open] .episode-chevron { transform: rotate(180deg); }
      </style>
    </head>
    <body>

    <header>
      <div class="header-inner">
        <a class="logo-link" href="https://www.dr.dk/lyd" title="DR Lyd" target="_blank" rel="noopener">
          <img src="/assets/icon-logo-drlyd.svg" alt="DR Lyd"/>
        </a>

        <div class="header-title">
          <h1>DR Lyd</h1>
          <p>Recycled</p>
        </div>

        <button class="theme-toggle" id="theme-toggle" title="Skift farvetema" aria-label="Skift farvetema">
          <span class="icon-to-dark"  aria-hidden="true">&#x1F319;</span>
          <span class="icon-to-light" aria-hidden="true">&#x2600;&#xFE0F;</span>
        </button>

        <a class="back-link" href="../">&#x2190; Alle podcasts</a>
      </div>
    </header>

    <main>
      <!-- Hero -->
      <div class="podcast-hero">
        <div class="podcast-cover">
          <xsl:choose>
            <xsl:when test="/rss/channel/itunes:image/@href">
              <img src="{/rss/channel/itunes:image/@href}" alt="{/rss/channel/title}"/>
            </xsl:when>
            <xsl:when test="/rss/channel/image/url">
              <img src="{/rss/channel/image/url}" alt="{/rss/channel/title}"/>
            </xsl:when>
          </xsl:choose>
        </div>
        <div class="podcast-info">
          <h2><xsl:value-of select="/rss/channel/title"/></h2>
          <p class="description"><xsl:value-of select="/rss/channel/description"/></p>
        </div>
      </div>

      <!-- Subscribe bar -->
      <div class="subscribe-bar">
        <span class="label">Abonner:</span>
        <xsl:variable name="feedPath" select="/rss/channel/atom:link/@href"/>
        <a class="subscribe-btn" href="podcast:{$feedPath}">&#x1F399; Podcast-app</a>
        <xsl:if test="$feedPath">
          <a class="subscribe-btn outline" href="{$feedPath}" target="_blank" rel="noopener">RSS</a>
        </xsl:if>
        <xsl:if test="/rss/channel/link">
          <a class="subscribe-btn outline" href="{/rss/channel/link}" target="_blank" rel="noopener">DR Lyd</a>
        </xsl:if>
      </div>

      <!-- Episode count -->
      <p class="section-heading">
        <xsl:value-of select="count(/rss/channel/item)"/> episoder
      </p>

      <!-- Episode list -->
      <div class="episode-list">
        <xsl:for-each select="/rss/channel/item">
          <div class="episode">
            <details>
              <summary class="episode-header">
                <span class="episode-title"><xsl:value-of select="title"/></span>
                <span class="episode-meta">
                  <xsl:if test="pubDate">
                    <span class="episode-date"><xsl:value-of select="pubDate"/></span>
                  </xsl:if>
                  <xsl:if test="itunes:duration">
                    <span class="episode-duration"><xsl:value-of select="itunes:duration"/></span>
                  </xsl:if>
                </span>
                <span class="episode-chevron">&#x25BC;</span>
              </summary>
              <div class="episode-body">
                <xsl:if test="description">
                  <div class="episode-description">
                    <xsl:value-of select="description"/>
                  </div>
                </xsl:if>
                <xsl:if test="enclosure/@url">
                  <audio class="episode-player" controls="controls" preload="none">
                    <xsl:attribute name="src"><xsl:value-of select="enclosure/@url"/></xsl:attribute>
                    <xsl:if test="enclosure/@type">
                      <xsl:attribute name="type"><xsl:value-of select="enclosure/@type"/></xsl:attribute>
                    </xsl:if>
                    Din browser underst&#xF8;tter ikke HTML5-lyd.
                  </audio>
                </xsl:if>
              </div>
            </details>
          </div>
        </xsl:for-each>
      </div>
    </main>

    <footer>
      <a href="../">DR Lyd &#x2014; Recycled</a>
    </footer>

    <script>
      (function () {
        document.getElementById('theme-toggle').addEventListener('click', function () {
          var html    = document.documentElement;
          var current = html.getAttribute('data-theme');
          if (!current) {
            current = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
          }
          var next = current === 'dark' ? 'light' : 'dark';
          html.setAttribute('data-theme', next);
          document.cookie = 'theme=' + next + '; path=/; max-age=31536000; SameSite=Lax';
        });
      })();
    </script>

    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
