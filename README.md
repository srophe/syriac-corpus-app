# Syriac Corpus Application

A TEI publishing application for Syriac texts and manuscripts, built on a ultra-reliable version of the Gaddel framework.

## Overview

This application provides a digital platform for publishing and exploring Syriac corpus materials encoded in TEI XML. Originally based on the Gaddel framework developed for Syriaca.org, it has been adapted for Syriac manuscript and text collections.

## Features

- **Multi-lingual Interface** - Browse and search in multiple languages
- **TEI Processing** - Convert TEI XML to JSON for searching, browsing, and display
- **TEI Processing** - Convert TEI XML to HTML for item pages
- **Faceted Search** - Filter and browse by author, date, and catalog
- **Full-text Search** - Search within Syriac texts and translations
- **Multi-format Export** - HTML, TEI, JSON formats
- **SPARQL Integration** - RDF triplestore and SPARQL endpoint support

## Requirements

- **Python** 3.7+ (for TEI processing and testing)


## Quick Start

```bash
# Clone repository
git clone <repository-url>
cd syriac-corpus-app

# Install Python dependencies
pip install lxml pytest


```


### TEI Requirements

TEI files must include a unique identifier:
```xml
<tei:publicationStmt>
  <tei:idno type="URI">unique-identifier</tei:idno>
</tei:publicationStmt>
```

## Project Structure

```
syriac-corpus-app/
├── resources/          # CSS, JS, fonts, images
├── siteGenerator/      # XSL templates and components
├── documentation/      # API and wiki documentation
├── exampleData/        # Sample TEI, JSON, HTML files
├── tei2json.py        # TEI to JSON converter
├── index.html         # Main entry point
└── *.html             # Page templates
```

## Configuration

- `repo-config.xml` - Configure data paths and unique identifiers
- `controller.xql` - Define URL routing and request handling

## Development

See [DEV_PROCESS.md](DEV_PROCESS.md) for detailed development workflow, testing procedures, and contribution guidelines.

## Data Format

The application extracts the following from TEI files:
- Title and author information
- Work and catalog URIs (Syriaca.org references)
- Composition dates
- Section divisions with Syriac text
- Full-text content for search indexing in any language

## License

See [LICENSE](LICENSE) for details.

## Links

- [Syriaca.org](http://syriaca.org/)
- [Srophé apps](https://github.com/srophe)
- [Gaddel app](https://github.com/srophe/Gaddel)


