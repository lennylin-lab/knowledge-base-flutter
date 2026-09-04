/// Strips a leading YAML front matter block from Markdown source.
///
/// Document detail view renders `title` / `tags` in the header; the body
/// should only show the markdown after the closing `---`. Edit mode keeps
/// the full source unchanged.
String stripYamlFrontMatter(String markdown) {
  if (!markdown.startsWith('---\n') && markdown != '---') {
    return markdown;
  }

  const closing = '\n---\n';
  final end = markdown.indexOf(closing, 4);
  if (end == -1) {
    if (markdown.endsWith('\n---')) {
      return '';
    }
    return markdown;
  }

  var body = markdown.substring(end + closing.length);
  while (body.startsWith('\n')) {
    body = body.substring(1);
  }
  return body;
}
