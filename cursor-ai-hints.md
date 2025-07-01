# Cursor AI hints

## 1. misc

## 2. Markdown

- When you edit markdown, stick to the format style that the files already have
- Stick to the Markdownlint rules
  - MD001 heading-increment - Heading levels should only increment by one level at a time
  - MD003 heading-style - Heading style
  - MD004 ul-style - Unordered list style
  - MD005 list-indent - Inconsistent indentation for list items at the same level
  - MD007 ul-indent - Unordered list indentation
  - MD009 no-trailing-spaces - Trailing spaces
  - MD010 no-hard-tabs - Hard tabs
  - MD011 no-reversed-links - Reversed link syntax
  - MD012 no-multiple-blanks - Multiple consecutive blank lines
  - MD013 line-length - Line length
  - MD014 commands-show-output - Dollar signs used before commands without showing output
  - MD018 no-missing-space-atx - No space after hash on atx style heading
  - MD019 no-multiple-space-atx - Multiple spaces after hash on atx style heading
  - MD020 no-missing-space-closed-atx - No space inside hashes on closed atx style heading
  - MD021 no-multiple-space-closed-atx - Multiple spaces inside hashes on closed atx style heading
  - MD022 blanks-around-headings - Headings should be surrounded by blank lines
  - MD023 heading-start-left - Headings must start at the beginning of the line
  - MD024 no-duplicate-heading - Multiple headings with the same content
  - MD025 single-title/single-h1 - Multiple top level headings in the same document
  - MD026 no-trailing-punctuation - Trailing punctuation in heading
  - MD027 no-multiple-space-blockquote - Multiple spaces after blockquote symbol
  - MD028 no-blanks-blockquote - Blank line inside blockquote
  - MD029 ol-prefix - Ordered list item prefix
  - MD030 list-marker-space - Spaces after list markers
  - MD031 blanks-around-fences - Fenced code blocks should be surrounded by blank lines
  - MD032 blanks-around-lists - Lists should be surrounded by blank lines
  - MD033 no-inline-html - Inline HTML
  - MD034 no-bare-urls - Bare URL used
  - MD035 hr-style - Horizontal rule style
  - MD036 no-emphasis-as-heading - Emphasis used instead of a heading
  - MD037 no-space-in-emphasis - Spaces inside emphasis markers
  - MD038 no-space-in-code - Spaces inside code span elements
  - MD039 no-space-in-links - Spaces inside link text
  - MD040 fenced-code-language - Fenced code blocks should have a language specified
  - MD041 first-line-heading/first-line-h1 - First line in file should be a top level heading
  - MD042 no-empty-links - No empty links
  - MD043 required-headings - Required heading structure
  - MD044 proper-names - Proper names should have the correct capitalization
  - MD045 no-alt-text - Images should have alternate text (alt text)
  - MD046 code-block-style - Code block style
  - MD047 single-trailing-newline - Files should end with a single newline character
  - MD048 code-fence-style - Code fence style
  - MD049 emphasis-style - Emphasis style should be consistent
  - MD050 strong-style - Strong style should be consistent
  - MD051 link-fragments - Link fragments should be valid
  - MD052 reference-links-images - Reference links and images should use a label that is defined
  - MD053 link-image-reference-definitions - Link and image reference definitions should be needed
  - MD054 link-image-style - Link and image style
  - MD055 table-pipe-style - Table pipe style
  - MD056 table-column-count - Table column count
  - MD058 blanks-around-tables - Tables should be surrounded by blank lines
  - MD059 descriptive-link-text - Link text should be descriptive

## 3. Git

- tag the versions without a "v" prefix

## 4. Scripts

- All waits must be loops that have a minimal fixed time (0.5 seconds) and then check what they are waiting for

## 5. Run modes

- We have three run modes

  - **Test-mode**: When started on the local development computer on which cursor-ai runs
  - **Github-Mode**: When Run by Github actions
  - **Addon-Mode**: When run as a home Assistant Add-On

- The add-on must run equally well in all run modes

## 6. Icons

### 6.1. ✅ KEEP - Functional Status Icons

These icons provide meaningful feedback about operation status and should be used:

- **✅** - Success/OK (e.g., "✅ Configuration loaded successfully", "✅ prometheus.yml accessible")
- **❌** - Error/Failure (e.g., "❌ No prometheus container found!", "❌ prometheus.yml not accessible")
- **⚠️** - Warning (e.g., "⚠️ No .env file found, using defaults")
- **🔄** - In Progress/Processing (e.g., "🔄 Files with DIFFERENT: Review differences")
- **🆕** - New/Added (e.g., "🆕 NEW FILES: Consider adding to git repository")

### 6.2. ❌ REMOVE - Decorative/Ornamental Icons

These icons are purely decorative and should be removed for cleaner output:

- **🧪** - Test mode (use plain text: "Test mode detected")
- **🏠** - Home/Addon mode (use plain text: "Addon mode detected")
- **📥** - Download/Extract (use plain text: "Extracting files...")
- **🔍** - Search/Find (use plain text: "Finding container...")
- **📦** - Container/Package (use plain text: "Container found")
- **📊** - Dashboard/Chart (use plain text: "Dashboards: X files")
- **🎯** - Target/Goal (use plain text: "Prometheus: X files")
- **🔎** - Magnifying glass (use plain text: "Blackbox: X files")
- **🚨** - Alert/Warning (use plain text: "Alerting: X files")
- **📋** - Clipboard/List (use plain text: "What was extracted:")
- **📁** - Folder/Directory (use plain text: "Files saved to:")

### 6.3. 📝 Guidelines

1. **Functional icons** provide status feedback (✅❌⚠️🔄🆕) - KEEP these
2. **Decorative icons** are visual fluff (🧪🏠📥🔍📦📊🎯🔎🚨📋📁) - REMOVE these
3. **Plain text** is always acceptable and often preferred
4. **Consistency** - Use the same icon for the same type of status across all scripts
5. **Clarity** - If an icon doesn't add functional value, use plain text instead

### 6.4. 🔧 Examples

**Good (functional):**

```sh
echo "✅ Configuration loaded successfully"
echo "❌ No prometheus container found!"
echo "⚠️ No .env file found, using defaults"
```

**Bad (decorative):**

```sh
echo "🧪 Test mode detected"
echo "📥 Extracting files..."
echo "📊 Dashboards: 5 files"
```

**Better (plain text):**

```sh
echo "Test mode detected"
echo "Extracting files..."
echo "Dashboards: 5 files"
```
