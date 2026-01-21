# PDF Generation

## Prerequisites

| Tool    | Version | Install                                                                              |
|---------|---------|--------------------------------------------------------------------------------------|
| Ruby    | 3.4+    | `sudo pacman -S ruby` (Arch/Manjaro)<br>`sudo apt install ruby-full` (Ubuntu/Debian) |
| Bundler | 2.6+    | `gem install bundler`                                                                |

## Setup

```bash
# Install Ruby gems (asciidoctor-pdf, rouge, bigdecimal)
bundle install

# Install npm packages
npm install
```

## Usage

```bash
# Cloud edition (default)
npm run pdf

# Qube edition
npm run pdf:qube
```

## Output

PDF generated at: `build/assembler-pdf/docs/_exports/index.pdf`

## Architecture

- `@antora/pdf-extension` (Node) - Assembles pages, resolves Antora attributes (`{productName}`, xrefs)
- `asciidoctor-pdf` (Ruby gem) - Renders PDF

The wrapper script `scripts/pdf-node.sh` ensures the bundle bin directory is in PATH when Antora calls `bundle exec asciidoctor-pdf`.

## Troubleshooting

**"Command not found: bundle"**
- Bundler not in PATH. Wrapper script handles this.

**"cannot load such file -- bigdecimal"**
- Ruby 3.4+ requires bigdecimal gem (already in Gemfile).

**Missing images/warnings**
- Non-critical. PDF still generates correctly.
