export default {
  logo: <span style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>OrignaGTA Docs</span>,
  project: {
    link: 'https://github.com/yuniorrodriguezosorio/origna_gta',
  },
  docsRepositoryBase: 'https://github.com/yuniorrodriguezosorio/origna_gta/tree/main/docs-site',
  head: {
    title: 'OrignaGTA Documentation',
    description: 'API docs, guides, and resources for OrignaGTA',
    og: {
      title: 'OrignaGTA Documentation',
      description: 'Complete documentation for OrignaGTA e-commerce platform',
    },
  },
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
  i18n: [
    { locale: 'en', text: 'English' },
    { locale: 'fr', text: 'Français' },
  ],
  darkMode: true,
  primaryHue: 260,
}
