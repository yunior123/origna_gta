export default {
  logo: <span style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>OrignaGTA Docs</span>,
  project: {
    link: 'https://github.com/yuniorrodriguezosorio/origna_gta',
  },
  docsRepositoryBase: 'https://github.com/yuniorrodriguezosorio/origna_gta/tree/main/docs-site',
  head: (
    <>
      <meta name="description" content="API docs, guides, and resources for OrignaGTA" />
      <meta property="og:title" content="OrignaGTA Documentation" />
      <meta property="og:description" content="Complete documentation for OrignaGTA e-commerce platform" />
      <meta property="og:type" content="website" />
    </>
  ),
  footer: {
    text: (
      <span>
        © 2026 OrignaGTA. {' '}
        <a href="https://orignagta.ca" target="_blank" rel="noreferrer">
          Visit Platform
        </a>
      </span>
    ),
  },
  darkMode: true,
  primaryHue: 260,
}
