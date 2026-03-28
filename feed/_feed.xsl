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
      <title><xsl:value-of select="/rss/channel/title"/> – DR Lyd Recycled</title>
      <link rel="icon" href="/assets/icon-recycle.svg">
      <link rel="stylesheet" href="/stylesheet.css">
      <style>
        :root {
          --bg:        #1a1a1a;
          --surface:   #242424;
          --surface2:  #2c2c2c;
          --border:    #333333;
          --accent:    #c0392b;
          --accent-hv: #e74c3c;
          --text:      #e8e8e8;
          --text-muted:#999999;
          --radius:    6px;
          --logo-h:    2rem;
        }

        @media (prefers-color-scheme: light) {
          :root {
            --bg:        #f5f5f5;
            --surface:   #ffffff;
            --surface2:  #f0f0f0;
            --border:    #dddddd;
            --accent:    #c0392b;
            --accent-hv: #a93226;
            --text:      #1a1a1a;
            --text-muted:#666666;
          }
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        html, body {
          min-height: 100%;
          background: var(--bg);
          color: var(--text);
          font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
          font-size: 16px;
          line-height: 1.5;
        }

        a { color: var(--accent); }
        a:hover { color: var(--accent-hv); }

        /* ── HEADER ─────────────────────────────────────────────── */
        header {
          background: var(--surface);
          border-bottom: 2px solid var(--accent);
          padding: 0.75rem 1.25rem;
        }
        .header-inner {
          max-width: 900px;
          margin: 0 auto;
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }
        .logo-link {
          display: flex;
          align-items: center;
          flex-shrink: 0;
          line-height: 0;
        }
        .logo-link img {
          height: var(--logo-h);
          width: auto;
          display: block;
          transition: opacity 0.2s;
        }
        .logo-link:hover img { opacity: 0.75; }
        .header-title {
          flex: 1;
          text-align: center;
        }
        .header-title h1 {
          font-size: clamp(1.1rem, 3vw, 1.6rem);
          font-weight: 700;
          color: var(--accent);
          letter-spacing: 0.02em;
          line-height: 1.1;
        }
        .header-title p {
          font-size: clamp(0.7rem, 2vw, 0.85rem);
          color: var(--text-muted);
          letter-spacing: 0.06em;
          text-transform: uppercase;
          margin-top: 0.1rem;
        }
        .back-link {
          font-size: 0.85rem;
          font-weight: 600;
          color: var(--text-muted);
          text-decoration: none;
          white-space: nowrap;
          flex-shrink: 0;
        }
        .back-link:hover { color: var(--text); }

        /* ── MAIN ────────────────────────────────────────────────── */
        main {
          max-width: 900px;
          margin: 1.5rem auto 3rem;
          padding: 0 1rem;
        }

        /* ── HERO ────────────────────────────────────────────────── */
        .podcast-hero {
          display: flex;
          gap: 1.5rem;
          align-items: flex-start;
          background: var(--surface);
          border: 1px solid var(--border);
          border-radius: var(--radius);
          padding: 1.25rem;
          margin-bottom: 1.5rem;
        }
        .podcast-cover {
          flex-shrink: 0;
          width: clamp(100px, 20vw, 180px);
        }
        .podcast-cover img {
          width: 100%;
          aspect-ratio: 1/1;
          object-fit: cover;
          border-radius: var(--radius);
          display: block;
        }
        .podcast-info { flex: 1; min-width: 0; }
        .podcast-info h2 {
          font-size: clamp(1.2rem, 4vw, 1.75rem);
          font-weight: 700;
          line-height: 1.2;
          margin-bottom: 0.5rem;
          color: var(--text);
        }
        .podcast-info .description {
          font-size: 0.875rem;
          color: var(--text-muted);
          line-height: 1.6;
          margin-bottom: 1rem;
        }

        /* Subscribe bar */
        .subscribe-bar {
          display: flex;
          flex-wrap: wrap;
          gap: 0.5rem;
          align-items: center;
          padding: 0.75rem 1rem;
          background: var(--surface2);
          border: 1px solid var(--border);
          border-left: 3px solid var(--accent);
          border-radius: var(--radius);
          margin-bottom: 1.5rem;
        }
        .subscribe-bar span.label {
          font-size: 0.8rem;
          color: var(--text-muted);
          text-transform: uppercase;
          letter-spacing: 0.05em;
          font-weight: 600;
        }
        .subscribe-btn {
          display: inline-block;
          background: var(--accent);
          color: #fff !important;
          text-decoration: none;
          font-size: 0.82rem;
          font-weight: 700;
          padding: 0.35rem 0.8rem;
          border-radius: 4px;
        }
        .subscribe-btn:hover { background: var(--accent-hv); }
        .subscribe-btn.outline {
          background: transparent;
          border: 1px solid var(--border);
          color: var(--text-muted) !important;
        }
        .subscribe-btn.outline:hover { border-color: var(--accent); color: var(--text) !important; }

        /* ── EPISODES ────────────────────────────────────────────── */
        .section-heading {
          font-size: 0.75rem;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          color: var(--text-muted);
          font-weight: 700;
          margin-bottom: 0.75rem;
        }
        .episode-list {
          display: flex;
          flex-direction: column;
          gap: 1px;
        }
        .episode {
          background: var(--surface);
          border: 1px solid var(--border);
          border-radius: var(--radius);
          overflow: hidden;
          margin-bottom: 0.5rem;
        }
        .episode-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0.75rem 1rem;
          cursor: pointer;
          gap: 1rem;
        }
        .episode-header:hover { background: var(--surface2); }
        .episode-title {
          font-size: 0.9rem;
          font-weight: 600;
          color: var(--text);
          flex: 1;
          min-width: 0;
        }
        .episode-meta {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          gap: 0.1rem;
          flex-shrink: 0;
        }
        .episode-date, .episode-duration {
          font-size: 0.73rem;
          color: var(--text-muted);
          white-space: nowrap;
        }
        .episode-chevron {
          color: var(--text-muted);
          font-size: 0.75rem;
          flex-shrink: 0;
        }
        .episode-body {
          padding: 0 1rem 1rem;
          border-top: 1px solid var(--border);
        }
        .episode-description {
          font-size: 0.85rem;
          color: var(--text-muted);
          line-height: 1.6;
          margin: 0.75rem 0 1rem;
        }
        audio.episode-player {
          width: 100%;
          display: block;
          border-radius: 4px;
          accent-color: var(--accent);
        }

        /* Details/summary toggle */
        details > summary { list-style: none; }
        details > summary::-webkit-details-marker { display: none; }

        /* ── FOOTER ─────────────────────────────────────────────── */
        footer {
          text-align: center;
          padding: 1.5rem 1rem;
          color: var(--text-muted);
          font-size: 0.75rem;
          border-top: 1px solid var(--border);
          margin-top: 2rem;
          max-width: 900px;
          margin-left: auto;
          margin-right: auto;
        }

        @media (max-width: 540px) {
          .podcast-hero { flex-direction: column; }
          .podcast-cover { width: 120px; }
        }
      </style>
    </head>
    <body>

    <header>
      <div class="header-inner">
        <a class="logo-link" href="https://www.dr.dk/lyd" title="DR Lyd" target="_blank" rel="noopener">
          <img src="assets/icon-logo-drlyd.svg" alt="DR Lyd"/>
        </a>
        <div class="header-title">
          <h1>DR Lyd</h1>
          <p>Recycled</p>
        </div>
        <a class="back-link" href="./">← Alle podcasts</a>
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
        <a class="subscribe-btn" href="podcast:{$feedPath}">🎙 Podcast-app</a>
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
                <span class="episode-chevron">▼</span>
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
                    Din browser understøtter ikke HTML5-lyd.
                  </audio>
                </xsl:if>
              </div>
            </details>
          </div>
        </xsl:for-each>
      </div>
    </main>

    <footer>
      <a href="./">DR Lyd – Recycled</a>
    </footer>

    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
