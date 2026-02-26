# Development Process

## Setup

### Prerequisites
- Python 3.13+
- Git

### Initial Setup
```bash
# Clone repositories
git clone <syriac-corpus-app-repo>
git clone <syriac-corpus-data-repo>

# Use virtual environment

python3 -m venv .venv
source .venv/bin/activate
# Install Python dependencies
pip install lxml pytest
or
pip3 install lxml pytest


# Test json conversion just on sample data
cd syriac-corpus-app
python tei2json.py exampleData/xml/ -o exampleData/output/

# Test json conversion on full data set

# Build and deploy
cd syriac-corpus-app
ant
```

## Development Workflow

### 1. Data Processing
Convert TEI XML to JSON for indexing:
```bash
# Single file
python tei2json.py input.xml

# Batch process directory
python tei2json.py --dir ./data/tei --outdir json_output

# Generate manuscripts.json for web UI
python tei2json.py --dir ./data/tei --manuscripts manuscripts.json
```

### 2. Testing Changes
```bash
# Build XAR package
ant

# Deploy via eXist-db dashboard
# http://localhost:8080/exist/apps/dashboard/index.html
```

### 3. Git Workflow
```bash
# Create feature branch
git checkout -b feature/description

# Commit changes
git add .
git commit -m "Description"

# Push and create PR
git push origin feature/description
```

## Project Structure
```
srophe/syriac-corpus-app/
├── exampleData/        # input and output data files for testing
├── api-documentation/           ??
├── resources/          # CSS, JS, images
├── siteGenerator/      # XSLT stylesheets for HTML conversion
├── tei2json.py         # TEI to JSON converter
├── repo-config.xml     # App configuration?
└── controller.xql      # URL routing?

srophe/syriac-corpus/
├── build/              # legacy?
├── modules/           # XQuery modules
├── resources/         # CSS, JS, images
├── templates/         # HTML templates
├── data/tei/       # TEI files for JSON converter
├── repo-config.xml   # App configuration
└── controller.xql    # URL routing
```

## Key Files
- `tei2json.py` - Extracts structured data from TEI XML
- `repo-config.xml` - Configure data paths and identifiers
- `controller.xql` - Define URL routes and handlers

## Common Tasks

### Add New TEI Records
1. Put or edit XML files in `data/tei/`
2. Ensure unique `tei:idno[@type='URI']` exists
3. Run `tei2json.py` to generate JSON in GitHub actions, manual process
4. Rebuild and redeploy application: CICD pipeline in GitHub runs automatically if it detects any code repo changes, including json data file changes


## Troubleshooting

### Build fails
- Look through GitHub actions logs 

### Search or browse issues
- Verify TEI has required `tei:idno[@type='URI']`
- Look through GitHub actions logs 

### HTML issues
- Review namespace declarations 
- Look through GitHub actions logs 

### Python script errors
- Install lxml: `pip install lxml`
- Check XML is well-formed

